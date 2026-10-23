#!/usr/bin/env perl
# ABSTRACT: an engine takes the Net::Async::HTTP client it built off the loop when it goes away, and leaves an injected one alone
use strict; use warnings;
use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
  eval { require Net::Async::HTTP; require IO::Async::Loop; 1 }
    or plan skip_all => 'Requires Net::Async::HTTP and IO::Async (the async backend under test)';
}

use Future;
use HTTP::Response;
use JSON::MaybeXS;
use Scalar::Util qw( refaddr );
use Test::LocalHTTPDaemon;
use Langertha::Engine::OpenAI;

# Role::AsyncHTTP adds the Net::Async::HTTP client it builds to the engine's
# loop (the process-wide one by default), and nothing took it off again: every
# engine object left its client -- and the client's keep-alive connections,
# open sockets included -- on the loop for the rest of the process.
# langertha-raider builds an engine per subagent, so a long-running raider
# grew without bound (karr k379). The engine now removes the client it built
# when it is destroyed. A client the caller injected (_async_http => ...) is
# the caller's: the engine never touches its place on the loop. Destruction at
# program exit must stay silent, whatever was torn down first.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $server = Test::LocalHTTPDaemon->start( sub {
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode({
      id      => 'chatcmpl-1',
      object  => 'chat.completion',
      model   => 'gpt-test',
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'pong' } } ],
    }) );
}, keep_alive => 1 );

my $loop = IO::Async::Loop->new;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub engine {
  my (%args) = @_;
  return Langertha::Engine::OpenAI->new(
    api_key => 'test-key', model => 'gpt-test', url => $server->url . '/v1', %args );
}

sub notifier_count { my ($l) = @_; return scalar( () = ( $l // $loop )->notifiers ) }

sub drive {
  my ($future) = @_;
  my $timeout = $loop->delay_future( after => 15 );
  $loop->await( Future->wait_any( $future, $timeout->then_fail("timed out\n") ) );
  return $future->is_done ? $future->get : 'failed: ' . ( $future->is_failed ? ( $future->failure )[0] : 'cancelled' );
}

subtest 'many short-lived engines that only selected their backend' => sub {
  @warnings = ();
  my $before = notifier_count();
  my $seen   = 0;
  for ( 1 .. 50 ) {
    my $engine = engine();
    my $http   = $engine->_async_http;
    $seen++ if $http->isa('Net::Async::HTTP') && $http->loop && $http->loop == $loop;
  }
  is( $seen, 50, 'each engine had its own Net::Async::HTTP client on the process-wide loop' );
  is( notifier_count(), $before, 'no client is left on the loop once the engines are gone' );
  is_deeply( \@warnings, [], 'no warnings' );
};

subtest 'many short-lived engines that each held a keep-alive connection' => sub {
  @warnings = ();
  # The first connect makes the loop build its own resolver (two notifiers it
  # keeps for good), so the baseline is taken after one request.
  is( drive( engine()->simple_chat_f('ping') ), 'pong', 'warm-up request' );
  my $before = notifier_count();
  my $answered = 0;
  for ( 1 .. 20 ) {
    my $engine = engine();
    $answered++ if drive( $engine->simple_chat_f('ping') ) eq 'pong';
  }
  is( $answered, 20, 'every engine got its answer' );
  is( notifier_count(), $before, 'neither the clients nor their connections stay on the loop' );
  is_deeply( \@warnings, [], 'no warnings' );
};

subtest 'an injected client stays where its owner put it' => sub {
  @warnings = ();
  my $http = Net::Async::HTTP->new( pipeline => 0 );
  $loop->add($http);
  # Warm it up first: its own keep-alive connection is part of its state.
  is( drive( engine( _async_http => $http )->simple_chat_f('ping') ), 'pong', 'warm-up through the injected client' );
  my $before = notifier_count();
  for ( 1 .. 5 ) {
    my $engine = engine( _async_http => $http );
    is( drive( $engine->simple_chat_f('ping') ), 'pong', "engine $_ answered through the injected client" );
  }
  ok( $http->loop && $http->loop == $loop, 'the injected client is still on its loop' );
  ok( ( grep { refaddr($_) == refaddr($http) } $loop->notifiers ), 'and in the loop\'s notifiers' );
  is( drive( engine( _async_http => $http )->simple_chat_f('ping') ), 'pong', 'and still serves a later engine' );
  is( notifier_count(), $before, 'the engines added nothing of their own and removed nothing' );
  $loop->remove($http);
  is_deeply( \@warnings, [], 'no warnings' );
};

subtest 'the client is removed from an _async_loop passed at construction' => sub {
  @warnings = ();
  my $own = IO::Async::Loop->really_new;
  {
    my $engine = engine( _async_loop => $own );
    ok( $engine->_async_http->loop == $own, 'the client sits on the given loop' );
    is( notifier_count($own), 1, 'one notifier on it while the engine lives' );
  }
  is( notifier_count($own), 0, 'none after the engine is gone' );
  is_deeply( \@warnings, [], 'no warnings' );
};

subtest 'a client its owner already took off the loop is not removed twice' => sub {
  @warnings = ();
  my $before = notifier_count();
  {
    my $engine = engine();
    my $http   = $engine->_async_http;
    $loop->remove($http);
  }
  is( notifier_count(), $before, 'loop unchanged' );
  is_deeply( \@warnings, [], 'no warnings and no error from the engine\'s destruction' );
};

# Global destruction: the engine, its client and the loop are torn down in no
# particular order. A short program keeps them alive until exit: an engine in
# a global on the process-wide loop (held in a file lexical), one on its own
# loop (a global too), and one in a reference cycle with itself, which only
# global destruction frees.
subtest 'destruction at program exit is silent' => sub {
  my $lib  = "$FindBin::Bin/../lib";
  my $code = join ' ',
    'my %args = ( api_key => "k", url => "http://127.0.0.1:1/v1" );',
    'my $loop = IO::Async::Loop->new;',
    'our $on_default = Langertha::Engine::OpenAI->new(%args); $on_default->_async_http;',
    'our $own_loop = IO::Async::Loop->really_new;',
    'our $on_own = Langertha::Engine::OpenAI->new(%args, _async_loop => $own_loop); $on_own->_async_http;',
    '{ my $cycle = Langertha::Engine::OpenAI->new(%args); $cycle->_async_http; $cycle->{_self_cycle} = $cycle; }',
    'print "ready\n";';
  my $out = qx{"$^X" -I"$lib" -MIO::Async::Loop -MLangertha::Engine::OpenAI -we '$code' 2>&1};
  is( $?, 0, 'exit status 0' );
  is( $out, "ready\n", 'nothing on stderr' );
};

done_testing;
