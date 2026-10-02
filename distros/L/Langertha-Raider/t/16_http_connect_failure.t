#!/usr/bin/env perl
# ABSTRACT: A module Net::Async::HTTP loads to connect is missing: the raid and the web tools fail, they do not hang (k107, k109)
use strict;
use warnings;
use Test2::V0;
use Future;
use IO::Async::Listener;
use IO::Async::Loop;
use IO::Socket::INET;

# Net::Async::HTTP loads IO::Async::Internals::Connector (every connect) and
# IO::Async::SSL (https) only when it opens a connection. When that load
# dies, the connection slot for the host stays taken and every later request
# to that host waits forever (Net::Async::HTTP 0.50). Seen in the standalone
# binary: the Connector was not packed, and without libssl IO::Async::SSL
# cannot load.
my %blocked;
unshift @INC, sub {
  my ( undef, $file ) = @_;
  die "Can't locate $file in \@INC (blocked by the test)\n" if $blocked{$file};
  return;
};

use Langertha::Engine::OpenAI;
use Langertha::Raider;
use Langertha::Raider::WebTools qw( build_web_tools_server );

for my $file (qw( IO/Async/Internals/Connector.pm IO/Async/SSL.pm )) {
  plan skip_all => "$file is already loaded, it cannot be made to fail"
    if $INC{$file};
}

# A port nothing listens on.
my $port = do {
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "listen: $!";
  my $p = $s->sockport;
  close $s;
  $p;
};

# Waits at most $secs for $f. Returns true when $f is ready.
sub settles_within {
  my ( $loop, $f, $secs ) = @_;
  my $timer = $loop->delay_future( after => $secs );
  $loop->await( Future->wait_any( $f->without_cancel, $timer ) );
  return $f->is_ready;
}

# One raid against an OpenAI engine on $url with $file blocked. The engine
# embeds the session history, so the raid sends two requests to the host:
# the embedding (in the background) and the chat request.
sub raid_with_blocked {
  my ( $file, $url ) = @_;
  local $blocked{$file} = 1;
  my $loop = IO::Async::Loop->new;
  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'test-key',
    url     => $url,
    model   => 'gpt-test',
  );
  my $raider = Langertha::Raider->new(
    engine     => $engine,
    mission    => 'Test',
    raider_mcp => 1,
  );
  my $f = $raider->raid_f('hi');
  my $settled = settles_within( $engine->async_loop, $f, 10 );
  return ( $settled, $settled ? ( $f->is_failed ? scalar $f->failure : "done: ".$f->get ) : undef );
}

subtest 'raid: IO::Async::Internals::Connector cannot load' => sub {
  my ( $settled, $error ) = raid_with_blocked(
    'IO/Async/Internals/Connector.pm', "http://127.0.0.1:$port/v1" );
  ok( $settled, 'the raid ends instead of hanging' );
  like( $error, qr/IO::Async::Internals::Connector/, 'the error names the module' );
  like( $error, qr/blocked by the test/, 'and carries the load error' );
};

subtest 'raid: IO::Async::SSL cannot load, https engine' => sub {
  my ( $settled, $error ) = raid_with_blocked(
    'IO/Async/SSL.pm', "https://127.0.0.1:$port/v1" );
  ok( $settled, 'the raid ends instead of hanging' );
  like( $error, qr/IO::Async::SSL/, 'the error names the module' );
  like( $error, qr/https/i, 'and says https needs it' );
};

subtest 'raid: IO::Async::SSL cannot load, http engine is unaffected' => sub {
  my ( $settled, $error ) = raid_with_blocked(
    'IO/Async/SSL.pm', "http://127.0.0.1:$port/v1" );
  ok( $settled, 'the raid ends' );
  like( $error, qr/Connection refused/, 'it got as far as connecting' );
};

subtest 'web tools: IO::Async::SSL cannot load' => sub {
  local $blocked{'IO/Async/SSL.pm'} = 1;
  local @ENV{qw( BRAVE_API_KEY SERPER_API_KEY GOOGLE_API_KEY GOOGLE_CSE_ID )};
  my $loop = IO::Async::Loop->new;
  my $server = build_web_tools_server( loop => $loop );
  my %tool = map { $_->name => $_ } @{ $server->tools };
  my $call = sub {
    my ( $name, $args ) = @_;
    my ( $result, $hung );
    # The tool code catches a die itself, so the flag tells a hang apart.
    local $SIG{ALRM} = sub { $hung = 1; die "hung\n" };
    alarm 10;
    eval { $result = $tool{$name}->code->( $tool{$name}, $args ); 1 };
    alarm 0;
    return $hung ? { hung => 1 } : $result;
  };

  for my $round (1, 2) {
    my $res = $call->( web_fetch => { url => "https://127.0.0.1:$port/" } );
    ok( !$res->{hung}, "web_fetch $round ends instead of hanging" );
    ok( $res->{isError}, "web_fetch $round is a tool error" );
    like( $res->{content}[0]{text}, qr/IO::Async::SSL/, "web_fetch $round names the module" );
  }

  my $res = $call->( web_search => { query => 'perl' } );
  ok( !$res->{hung}, 'web_search ends instead of hanging' );
  ok( $res->{isError}, 'web_search is a tool error' );
  like( $res->{content}[0]{text}, qr/IO::Async::SSL/, 'web_search names the module' );

  # An http URL that redirects to https: the check of the URL itself passes,
  # the redirect must not reach Net::Async::HTTP either (k109).
  my $redirector = IO::Async::Listener->new(
    on_stream => sub {
      my ( undef, $stream ) = @_;
      $stream->configure(
        on_read => sub {
          my ( $s, $buffref ) = @_;
          return 0 unless $$buffref =~ /\r\n\r\n/;
          $$buffref = '';
          $s->write( "HTTP/1.1 302 Found\r\nLocation: https://127.0.0.1:$port/\r\n"
            ."Content-Length: 0\r\nConnection: close\r\n\r\n" );
          $s->close_when_empty;
          return 0;
        },
      );
      $loop->add($stream);
    },
  );
  $loop->add($redirector);
  my $listening = $redirector->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
  my $http_port = $listening->read_handle->sockport;

  for my $round (1, 2) {
    my $res = $call->( web_fetch => { url => "http://127.0.0.1:$http_port/" } );
    ok( !$res->{hung}, "redirected web_fetch $round ends instead of hanging" );
    ok( $res->{isError}, "redirected web_fetch $round is a tool error" );
    like( $res->{content}[0]{text}, qr/IO::Async::SSL/, "redirected web_fetch $round names the module" );
    like( $res->{content}[0]{text}, qr{https://127\.0\.0\.1:$port}, "redirected web_fetch $round names the redirect target" );
  }
  $loop->remove($redirector);
};

done_testing;
