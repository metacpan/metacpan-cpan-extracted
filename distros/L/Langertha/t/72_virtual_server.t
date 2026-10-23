#!/usr/bin/env perl
# ABSTRACT: Langertha::Virtual::Server serves a Virtual engine over HTTP, in the caller's loop and in its own process

use strict;
use warnings;

use Test2::Bundle::More;
use Path::Tiny;
use JSON::MaybeXS;
use IO::Socket::INET;
use LWP::UserAgent;
use HTTP::Request;
use Net::Async::HTTP;
use Time::HiRes ();

use lib path(__FILE__)->parent->child('lib')->stringify;

BEGIN {
  plan skip_all => 'fork-based server test not supported on Windows' if $^O eq 'MSWin32';
  eval { require IO::Async::Loop; require Net::Async::HTTP; 1 }
    or plan skip_all => 'Requires IO::Async and Net::Async::HTTP';
}

use Future::AsyncAwait;
use Test::MockMCP;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer tool tools after error );
use Langertha::Virtual::Server;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

sub engine {
  return Langertha::Engine::Virtual->new(
    rules => [
      'Hello'                     => answer('Hi there!'),
      'Add 2 and 3'               => tool( add => { a => 2, b => 3 } ),
      'Two things'                => tools( [ [ add => { a => 1, b => 1 } ], [ add => { a => 2, b => 2 } ] ] ),
      'Limit me'                  => error( 429, 'Rate limit reached' ),
      'Break me'                  => error( 500, 'Upstream is down' ),
      after('add')                => sub { answer( 'The sum is '.$_[0]{tool_results}[0]{content}.'.' ) },
    ],
    fallback => answer('No idea.'),
    langfuse_enabled => 0,
    @_,
  );
}

sub client {
  my ($server) = @_;
  return Langertha::Engine::OpenAI->new( url => $server->url, api_key => 'unused', langfuse_enabled => 0 );
}

my $http = Net::Async::HTTP->new( pipeline => 0 );
$loop->add($http);

# A plain request to the server (an HTTP::Response); failing statuses stay responses.
sub raw {
  my ( $server, $method, $path, $body ) = @_;
  my $url = ( $server->url =~ s{/v1\z}{}r ).$path;
  my $request = HTTP::Request->new( $method => $url );
  if ( defined $body ) {
    $request->header( 'Content-Type' => 'application/json' );
    $request->content($body);
  }
  return $http->do_request( request => $request )->else( sub { Future->done( $_[1] ) } )->get;
}

my $calculator = Test::MockMCP->new( tools => [ {
  name => 'add', description => 'Add', input_schema => { type => 'object' },
  code => sub { my ( $self, $args ) = @_; return $self->text_result( $args->{a} + $args->{b} ) },
} ] );

subtest 'in the caller loop: chat, tool round, models, 404' => sub {
  my $engine = engine();
  my $server = Langertha::Virtual::Server->new( engine => $engine, loop => $loop );
  ok( !eval { $server->url; 1 } && $@ =~ /not started/, 'no url before start' );
  $server->start;
  like( $server->url, qr{\Ahttp://127\.0\.0\.1:\d+/v1\z}, 'url on a free local port' );

  my $client = client($server);
  is( "".$client->simple_chat_f('Hello')->get, 'Hi there!', 'chat over HTTP through the OpenAI engine' );
  is( $engine->requests->[0]{text}, 'Hello', 'the engine recorded the request' );

  my $tooled = Langertha::Engine::OpenAI->new(
    url => $server->url, api_key => 'unused', langfuse_enabled => 0, mcp_servers => [$calculator],
  );
  is( "".$tooled->chat_with_tools_f('Add 2 and 3')->get, 'The sum is 5.', 'tool-call round over HTTP' );
  is_deeply( $engine->calls->[-1], [ 'add', { a => 2, b => 3 } ], 'the call went out as tool_calls' );

  like( raw( $server, GET => '/v1/models' )->content,
    qr/"data":\[\{"created":0,"id":"virtual","object":"model","owned_by":"virtual"\}\],"object":"list"/,
    'GET /v1/models lists the engine model' );

  my $missing = raw( $server, GET => '/v1/nothing' );
  is( $missing->code, 404, 'unknown path is a 404' );
  is_deeply( $json->decode( $missing->content ),
    { error => { code => 404, message => 'no route for GET /v1/nothing', type => 'invalid_request_error' } },
    '... with an OpenAI-style error body' );
  is( raw( $server, POST => '/v1/chat/completions', 'abc' )->code, 400, 'a body that is not JSON is a 400' );
  is( raw( $server, GET => '/v1/chat/completions' )->code, 405, 'GET on the chat endpoint is a 405' );
  is( raw( $server, GET => '/_virtual/requests' )->code, 404, 'debug endpoint is off by default' );
  $server->stop;
  $server->stop;
  ok( 1, 'stop twice is safe' );
};

subtest 'error reactions arrive with their status' => sub {
  my $server = Langertha::Virtual::Server->new( engine => engine(), loop => $loop )->start;
  my $client = client($server);
  my $failure = $client->simple_chat_f('Limit me')->failure;
  like( $failure, qr/429/, 'a 429 reaches the client as a 429' );
  like( $failure, qr/Rate limit reached/, '... with the message' );
  like( $client->simple_chat_f('Break me')->failure, qr/500.*Upstream is down/s, 'a 500 reaction' );
  $server->stop;
};

subtest 'stream: true is served as server-sent events' => sub {
  my $server = Langertha::Virtual::Server->new( engine => engine(), loop => $loop )->start;
  my $client = client($server);
  my @pieces;
  $client->simple_chat_stream_realtime_f( sub { push @pieces, "".$_[0]->content }, 'Hello' )->get;
  is( join( '', grep { length } @pieces ), 'Hi there!', 'the text streams in' );

  my $body = $json->encode( { model => 'virtual', stream => JSON::MaybeXS::true,
    messages => [ { role => 'user', content => 'Add 2 and 3' } ] } );
  my $answer = raw( $server, POST => '/v1/chat/completions', $body );
  like( $answer->content_type, qr{\Atext/event-stream}, 'event-stream content type' );
  like( $answer->content, qr/"tool_calls":\[\{"function":\{"arguments":"","name":"add"\},"id":"call_virtual_\d+","index":0,"type":"function"\}\]/,
    'the tool call opens with a delta fragment (name, id, empty arguments)' );
  like( $answer->content, qr/"tool_calls":\[\{"function":\{"arguments":"\{\\"a\\":2,\\""\},"index":0\}\].*"tool_calls":\[\{"function":\{"arguments":"b\\":3\}"\},"index":0\}\]/s,
    '... and its arguments follow in pieces' );
  like( $answer->content, qr/"finish_reason":"tool_calls".*data: \[DONE\]\n\n\z/s, 'finish reason, then [DONE]' );
  $server->stop;
};

subtest 'delay lets a client run into its timeout' => sub {
  my $server = Langertha::Virtual::Server->new( engine => engine(), loop => $loop, delay => 0.4 )->start;
  my $started = Time::HiRes::time();
  is( "".client($server)->simple_chat_f('Hello')->get, 'Hi there!', 'still answers' );
  cmp_ok( Time::HiRes::time() - $started, '>=', 0.35, 'but only after the delay' );
  $server->stop;
};

subtest 'spawn: own process, debug endpoint, reap without zombie' => sub {
  my ( $pid, $url ) = Langertha::Virtual::Server->spawn( engine => engine(), debug => 1 );
  ok( $pid, 'got a pid' );
  my $client = Langertha::Engine::OpenAI->new( url => $url, api_key => 'unused', langfuse_enabled => 0 );
  is( "".$client->simple_chat('Hello'), 'Hi there!', 'a synchronous client works against the child' );

  is_deeply( $client->list_models, ['virtual'], 'GET /v1/models through the engine (synchronous)' );

  my $ua = LWP::UserAgent->new;
  my $seen = $json->decode( $ua->get( ( $url =~ s{/v1\z}{}r ).'/_virtual/requests' )->decoded_content );
  is( $seen->{requests}[0]{text}, 'Hello', 'the child reports its requests' );

  my $tooled = Langertha::Engine::OpenAI->new(
    url => $url, api_key => 'unused', langfuse_enabled => 0, mcp_servers => [$calculator],
  );
  is( "".$tooled->chat_with_tools_f('Add 2 and 3')->get, 'The sum is 5.', 'tool round against the child' );

  Langertha::Virtual::Server->reap($pid);
  is( waitpid( $pid, 1 ), -1, 'no zombie is left to wait for' );
  ok( !kill( 0, $pid ), 'the process is gone' );
  ok( !IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => ( $url =~ /:(\d+)\// )[0] ), 'the port is closed' );
};

subtest 'a spawned server ends when its parent is gone' => sub {
  pipe( my $reader, my $writer ) or die $!;
  my $middle = fork // die;
  unless ($middle) {
    close $reader;
    my ( $pid, $url ) = Langertha::Virtual::Server->spawn( engine => engine() );
    print {$writer} "$pid\n";
    close $writer;
    require POSIX;
    POSIX::_exit(0);
  }
  close $writer;
  my $pid = <$reader>;
  chomp $pid;
  waitpid $middle, 0;
  my $gone = 0;
  for ( 1 .. 40 ) { select undef, undef, undef, 0.1; $gone = !-d "/proc/$pid" || path("/proc/$pid/stat")->slurp =~ /\) Z/; last if $gone }
  ok( $gone, 'the orphaned server exits by itself' );
  waitpid( $pid, 1 );
};

done_testing;
