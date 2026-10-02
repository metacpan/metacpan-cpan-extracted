#!/usr/bin/env perl
# ABSTRACT: the async inline-image prefetch gives up after inline_image_fetch_timeout
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use IO::Socket::INET;
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use HTTP::Response;
use LWP::UserAgent;
use Time::HiRes qw( time );
use Test::LocalHTTPDaemon;
use Langertha::Content::Image;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OllamaOpenAI;

# karr k276 (ADR 0027, follow-up of k274): the _f paths fetch URL images an
# engine must inline through its async backend. Net::Async::HTTP has no
# timeout of its own, so an image host that accepts the connection and never
# answers stalled chat_f forever -- inside the event loop knarr/skeid serve
# every other request from -- where the sync build path gives up after 30s.
# The prefetch now races each fetch against inline_image_fetch_timeout on the
# backend's loop, fails with the engine-named inline-image error, sends no
# chat request, and cancels the fetch it gave up on (its connection closes).
# On the sync LWP fallback there is no loop and LWP's own timeout applies.

plan skip_all => 'Net::Async::HTTP not installed' unless eval { require Net::Async::HTTP; 1 };

my $json  = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $bytes = "\x89PNG-a";

# Accepts connections (the kernel completes the handshake) and never answers.
my $hang = IO::Socket::INET->new( Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', ReuseAddr => 1 ) or die "listen: $!";
my $hang_url = 'http://127.0.0.1:' . $hang->sockport . '/hang.png';

my $server = Test::LocalHTTPDaemon->start( sub {
  my ($req) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $bytes )
    if $req->uri->path eq '/a.png';
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode( { id => 'x', object => 'chat.completion', created => 1, model => 'm',
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'ok' } } ] } ) );
} );
my $base = $server->url;

# Record every backend request and every loop timer the code under test starts.
my ( @requests, @timers );
{
  no warnings 'redefine';
  my $do_request = \&Net::Async::HTTP::do_request;
  *Net::Async::HTTP::do_request = sub {
    my ( $self, %args ) = @_;
    my $f = $do_request->(@_);
    push @requests, [ $args{request}->method, $args{request}->uri->path, $f ];
    return $f;
  };
  require IO::Async::Loop;
  my $delay_future = \&IO::Async::Loop::delay_future;
  *IO::Async::Loop::delay_future = sub {
    my $f = $delay_future->(@_);
    push @timers, $f;
    return $f;
  };
}

# Runs $f on the loop, but never longer than $max seconds (so a regression
# reports a failure instead of hanging the suite).
sub run_capped {
  my ( $loop, $f, $max ) = @_;
  my $cap = $loop->delay_future( after => $max );
  $loop->await( Future->wait_any( $f->without_cancel, $cap ) );
  $cap->cancel unless $cap->is_ready;
  return $f;
}

# --- A hanging image host fails chat_f after the configured timeout ---
{
  my $e = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm',
    inline_image_fetch_timeout => 1 );
  is $e->inline_image_fetch_timeout, 1, 'the timeout is an engine attribute';
  my $loop = $e->async_loop;
  ok $loop, 'Net::Async::HTTP backend has a loop';
  @requests = (); @timers = ();

  my $t0 = time;
  my $f  = $e->chat_f( messages => [ { role => 'user',
    content => [ 'x', Langertha::Content::Image->from_url($hang_url) ] } ] );
  run_capped( $loop, $f, 10 );
  my $took = time - $t0;

  ok $f->is_failed, 'chat_f fails instead of hanging on the image host';
  like scalar( $f->is_failed ? $f->failure : '' ),
    qr/\ALangertha::Engine::OllamaOpenAI: this endpoint takes only inline images .*could not be inlined \(ensure_base64: failed to fetch \Q$hang_url\E: timed out after 1s\); pass the image as base64/s,
    '... with the engine-named inline-image error naming URL and timeout';
  ok $took >= 0.9 && $took < 5, "... after about the configured second (took ${\ sprintf '%.2f', $took }s)";
  is_deeply [ map { [ @$_[0,1] ] } @requests ], [ [ GET => '/hang.png' ] ],
    '... and no chat request was sent';
  ok $requests[0][2]->is_cancelled, '... the pending fetch Future was cancelled';
  $loop->loop_once(0.1);
  is scalar( $e->_async_http->children ), 0, '... and its connection closed (no notifier left behind)';
}

# --- A fetch that answers in time cancels its timer ---
{
  my $e = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm',
    inline_image_fetch_timeout => 7 );
  @requests = (); @timers = ();
  my $img = Langertha::Content::Image->from_url("$base/a.png");
  my $f = $e->chat_f( messages => [ { role => 'user', content => [ 'x', $img ] } ] );
  my @fetch_timers = @timers;   # before run_capped adds its own cap
  run_capped( $e->async_loop, $f, 10 );
  ok $f->is_done, 'an image that arrives in time goes through';
  is $img->base64, encode_base64( $bytes, '' ), '... inlined';
  is scalar(@fetch_timers), 1, '... raced against one timeout timer';
  ok @fetch_timers && $fetch_timers[0]->is_cancelled, '... which is cancelled, not left on the loop';
}

# --- inline_image_fetch_timeout => 0 disables the race ---
{
  my $e = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm',
    inline_image_fetch_timeout => 0 );
  @timers = ();
  my $f = $e->chat_f( messages => [ { role => 'user',
    content => [ 'x', Langertha::Content::Image->from_url("$base/a.png") ] } ] );
  my $n = scalar @timers;
  run_capped( $e->async_loop, $f, 10 );
  ok $f->is_done, 'timeout 0: the fetch still works';
  is $n, 0, '... without a timer';
}

# --- Sync LWP fallback: no loop, LWP's own timeout applies ---
{
  my $ua = LWP::UserAgent->new( timeout => 1 );
  my $e  = Langertha::Engine::OllamaOpenAI->new( url => "$base/v1", model => 'm', user_agent => $ua,
    _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ) );
  is $e->async_loop, undef, 'sync fallback has no loop';
  @timers = ();
  my $f = $e->chat_f( messages => [ { role => 'user',
    content => [ 'x', Langertha::Content::Image->from_url($hang_url) ] } ] );
  ok $f->is_failed, "sync fallback: LWP's timeout fails the fetch";
  like scalar( $f->is_failed ? $f->failure : '' ),
    qr/could not be inlined \(ensure_base64: failed to fetch \Q$hang_url\E: 500 read timeout\)/,
    '... with the same engine-named error';
  is scalar(@timers), 0, '... and no loop timer was started';
}

done_testing;
