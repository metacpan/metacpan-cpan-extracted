use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;

# A routed stream lost the backend's token usage: Langertha's stream chunks
# carry it (cumulative, the last report being the stream's totals -- after the
# finish chunk on OpenAI's include_usage frame), but the engine handlers read
# only text, finish_reason and tool calls off them. The Langfuse generation of
# a routed stream had no usage, and the client's stream reported none either.
# The stream now keeps the usage; the tracing and request-log decorators record
# it, and each protocol reports it the way its own wire does: Anthropic on
# message_delta, Ollama as prompt_eval_count / eval_count on the done line,
# OpenAI in a chunk of its own after the terminal one -- only when the client
# asked for it with stream_options.include_usage.

use Langertha::Stream::Chunk;
use Langertha::Usage;
use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Streams like a core OpenAI-wire engine with include_usage: text, the finish
# chunk, then a content-less chunk carrying the usage (and the upstream's own
# model name on every chunk). An earlier partial report is overridden.
{
  package UsageEngine;
  use Moose;
  use Future;
  has chat_model => ( is => 'ro', default => 'up-model' );
  has no_usage   => ( is => 'ro', default => 0 );
  sub supports { $_[1] eq 'streaming' ? 1 : 0 }
  sub chat_stream_realtime_f {
    my ( $self, %args ) = @_;
    my $cb = $args{chunk_callback};
    my %m = ( model => 'up-model-2024' );
    $cb->( Langertha::Stream::Chunk->new( content => 'Hel', %m ) );
    $cb->( Langertha::Stream::Chunk->new( content => 'lo', %m,
      $self->no_usage ? () : ( usage => { prompt_tokens => 17, completion_tokens => 1 } ) ) );
    $cb->( Langertha::Stream::Chunk->new( content => '', %m, is_final => 1, finish_reason => 'stop' ) );
    $cb->( Langertha::Stream::Chunk->new( content => '', %m,
      usage => { prompt_tokens => 17, completion_tokens => 9, total_tokens => 26 } ) )
      unless $self->no_usage;
    return Future->done;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package UsageRouter;
  use Moose;
  has engine => ( is => 'ro', required => 1 );
  sub resolve { ( $_[0]->engine, 'up-model', 0 ) }
  sub list_models { [ { id => 'fake', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

{
  package RecTracer;
  use Moose;
  has ended => ( is => 'rw' );
  sub start_trace { {} }
  sub end_trace   { my ( $self, $t, %o ) = @_; $self->ended( \%o ) }
  __PACKAGE__->meta->make_immutable;
}

{
  package RecLog;
  use Moose;
  has ended => ( is => 'rw' );
  sub start_request { {} }
  sub end_request   { my ( $self, $h, %o ) = @_; $self->ended( \%o ) }
  __PACKAGE__->meta->make_immutable;
}

my $session = Langertha::Knarr::Session->new( id => 's' );
my $sreq = Langertha::Knarr::Request->new(
  protocol => 'openai', model => 'fake', stream => 1,
  messages => [ { role => 'user', content => 'hi' } ],
);

sub drain {
  my ($stream) = @_;
  my $text = '';
  while ( defined( my $c = $stream->next_chunk_f->get ) ) { $text .= $c }
  return $text;
}

sub counts {
  my ($u) = @_;
  return undef unless $u;
  return [ $u->input_tokens, $u->output_tokens, $u->total_tokens ];
}

subtest 'Stream keeps the last usage report' => sub {
  my $s = Langertha::Knarr::Stream->from_callback( sub {
    my ( $emit, $done, $fail, $finish, $tool_call, $usage ) = @_;
    $emit->('a');
    $usage->( { prompt_tokens => 3, completion_tokens => 1 } );
    $usage->(undef);
    $usage->( {} );
    $usage->( { prompt_tokens => 3, completion_tokens => 4 } );
    $done->();
  });
  is drain($s), 'a', 'text still flows';
  isa_ok $s->usage, ['Langertha::Usage'], 'provider hash upgraded';
  is counts( $s->usage ), [ 3, 4, 7 ], 'the later report wins, undef and empty ones are ignored';

  my $wrap = Langertha::Knarr::Stream->new( upstream => $s, source => sub { Future->done(undef) } );
  is counts( $wrap->usage ), [ 3, 4, 7 ], 'a wrapping stream answers with its upstream usage';

  is( Langertha::Knarr::Stream->from_list('x')->usage, undef, 'no usage by default' );
  is counts( Langertha::Knarr::Stream->new( usage => { input_tokens => 2, output_tokens => 5 } )->usage ),
    [ 2, 5, 7 ], 'usage as a constructor argument';
  is( Langertha::Knarr::Stream->new( usage => {} )->usage, undef, 'an empty hash is no usage' );
};

subtest 'engine handlers collect the chunk usage' => sub {
  for my $case (
    [ Engine => sub { Langertha::Knarr::Handler::Engine->new( engine => $_[0] ) } ],
    [ Router => sub { Langertha::Knarr::Handler::Router->new( router => UsageRouter->new( engine => $_[0] ) ) } ],
  ) {
    my ( $name, $build ) = @$case;
    my $stream = $build->( UsageEngine->new )->handle_stream_f( $session, $sreq )->get;
    is drain($stream), 'Hello', "$name: text";
    is counts( $stream->usage ), [ 17, 9, 26 ], "$name: usage of the report after the finish chunk";
    is $stream->finish_reason, 'stop', "$name: reason";

    my $plain = $build->( UsageEngine->new( no_usage => 1 ) )->handle_stream_f( $session, $sreq )->get;
    drain($plain);
    is $plain->usage, undef, "$name: no report, no usage";
  }
};

subtest 'non-streaming fallback takes the usage from the Response' => sub {
  my $h = Langertha::Knarr::Handler::Engine->new( engine => UsageEngine->new );
  no warnings 'redefine';
  local *Langertha::Knarr::Handler::Engine::_supports_streaming = sub { 0 };
  local *Langertha::Knarr::Handler::Engine::handle_chat_f = sub {
    Future->done( Langertha::Knarr::Response->new(
      content => 'x', usage => { prompt_tokens => 5, completion_tokens => 2 } ) );
  };
  my $stream = $h->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is counts( $stream->usage ), [ 5, 2, 7 ], 'usage from the Response';
};

subtest 'decorators record the stream usage' => sub {
  my $tracer = RecTracer->new;
  my $stream = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Router->new( router => UsageRouter->new( engine => UsageEngine->new ) ),
    tracing => $tracer,
  )->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is counts( $stream->usage ), [ 17, 9, 26 ], 'Tracing stream reports the inner usage';
  is counts( $tracer->ended->{usage} ), [ 17, 9, 26 ], 'trace gets the usage';

  my $log = RecLog->new;
  $stream = Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => Langertha::Knarr::Handler::Engine->new( engine => UsageEngine->new ),
    request_log => $log,
  )->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is counts( $log->ended->{usage} ), [ 17, 9, 26 ], 'request log gets the usage';

  my $plain = RecTracer->new;
  $stream = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Engine->new( engine => UsageEngine->new( no_usage => 1 ) ),
    tracing => $plain,
  )->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  ok !exists $plain->ended->{usage}, 'no usage key without a report';
};

# --- Wire formats ---

sub sse_events {
  my ($body) = @_;
  my @events;
  for my $block ( grep { length } split /\n\n/, $body ) {
    my ($event) = $block =~ /^event: (.+)$/m;
    my ($data)  = $block =~ /^data: (.+)$/m;
    push @events, [ $event, $data eq '[DONE]' ? $data : $json->decode($data) ];
  }
  return @events;
}

my $usage = Langertha::Usage->from_hash( { prompt_tokens => 17, completion_tokens => 9, total_tokens => 26 } );
my $oa = Langertha::Knarr::Protocol::OpenAI->new;
my $an = Langertha::Knarr::Protocol::Anthropic->new;
my $ol = Langertha::Knarr::Protocol::Ollama->new;
sub oreq {
  my (%raw) = @_;
  return Langertha::Knarr::Request->new( protocol => 'openai', model => 'fake', stream => 1, raw => { %raw } );
}

subtest 'OpenAI: a usage chunk after the terminal one, only with include_usage' => sub {
  my $req = oreq( stream_options => { include_usage => JSON::MaybeXS::true() } );
  my @chunks = map { $_->[1] } sse_events( $oa->format_stream_close( $req, 'stop', [], $usage ) );
  is scalar @chunks, 2, 'terminal chunk, then the usage chunk';
  is $chunks[0]{choices}[0]{finish_reason}, 'stop', 'terminal chunk first';
  ok !exists $chunks[0]{usage}, 'terminal chunk carries no usage';
  is $chunks[1]{choices}, [], 'usage chunk has empty choices';
  is $chunks[1]{usage}, { prompt_tokens => 17, completion_tokens => 9, total_tokens => 26 }, 'usage in OpenAI keys';
  is $chunks[1]{object}, 'chat.completion.chunk', 'a chunk like the others';

  is scalar( () = sse_events( $oa->format_stream_close( oreq(), 'stop', [], $usage ) ) ), 1,
    'without include_usage no usage chunk';
  is scalar( () = sse_events( $oa->format_stream_close(
    oreq( stream_options => { include_usage => JSON::MaybeXS::false() } ), 'stop', [], $usage ) ) ), 1,
    'include_usage false: no usage chunk';
  is scalar( () = sse_events( $oa->format_stream_close( $req, 'stop', [], undef ) ) ), 1,
    'no usage from the backend: no zeroed chunk';
  is $oa->format_stream_done( $req, 'stop', [], $usage ), "data: [DONE]\n\n", 'end marker unchanged';
};

subtest 'Anthropic: usage on message_delta' => sub {
  my $req = Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'fake', stream => 1 );
  my @ev = sse_events( $an->format_stream_close( $req, 'end_turn', [], $usage ) );
  my ($delta) = map { $_->[1] } grep { $_->[0] eq 'message_delta' } @ev;
  is $delta->{usage}, { input_tokens => 17, output_tokens => 9 }, 'input and output tokens';
  is $ev[-1][0], 'message_stop', 'message_stop still ends the stream';
  ($delta) = map { $_->[1] } grep { $_->[0] eq 'message_delta' }
    sse_events( $an->format_stream_close( $req, 'end_turn', [] ) );
  is $delta->{usage}, { output_tokens => 0 }, 'without usage as before';
};

subtest 'Ollama: counters on the done line' => sub {
  my $req = Langertha::Knarr::Request->new( protocol => 'ollama', model => 'fake', stream => 1 );
  my $done = $json->decode( $ol->format_stream_done( $req, 'stop', [], $usage ) );
  ok $done->{done}, 'done line';
  is [ @{$done}{qw( prompt_eval_count eval_count )} ], [ 17, 9 ], 'prompt_eval_count / eval_count';
  $done = $json->decode( $ol->format_stream_done( $req, 'stop', [] ) );
  ok !exists $done->{eval_count}, 'without usage no counters';
};

# --- End to end: a real Knarr server in front of the usage engine ---

my $loop = IO::Async::Loop->new;
my $tracer = RecTracer->new;
my $knarr = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Router->new( router => UsageRouter->new( engine => UsageEngine->new ) ),
    tracing => $tracer,
  ),
  loop => $loop,
  port => 0,
);
$knarr->start;
my $kport = $knarr->_server->read_handle->sockport;

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post_stream {
  my ( $port, $path, %extra ) = @_;
  my $r = HTTP::Request->new( POST => "http://127.0.0.1:$port$path" );
  $r->header( 'Content-Type' => 'application/json' );
  $r->content( $json->encode({
    model => 'fake', max_tokens => 16, stream => JSON::MaybeXS::true(),
    messages => [ { role => 'user', content => 'hi' } ], %extra,
  }) );
  return $http->do_request( request => $r )->get->content;
}

sub check_wire {
  my ( $label, $get ) = @_;

  my @data = map { $_->[1] } sse_events( $get->( '/v1/chat/completions',
    stream_options => { include_usage => JSON::MaybeXS::true() } ) );
  is $data[-1], '[DONE]', "$label openai: ends with [DONE]";
  is $data[-2]{usage}, { prompt_tokens => 17, completion_tokens => 9, total_tokens => 26 },
    "$label openai: usage chunk right before [DONE]";
  is $data[-3]{choices}[0]{finish_reason}, 'stop', "$label openai: after the terminal chunk";
  @data = map { $_->[1] } sse_events( $get->('/v1/chat/completions') );
  ok !( grep { ref $_ && exists $_->{usage} } @data ), "$label openai: none without include_usage";

  my @ev = sse_events( $get->('/v1/messages') );
  is $ev[-1][0], 'message_stop', "$label anthropic: ends with message_stop";
  is $ev[-2][1]{usage}, { input_tokens => 17, output_tokens => 9 }, "$label anthropic: usage on message_delta";

  my @ndjson = map { $json->decode($_) } grep { length } split /\n/, $get->('/api/chat');
  ok $ndjson[-1]{done}, "$label ollama: last line is done";
  is [ @{ $ndjson[-1] }{qw( prompt_eval_count eval_count )} ], [ 17, 9 ], "$label ollama: counters on the done line";
}

subtest 'Knarr server streams the usage' => sub {
  check_wire( 'direct', sub { post_stream( $kport, @_ ) } );
  is counts( $tracer->ended->{usage} ), [ 17, 9, 26 ], 'trace of the streamed request has the usage';
};

subtest 'PSGI buffered stream carries the usage' => sub {
  plan skip_all => 'Plack::Test required'
    unless eval { require Plack::Test; 1 };
  my $test = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );
  check_wire( 'psgi', sub {
    my ( $path, %extra ) = @_;
    my $r = HTTP::Request->new( POST => $path );
    $r->header( 'Content-Type' => 'application/json' );
    $r->content( $json->encode({
      model => 'fake', stream => JSON::MaybeXS::true(),
      messages => [ { role => 'user', content => 'hi' } ], %extra,
    }) );
    $test->request($r)->content;
  } );
};

# --- A real core engine against a local OpenAI-wire upstream ---
#
# Usage on the finish chunk (vLLM continuous usage, several gateways) reaches
# every core. The include_usage frame after it (choices: []) is kept by a core
# whose parser turns it into a usage chunk; an older core drops it, and Knarr
# then reports no usage rather than failing -- probed, not assumed from
# $VERSION.

my %UPSTREAM = (
  inc => [
    { choices => [ { index => 0, delta => { role => 'assistant', content => 'Hi' } } ] },
    { choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ] },
    { choices => [], usage => { prompt_tokens => 17, completion_tokens => 9, total_tokens => 26 } },
  ],
  fin => [
    { choices => [ { index => 0, delta => { role => 'assistant', content => 'Hi' } } ] },
    { choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ],
      usage => { prompt_tokens => 13, completion_tokens => 5, total_tokens => 18 } },
  ],
);
my @upstream_bodies;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $srv, $r ) = @_;
    my $body = $json->decode( $r->body );
    push @upstream_bodies, $body;
    my $frames = $UPSTREAM{ $body->{model} } or return $r->respond( HTTP::Response->new(404) );
    my $sse = join '', ( map { 'data: ' . $json->encode( { model => "$body->{model}-upstream", %$_ } ) . "\n\n" } @$frames ),
      "data: [DONE]\n\n";
    my $resp = HTTP::Response->new(200);
    $resp->header( 'Content-Type' => 'text/event-stream' );
    $resp->content($sse);
    $resp->content_length( length $sse );
    $r->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $uport = $upstream->read_handle->sockport;

subtest 'real core engine: usage from the stream chunks' => sub {
  require Langertha::Engine::OpenAI;
  my $probe = Langertha::Engine::OpenAI->new( url => 'http://x/v1', api_key => 'k', model => 'm' )
    ->parse_stream_chunk( { choices => [], usage => { prompt_tokens => 1, completion_tokens => 1 } }, undef, {} );
  my $core_keeps = $probe && $probe->can('has_usage') && $probe->has_usage;
  note $core_keeps ? 'core keeps the include_usage frame' : 'core drops the include_usage frame';

  for my $model (qw( fin inc )) {
    my $engine = Langertha::Engine::OpenAI->new(
      url => "http://127.0.0.1:$uport/v1", api_key => 'test', model => $model,
    );
    my $stream = Langertha::Knarr::Handler::Engine->new( engine => $engine )
      ->handle_stream_f( $session, $sreq )->get;
    my $text = '';
    while ( defined( my $c = $loop->await( $stream->next_chunk_f )->get ) ) { $text .= $c }
    is $text, 'Hi', "$model: text";
    if ( $model eq 'fin' ) {
      is counts( $stream->usage ), [ 13, 5, 18 ], 'fin: usage on the finish chunk';
    }
    elsif ($core_keeps) {
      is counts( $stream->usage ), [ 17, 9, 26 ], 'inc: usage of the include_usage frame';
    }
    else {
      is $stream->usage, undef, 'inc: no usage, no failure';
    }
  }
};

done_testing;
