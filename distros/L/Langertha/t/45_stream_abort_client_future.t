#!/usr/bin/env perl
# ABSTRACT: a chunk-sub die keeps its exception and stays in the chunk-sub, whatever future the injected client returns
use strict; use warnings;
use Test2::Bundle::More;

BEGIN {
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use Future;
use HTTP::Response;
use JSON::MaybeXS;
use Langertha::Engine::OpenAI;

# When the chunk callback dies, chat_stream_realtime_f stops the transfer on
# the future's own loop, or lets a loop-less client drain (karr k194, ADR
# 0027). Two edges of that, both reachable only through an injected client
# (karr k199):
#
# - The transfer can still end in a transport failure after the die (the peer
#   resets while the rest is drained). The caller must get the exception that
#   stopped the stream, not the transport error it provoked.
# - An injected client may return futures whose loop() belongs to another
#   event system and has no later(). Calling it died inside the chunk-sub, i.e.
#   inside the client's read handler: exactly what the k194 fix keeps out of
#   there. Such a client is drained like a loop-less one.
#
# The client below is driven by hand: do_request only records the callbacks,
# the test plays the server.

{
  package Test::HandClient;
  sub new { my ( $class, $future_class ) = @_; bless { future_class => $future_class }, $class }
  sub do_request {
    my ( $self, %args ) = @_;
    $self->{on_header} = $args{on_header};
    return $self->{future} = $self->{future_class}->new;
  }
}
{
  package Test::ForeignLoop;       # another event system's loop: no later()
  sub new { bless {}, shift }
}
{
  package Test::ForeignFuture;
  our @ISA = ('Future');
  sub loop { Test::ForeignLoop->new }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $sse  = 'data: ' . $json->encode({ choices => [ { index => 0, delta => { content => 'Hel' } } ] }) . "\n\n";

sub start_stream {
  my ($future_class) = @_;
  my $client = Test::HandClient->new($future_class);
  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'test-key', model => 'gpt-test', _async_http => $client );
  my $stream = $engine->chat_stream_realtime_f(
    messages       => [ { role => 'user', content => 'hi' } ],
    chunk_callback => sub { die "user abort\n" },
  );
  my $response = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ] );
  my $body_sub = $client->{on_header}->($response);
  return ( $client, $stream, $body_sub, $response );
}

sub outcome {
  my ($future) = @_;
  return 'pending' unless $future->is_ready;
  return 'failed: ' . ( $future->failure )[0] if $future->is_failed;
  return 'done';
}

subtest 'a transport failure after the die does not mask the exception' => sub {
  my ( $client, $stream, $body_sub ) = start_stream('Future');
  is( ( eval { $body_sub->($sse); 1 } ? '' : $@ ), '', 'the die stayed inside the chunk-sub' );
  is( outcome($stream), 'pending', 'the stream waits for the transfer to end' );
  $client->{future}->fail( "Connection reset by peer\n", 'http' );
  is( outcome($stream), "failed: user abort\n", 'it fails with the chunk_callback exception, not the transport error' );
};

subtest 'a future whose loop has no later() is drained' => sub {
  my ( $client, $stream, $body_sub, $response ) = start_stream('Test::ForeignFuture');
  is( ( eval { $body_sub->($sse); 1 } ? '' : $@ ), '', 'no exception out of the chunk-sub into the client' );
  is( outcome($stream), 'pending', 'the stream waits for the transfer to end' );
  $body_sub->($sse);           # the rest of the body arrives and is dropped
  $client->{future}->done($response);
  is( outcome($stream), "failed: user abort\n", 'then it fails with the chunk_callback exception' );
};

done_testing;
