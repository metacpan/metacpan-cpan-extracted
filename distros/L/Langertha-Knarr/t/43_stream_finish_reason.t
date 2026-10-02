use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;

# k18: a routed stream must end with the backend's real finish reason. Before,
# Knarr::Stream carried text only, so every stream closed with a hardcoded
# "normal end": Anthropic message_delta stop_reason end_turn, no OpenAI
# terminal chunk at all, Ollama done_reason stop. A length-truncated answer
# then looked complete to the client, which never learns it should continue.
# The stream now carries the terminal reason from Langertha::Stream::Chunk,
# and each protocol maps it into its own closed vocabulary when it closes the
# stream. The non-streaming Ollama and OpenAI answers use the same mapping,
# so a backend's tool_calls / end_turn / MAX_TOKENS never reaches a client
# verbatim.

use Langertha::Stream::Chunk;
use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Stream;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

# Streams like a real core engine: text chunks, then a terminal chunk with
# empty content that carries finish_reason (OpenAI-dialect shape).
{
  package FinishEngine;
  use Moose;
  use Future;
  has chat_model => ( is => 'ro', default => 'fin-1' );
  has reason     => ( is => 'rw', default => 'length' );
  has plain      => ( is => 'ro', default => 0 );   # emit plain strings (no Chunk objects)
  sub supports { $_[1] eq 'streaming' ? 1 : 0 }
  sub chat_stream_realtime_f {
    my ( $self, %args ) = @_;
    my $cb = $args{chunk_callback};
    if ( $self->plain ) { $cb->($_) for qw( Hel lo ); return Future->done }
    $cb->( Langertha::Stream::Chunk->new( content => $_ ) ) for qw( Hel lo );
    $cb->( Langertha::Stream::Chunk->new(
      content => '', is_final => 1, finish_reason => $self->reason ) );
    return Future->done;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package FinishRouter;
  use Moose;
  has engine => ( is => 'ro', required => 1 );
  sub resolve { ( $_[0]->engine, 'fin-1' ) }
  sub list_models { [ { id => 'fin-1', object => 'model' } ] }
  __PACKAGE__->meta->make_immutable;
}

{
  package NullTracer;
  use Moose;
  sub start_trace { {} }
  sub end_trace   { }
  __PACKAGE__->meta->make_immutable;
}

my $session = Langertha::Knarr::Session->new( id => 's' );
my $sreq = Langertha::Knarr::Request->new(
  protocol => 'openai', model => 'fin-1', stream => 1,
  messages => [ { role => 'user', content => 'hi' } ],
);

sub drain {
  my ($stream) = @_;
  my $text = '';
  while ( defined( my $c = $stream->next_chunk_f->get ) ) { $text .= $c }
  return $text;
}

subtest 'Stream carries a terminal finish_reason' => sub {
  my $s = Langertha::Knarr::Stream->from_callback( sub {
    my ( $emit, $done, $fail, $finish ) = @_;
    $emit->('a');
    $finish->(undef);          # an undef never overwrites
    $finish->('length');
    $finish->(undef);
    $done->();
  });
  is drain($s), 'a', 'text still flows';
  is $s->finish_reason, 'length', 'finish_reason set by the producer';

  my $wrap = Langertha::Knarr::Stream->new( upstream => $s, source => sub { Future->done(undef) } );
  is $wrap->finish_reason, 'length', 'a wrapping stream answers with its upstream reason';
  $wrap->finish_reason('stop');
  is $wrap->finish_reason, 'stop', 'its own reason wins over the upstream one';

  is( Langertha::Knarr::Stream->from_list('x')->finish_reason, undef, 'no reason by default' );
};

subtest 'engine handlers expose the engine chunk finish_reason' => sub {
  for my $case (
    [ Engine => sub { Langertha::Knarr::Handler::Engine->new( engine => $_[0] ) } ],
    [ Router => sub { Langertha::Knarr::Handler::Router->new( router => FinishRouter->new( engine => $_[0] ) ) } ],
  ) {
    my ( $name, $build ) = @$case;
    my $stream = $build->( FinishEngine->new )->handle_stream_f( $session, $sreq )->get;
    is drain($stream), 'Hello', "$name: text";
    is $stream->finish_reason, 'length', "$name: finish_reason from the terminal chunk";

    my $plain = $build->( FinishEngine->new( plain => 1 ) )->handle_stream_f( $session, $sreq )->get;
    is drain($plain), 'Hello', "$name: plain-string chunks still stream";
    is $plain->finish_reason, undef, "$name: no reason when the chunks carry none";
  }
};

subtest 'tracing decorator forwards the reason' => sub {
  my $h = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Engine->new( engine => FinishEngine->new ),
    tracing => NullTracer->new,
  );
  my $stream = $h->handle_stream_f( $session, $sreq )->get;
  drain($stream);
  is $stream->finish_reason, 'length', 'Tracing stream reports the inner reason';
};

subtest 'non-streaming fallback keeps the Response reason' => sub {
  my $engine = FinishEngine->new;
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  no warnings 'redefine';
  local *Langertha::Knarr::Handler::Engine::_supports_streaming = sub { 0 };
  local *Langertha::Knarr::Handler::Engine::handle_chat_f = sub {
    Future->done( Langertha::Knarr::Response->new( content => 'full', finish_reason => 'length' ) );
  };
  my $stream = $h->handle_stream_f( $session, $sreq )->get;
  is drain($stream), 'full', 'single chunk';
  is $stream->finish_reason, 'length', 'reason from the Response';
};

my $oa = Langertha::Knarr::Protocol::OpenAI->new;
my $an = Langertha::Knarr::Protocol::Anthropic->new;
my $ol = Langertha::Knarr::Protocol::Ollama->new;
my $req = Langertha::Knarr::Request->new( protocol => 'openai', model => 'fin-1' );

sub anthropic_stop {
  my $out = $an->format_stream_close( $req, $_[0] );
  my ($data) = $out =~ /^event: message_delta\ndata: (.+)$/m;
  return $json->decode($data)->{delta}{stop_reason};
}

sub openai_close {
  my $out = $oa->format_stream_close( $req, $_[0] );
  my ($data) = $out =~ /^data: (.+)$/m;
  return $json->decode($data)->{choices}[0];
}

sub ollama_done {
  return $json->decode( $ol->format_stream_done( $req, $_[0] ) )->{done_reason};
}

sub ollama_chat {
  my $r = Langertha::Knarr::Response->new( content => 'x',
    ( defined $_[0] ? ( finish_reason => $_[0] ) : () ) );
  my ( undef, undef, $body ) = $ol->format_chat_response( $r, $req );
  return $json->decode($body)->{done_reason};
}

sub openai_chat {
  my $r = Langertha::Knarr::Response->new( content => 'x',
    ( defined $_[0] ? ( finish_reason => $_[0] ) : () ) );
  my ( undef, undef, $body ) = $oa->format_chat_response( $r, $req );
  return $json->decode($body)->{choices}[0]{finish_reason};
}

subtest 'Anthropic message_delta routes the reason through _stop_reason' => sub {
  is anthropic_stop('length'),     'max_tokens', 'length -> max_tokens';
  is anthropic_stop('MAX_TOKENS'), 'max_tokens', 'Gemini MAX_TOKENS -> max_tokens';
  is anthropic_stop('tool_calls'), 'tool_use',   'tool_calls -> tool_use';
  is anthropic_stop('stop'),       'end_turn',   'stop -> end_turn';
  is anthropic_stop(undef),        'end_turn',   'no reason -> end_turn';
};

subtest 'OpenAI terminal chunk carries a mapped finish_reason' => sub {
  my $c = openai_close('length');
  is $c->{delta}, {}, 'terminal chunk has an empty delta';
  is $c->{finish_reason}, 'length', 'length passes through';
  is openai_close('max_tokens')->{finish_reason}, 'length',         'Anthropic max_tokens -> length';
  is openai_close('MAX_TOKENS')->{finish_reason}, 'length',         'Gemini MAX_TOKENS -> length';
  is openai_close('end_turn')->{finish_reason},   'stop',           'end_turn -> stop';
  is openai_close('tool_use')->{finish_reason},   'tool_calls',     'tool_use -> tool_calls';
  is openai_close('SAFETY')->{finish_reason},     'content_filter', 'Gemini SAFETY -> content_filter';
  is openai_close('weird')->{finish_reason},      'stop',           'unknown -> stop';
  is openai_close(undef)->{finish_reason},        'stop',           'no reason -> stop';

  is openai_chat('end_turn'),   'stop',   'non-stream: end_turn -> stop';
  is openai_chat('max_tokens'), 'length', 'non-stream: max_tokens -> length';
  is openai_chat(undef),        'stop',   'non-stream: no reason -> stop';
};

subtest 'Ollama done_reason stays in Ollama vocabulary' => sub {
  for my $case (
    [ length => 'length' ], [ max_tokens => 'length' ], [ MAX_TOKENS => 'length' ],
    [ stop => 'stop' ], [ STOP => 'stop' ], [ end_turn => 'stop' ],
    [ tool_calls => 'stop' ], [ tool_use => 'stop' ], [ content_filter => 'stop' ],
    [ load => 'load' ], [ undef, 'stop' ],
  ) {
    my ( $in, $want ) = @$case;
    my $label = $in // 'undef';
    is ollama_done($in), $want, "stream: $label -> $want";
    is ollama_chat($in), $want, "non-stream: $label -> $want";
  }
};

# --- End to end: a real Knarr server in front of the fake engine ---

my $loop = IO::Async::Loop->new;
my $backend = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Engine->new( engine => FinishEngine->new ),
  loop    => $loop,
  port    => 0,
);
$backend->start;
my $bport = $backend->_server->read_handle->sockport;

# A second Knarr that forwards to the first through Handler::Passthrough: the
# reason must survive the protocol-native round trip.
my $front = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { map { $_ => "http://127.0.0.1:$bport" } qw( openai anthropic ollama ) },
    loop      => $loop,
  ),
  loop => $loop,
  port => 0,
);
$front->start;
my $fport = $front->_server->read_handle->sockport;

my $http = Net::Async::HTTP->new;
$loop->add($http);

sub post_stream {
  my ( $port, $path ) = @_;
  my $r = HTTP::Request->new( POST => "http://127.0.0.1:$port$path" );
  $r->header( 'Content-Type' => 'application/json' );
  $r->content( $json->encode({
    model => 'fin-1', max_tokens => 16, stream => JSON::MaybeXS::true(),
    messages => [ { role => 'user', content => 'hi' } ],
  }) );
  return $http->do_request( request => $r )->get->decoded_content;
}

sub check_wire {
  my ( $label, $get ) = @_;

  my $openai = $get->('/v1/chat/completions');
  my @data = map { /^data: (.+)$/ ? $1 : () } split /\n/, $openai;
  is $data[-1], '[DONE]', "$label openai: ends with [DONE]";
  my $term = $json->decode( $data[-2] );
  is $term->{choices}[0]{delta}, {}, "$label openai: terminal chunk before [DONE] has an empty delta";
  is $term->{choices}[0]{finish_reason}, 'length', "$label openai: terminal finish_reason length";
  my @set = grep { defined $json->decode($_)->{choices}[0]{finish_reason} } @data[ 0 .. $#data - 1 ];
  is scalar @set, 1, "$label openai: only the terminal chunk sets finish_reason";

  my $anthropic = $get->('/v1/messages');
  like $anthropic, qr/"stop_reason":"max_tokens"/, "$label anthropic: message_delta stop_reason max_tokens";
  like $anthropic, qr/event: message_stop/, "$label anthropic: message_stop";

  my @ndjson = map { $json->decode($_) } grep { length } split /\n/, $get->('/api/chat');
  ok $ndjson[-1]{done}, "$label ollama: last line is done";
  is $ndjson[-1]{done_reason}, 'length', "$label ollama: done_reason length";
}

subtest 'Knarr server streams the real reason' => sub {
  check_wire( 'direct', sub { post_stream( $bport, $_[0] ) } );
};

subtest 'Handler::Passthrough carries the upstream reason' => sub {
  check_wire( 'passthrough', sub { post_stream( $fport, $_[0] ) } );
};

subtest 'PSGI buffered stream reports the real reason' => sub {
  plan skip_all => 'Plack::Test required'
    unless eval { require Plack::Test; require HTTP::Request::Common; 1 };
  my $app = Langertha::Knarr::PSGI->new( knarr => $backend )->to_app;
  my $test = Plack::Test->create($app);
  check_wire( 'psgi', sub {
    my $r = HTTP::Request->new( POST => $_[0] );
    $r->header( 'Content-Type' => 'application/json' );
    $r->content( $json->encode({
      model => 'fin-1', stream => JSON::MaybeXS::true(),
      messages => [ { role => 'user', content => 'hi' } ],
    }) );
    $test->request($r)->decoded_content;
  });
};

done_testing;
