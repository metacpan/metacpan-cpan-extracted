use strict;
use warnings;
use Test2::V0;

# Regression: the raw passthrough closed its Langfuse generation without
# token usage -- it parsed nothing of the upstream's answer, so every
# passthrough generation showed no counts, and the model it recorded was
# the one the client asked for, not the one that answered. Now a copy of
# the upstream's bytes is read for the trace: the usage and model of a
# buffered JSON answer, and of a stream the frames that carry them (OpenAI's
# final usage chunk, Anthropic's message_start and message_delta, Ollama's
# done frame). The bytes the client gets stay the upstream's, byte for
# byte, and nothing is read when nothing traces.

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use JSON::MaybeXS;
use Time::HiRes qw( time );

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::PassthroughUsage;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

#   _ __ ___  __ _  __| | ___ _ __
#  | '__/ _ \/ _` |/ _` |/ _ \ '__|
#  | | |  __/ (_| | (_| |  __/ |
#  |_|  \___|\__,_|\__,_|\___|_|

# The streams the upstreams send, with usage where each provider puts it.
my %STREAM = (
  openai => join( '',
    qq(data: {"choices":[{"delta":{"content":"Hel"},"index":0}],"id":"c1","model":"gpt-4o-2024-08-06","usage":null}\n\n),
    qq(data: {"choices":[{"delta":{"content":"lo \\"usage\\":{"},"index":0}],"id":"c1","model":"gpt-4o-2024-08-06","usage":null}\n\n),
    qq(data: {"choices":[{"delta":{},"finish_reason":"stop","index":0}],"id":"c1","model":"gpt-4o-2024-08-06","usage":null}\n\n),
    qq(data: {"choices":[],"id":"c1","model":"gpt-4o-2024-08-06","usage":{"completion_tokens":7,"prompt_tokens":11,"prompt_tokens_details":{"cached_tokens":8},"total_tokens":18}}\n\n),
    "data: [DONE]\n\n" ),
  anthropic => join( '',
    qq(event: message_start\ndata: {"message":{"id":"msg_1","model":"claude-x-20260101","role":"assistant","type":"message","usage":{"cache_creation_input_tokens":4,"cache_read_input_tokens":30,"input_tokens":20,"output_tokens":1}},"type":"message_start"}\n\n),
    qq(event: content_block_delta\ndata: {"delta":{"text":"Hi","type":"text_delta"},"index":0,"type":"content_block_delta"}\n\n),
    qq(event: message_delta\ndata: {"delta":{"stop_reason":"end_turn"},"type":"message_delta","usage":{"output_tokens":5}}\n\n),
    qq(event: message_stop\ndata: {"type":"message_stop"}\n\n) ),
  ollama => join( '',
    qq({"created_at":"2026-09-30T00:00:00Z","done":false,"message":{"content":"Hi","role":"assistant"},"model":"llama3.2:3b"}\n),
    qq({"created_at":"2026-09-30T00:00:01Z","done":true,"done_reason":"stop","eval_count":4,"message":{"content":"","role":"assistant"},"model":"llama3.2:3b","prompt_eval_count":9,"total_duration":123}\n) ),
);
my %BODY = (
  openai    => qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"Hello","role":"assistant"}}],"id":"c1","model":"gpt-4o-2024-08-06","usage":{"completion_tokens":7,"prompt_tokens":11,"prompt_tokens_details":{"cached_tokens":8},"total_tokens":18}}),
  anthropic => qq({"content":[{"text":"Hi","type":"text"}],"id":"msg_1","model":"claude-x-20260101","role":"assistant","stop_reason":"end_turn","type":"message","usage":{"cache_creation_input_tokens":4,"cache_read_input_tokens":30,"input_tokens":20,"output_tokens":5}}),
  ollama    => qq({"done":true,"eval_count":4,"message":{"content":"Hi","role":"assistant"},"model":"llama3.2:3b","prompt_eval_count":9}),
);
my %EXPECT = (
  openai    => { model => 'gpt-4o-2024-08-06', counts => [ 11, 7, 18 ] },
  anthropic => { model => 'claude-x-20260101', counts => [ 20, 5, 25 ] },
  ollama    => { model => 'llama3.2:3b',       counts => [ 9, 4, 13 ] },
);
# What the generation carries (k65): Langfuse's exclusive buckets -- the
# uncached input, cache reads and writes apart, total their sum -- and v2's
# usage with the whole input. OpenAI's cached_tokens are part of
# prompt_tokens, Anthropic's cache counts come beside input_tokens.
my %LANGFUSE = (
  openai    => [ { input => 3,  input_cached_tokens => 8, output => 7, total => 18 },
                 { input => 11, output => 7, total => 18, unit => 'TOKENS' } ],
  anthropic => [ { input => 20, input_cached_tokens => 30, input_cache_creation => 4, output => 5, total => 59 },
                 { input => 54, output => 5, total => 59, unit => 'TOKENS' } ],
  ollama    => [ { input => 9,  output => 4, total => 13 },
                 { input => 9,  output => 4, total => 13, unit => 'TOKENS' } ],
);

sub counts_of {
  my ($args) = @_;
  my $u = Langertha::Usage->from_hash( $args->{usage} );
  return [ $u->input_tokens, $u->output_tokens, $u->total_tokens // $u->input_tokens + $u->output_tokens ];
}

subtest 'a stream split at every byte gives the same usage' => sub {
  for my $p ( sort keys %STREAM ) {
    for my $size ( 1, 3, 17, length $STREAM{$p} ) {
      my $r = Langertha::Knarr::PassthroughUsage->new;
      my $s = $STREAM{$p};
      $r->add_chunk( substr( $s, 0, $size, '' ) ) while length $s;
      my %args = $r->trace_args;
      is( $args{model}, $EXPECT{$p}{model}, "$p, pieces of $size: model" );
      is( counts_of( \%args ), $EXPECT{$p}{counts}, "$p, pieces of $size: counts" );
    }
  }
  my $r = Langertha::Knarr::PassthroughUsage->new;
  $r->add_chunk( $STREAM{anthropic} );
  is( $r->usage, { cache_creation_input_tokens => 4, cache_read_input_tokens => 30,
                   input_tokens => 20, output_tokens => 5 },
    'anthropic: message_delta counts laid over message_start' );
};

subtest 'buffered answers' => sub {
  for my $p ( sort keys %BODY ) {
    my $r = Langertha::Knarr::PassthroughUsage->new;
    $r->read_body( $BODY{$p} );
    my %args = $r->trace_args;
    is( $args{model}, $EXPECT{$p}{model}, "$p body: model" );
    is( counts_of( \%args ), $EXPECT{$p}{counts}, "$p body: counts" );

    $r = Langertha::Knarr::PassthroughUsage->new;
    $r->read_body( $STREAM{$p} );
    is( counts_of( { $r->trace_args } ), $EXPECT{$p}{counts}, "$p buffered stream: counts" );
  }
};

subtest 'edges' => sub {
  my $r = Langertha::Knarr::PassthroughUsage->new;
  is( [ $r->trace_args ], [], 'nothing read, nothing to trace' );

  ( my $crlf = $STREAM{openai} ) =~ s/\n/\r\n/g;
  $r = Langertha::Knarr::PassthroughUsage->new;
  $r->add_chunk($crlf);
  is( counts_of( { $r->trace_args } ), [ 11, 7, 18 ], 'CRLF line ends' );

  $r = Langertha::Knarr::PassthroughUsage->new;
  ( my $last = $STREAM{ollama} ) =~ s/\n\z//;
  $r->add_chunk($last);
  is( $r->usage, undef, 'an unfinished last line waits' );
  is( counts_of( { $r->trace_args } ), [ 9, 4, 13 ], 'and is read at the end' );

  $r = Langertha::Knarr::PassthroughUsage->new( max_line => 64 );
  $r->add_chunk( 'data: {"usage":{"prompt_tokens":1,' . ( 'x' x 50 ) );
  $r->add_chunk( ( 'y' x 100 ) . qq(}}\n) );
  is( $r->usage, undef, 'a line longer than max_line is dropped' );
  is( length $r->_tail, 0, 'and not held' );
  $r->add_chunk( qq(data: {"usage":{"prompt_tokens":2,"completion_tokens":3}}\n) );
  is( counts_of( { $r->trace_args } ), [ 2, 3, 5 ], 'the next line is read again' );

  $r = Langertha::Knarr::PassthroughUsage->new;
  $r->add_chunk(qq(data: {"usage":{"prompt_tokens":4,"completion_tokens":1}}\n\ndata: {"choices":[],"usage":null}\n\n));
  is( counts_of( { $r->trace_args } ), [ 4, 1, 5 ], 'a later "usage":null does not wipe the counts' );

  $r = Langertha::Knarr::PassthroughUsage->new;
  $r->read_body('not json at all');
  $r->add_chunk("data: {broken\n\n");
  is( [ $r->trace_args ], [], 'garbage is skipped' );
};

#                  _   _
#   _ __ ___  _   _| |_| |_ ___
#  | '__/ _ \| | | | __| __/ _ \
#  | | | (_) | |_| | |_| ||  __/
#  |_|  \___/ \__,_|\__|\__\___|

my $loop = IO::Async::Loop->new;

# Fake Langfuse: keeps every ingestion batch.
my @batches;
my $langfuse = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $server, $req ) = @_;
    push @batches, $json->decode( $req->body );
    my $resp = HTTP::Response->new(207);
    $resp->content_type('application/json');
    $resp->content('{"successes":[],"errors":[]}');
    $resp->content_length( length $resp->content );
    $req->respond($resp);
  },
);
$loop->add($langfuse);
$langfuse->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $langfuse_url = 'http://127.0.0.1:' . $langfuse->read_handle->sockport;

# Fake upstream for all three protocols; a stream goes out in pieces that
# cut through its frames.
my %PATH = ( '/v1/chat/completions' => 'openai', '/v1/messages' => 'anthropic', '/api/chat' => 'ollama' );
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my $p = $PATH{ $req->path };
    my $sent = $req->body // '';
    my @enc = map { ( 'Content-Encoding' => $_ ) } grep { defined } $req->header('X-Test-Encoding');
    if ( $sent =~ /"stream":true/ || ( $p eq 'ollama' && $sent !~ /"stream":false/ ) ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => $p eq 'ollama' ? 'application/x-ndjson' : 'text/event-stream', @enc );
      $req->respond_chunk_header($head);
      my $s = $STREAM{$p};
      $req->write_chunk( substr( $s, 0, 13, '' ) ) while length $s;
      $req->write_chunk_eof;
      return;
    }
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $BODY{$p}, @enc );
    $resp->content( $BODY{$p} );
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

{
  package UsageRouter;   # every model is a passthrough model
  sub new { bless {}, shift }
  sub is_passthrough_model { 1 }
}

sub knarr_with {
  my (%tracing) = @_;
  my $knarr = Langertha::Knarr->new(
    loop            => $loop,
    listen          => [ '127.0.0.1:0' ],
    handler         => Langertha::Knarr::Handler::Code->new( code => sub { die 'handler reached' } ),
    router          => UsageRouter->new,
    raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
      upstreams => { openai => $up, anthropic => $up, ollama => $up }, loop => $loop ),
    %tracing,
  );
  $knarr->start;
  return {
    port => $knarr->_server->read_handle->sockport,
    psgi => Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app ),
  };
}

sub tracing_with_keys {
  my (%keys) = @_;
  return Langertha::Knarr::Tracing->new( loop => $loop, config => Langertha::Knarr::Config->new( data => {
    models => {}, %keys ? ( langfuse => { %keys, url => $langfuse_url } ) : () } ) );
}

my $traced   = knarr_with( tracing => tracing_with_keys( public_key => 'pk-lf-t', secret_key => 'sk-lf-t' ) );
my $disabled = knarr_with( tracing => tracing_with_keys() );
my $untraced = knarr_with();

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %CLIENT_PATH = reverse %PATH;
sub send_via {
  my ($setup, $transport, $p, $stream, @extra) = @_;
  my $body = $json->encode({ model => "asked-$p", max_tokens => 5,
    messages => [ { role => 'user', content => 'hi' } ],
    stream => $stream ? JSON::MaybeXS::true() : JSON::MaybeXS::false() });
  my @h = ( 'Content-Type' => 'application/json', 'x-api-key' => 'sk-client',
    'Authorization' => 'Bearer sk-client', @extra );
  my $path = $CLIENT_PATH{$p};
  return $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$setup->{port}$path", \@h, $body ) )->get
    : $setup->{psgi}->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $body ) );
}

# The generation-update of the next batch Langfuse receives.
sub next_generation {
  my $deadline = time + 5;
  $loop->loop_once(0.05) until @batches || time > $deadline;
  my $batch = shift @batches or return;
  my ($gen) = grep { $_->{type} eq 'generation-update' } @{ $batch->{batch} };
  return $gen && $gen->{body};
}

for my $p ( sort keys %STREAM ) {
  for my $stream ( 0, 1 ) {
    for my $transport ( 'native', 'psgi' ) {
      my $tag = "$p " . ( $stream ? 'stream' : 'sync' ) . " ($transport)";
      @batches = ();
      my $resp = send_via( $traced, $transport, $p, $stream );
      is( $resp->code, 200, "$tag: answered" );
      is( $resp->content, $stream ? $STREAM{$p} : $BODY{$p},
        "$tag: the client gets the upstream's bytes, byte for byte" );
      my $gen = next_generation();
      ok( $gen, "$tag: Langfuse got the generation" ) or next;
      is( $gen->{usageDetails}, $LANGFUSE{$p}[0], "$tag: the upstream's token counts, cache apart" );
      is( $gen->{usage}, $LANGFUSE{$p}[1], "$tag: v2 usage shape, the whole input" );
      is( $gen->{model}, $EXPECT{$p}{model}, "$tag: the model that answered" );
      is( $gen->{output}, $stream ? '[stream]' : '[passthrough]', "$tag: output marker as before" );
    }
  }
}

subtest 'bytes still encoded are not read' => sub {
  @batches = ();
  my $resp = send_via( $traced, 'native', 'openai', 1, 'X-Test-Encoding' => 'x-knarr-test' );
  is( $resp->content, $STREAM{openai}, 'the bytes unchanged' );
  is( scalar $resp->header('Content-Encoding'), 'x-knarr-test', 'with their encoding' );
  my $gen = next_generation();
  ok( $gen, 'still traced' );
  ok( !exists $gen->{usage} && !exists $gen->{model}, 'without usage or model read off them' );
};

subtest 'nothing is read when nothing traces' => sub {
  my $made = 0;
  my $orig = \&Langertha::Knarr::PassthroughUsage::new;
  no warnings 'redefine';
  local *Langertha::Knarr::PassthroughUsage::new = sub { $made++; $orig->(@_) };
  use warnings 'redefine';
  for my $setup ( $disabled, $untraced ) {
    for my $transport ( 'native', 'psgi' ) {
      for my $stream ( 0, 1 ) {
        my $resp = send_via( $setup, $transport, 'openai', $stream );
        is( $resp->content, $stream ? $STREAM{openai} : $BODY{openai}, 'bytes unchanged' );
      }
    }
  }
  is( $made, 0, 'no usage reader without an active trace' );
  send_via( $traced, 'native', 'openai', 1 );
  is( $made, 1, '(one with a trace)' );
  next_generation();
};

done_testing;
