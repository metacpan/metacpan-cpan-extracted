#!/usr/bin/env perl
# ABSTRACT: compress_history_f surfaces a 200-error body loudly, not as an empty summary
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Langertha::Engine::OpenAI;
use Langertha::Raider;

# compress_history_f is a plain (non-tool) chat that summarizes the working
# history. It used to read the reply with response_text_content, which never
# croaks: a provider (or gateway) answering HTTP 200 with an error object in the
# body parsed to empty text, so the compression silently replaced the history
# with "". It now reads the summary through the engine's public chat_response
# hook (the parser chat_f uses), so the error is surfaced. This needs a real
# engine carrying that hook; the duck-typed engines in the other compression
# tests (t/89, t/93) exercise the legacy fallback path instead.

plan skip_all => 'this Langertha has no public chat_response hook'
  unless Langertha::Engine::OpenAI->can('chat_response');

{
  # A real OpenAI engine whose only override is the HTTP round trip: parse_response
  # and chat_response stay the genuine ones, so the reply is read exactly as core
  # reads it. Answers every request with a canned 200 whose body is `body`.
  package FakeOpenAI;
  use Moose;
  use HTTP::Response;
  extends 'Langertha::Engine::OpenAI';
  has _loop    => (is => 'ro', default => sub { IO::Async::Loop->new });
  has body     => (is => 'ro', required => 1);
  has requests => (is => 'rw', default => 0);
  sub async_loop { $_[0]->_loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->requests($self->requests + 1);
    my $http = HTTP::Response->new(200, 'OK',
      [ 'Content-Type' => 'application/json' ], $self->json->encode($self->body));
    return $self->_loop->delay_future(after => 0)->then_done($http);
  }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed engine with no chat_response: the legacy fallback path. Its
  # response_text_content returns a canned summary regardless of the body.
  package NoHookEngine;
  use Moose;
  has _loop    => (is => 'ro', default => sub { IO::Async::Loop->new });
  has requests => (is => 'rw', default => 0);
  sub async_loop { $_[0]->_loop }
  sub async_request_f {
    my ( $self ) = @_;
    $self->requests($self->requests + 1);
    return $self->_loop->delay_future(after => 0)->then_done({ text => 'legacy summary' });
  }
  sub chat_request          { return { request => 1 } }
  sub parse_response        { return $_[1] }
  sub response_text_content { return $_[1]->{text} }
  __PACKAGE__->meta->make_immutable;
}

sub raider_for {
  my ( $engine ) = @_;
  return Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    history               => [ { role => 'user', content => 'a turn to summarize' } ],
  );
}

# Runs compression under an alarm, so a hang fails the test instead of stalling CI.
sub compress_result {
  my ( $raider ) = @_;
  my ( $summary, $err );
  {
    local $@;
    $summary = eval {
      local $SIG{ALRM} = sub { die "TIMEOUT: compression hung\n" };
      alarm 5;
      my $s = $raider->compress_history;
      alarm 0;
      $s;
    };
    $err = $@;
    alarm 0;
  }
  return ( $summary, $err );
}

subtest 'a 200 body carrying an error ends compression loudly, not with ""' => sub {
  my $engine = FakeOpenAI->new(api_key => 'x',
    body => { error => { message => 'upstream exploded', type => 'server_error' } });
  my $raider = raider_for($engine);
  my ( $summary, $err ) = compress_result($raider);
  unlike($err, qr/TIMEOUT/, 'compression does not hang');
  ok($err, 'compression dies instead of returning');
  like($err, qr/response carried an error/, 'the error in the body is surfaced');
  like($err, qr/upstream exploded/, 'the provider message is included');
  is($engine->requests, 1, 'the summary request was sent');
  # The failed compression must not have replaced the history with an empty
  # summary: the original turn is still there.
  is($raider->history, [ { role => 'user', content => 'a turn to summarize' } ],
    'history is left untouched, not silently emptied');
};

subtest 'a normal 200 body yields the summary through the hook path' => sub {
  my $engine = FakeOpenAI->new(api_key => 'x', body => {
    id      => 'c1',
    model   => 'gpt-test',
    choices => [ {
      index         => 0,
      finish_reason => 'stop',
      message       => { role => 'assistant', content => 'a concise summary' },
    } ],
  });
  my $raider = raider_for($engine);
  my ( $summary, $err ) = compress_result($raider);
  is($err, '', 'no error on a normal reply');
  is($summary, 'a concise summary', 'the summary text is returned');
  is($raider->history, [ { role => 'assistant', content => 'a concise summary' } ],
    'working history is replaced with the summary');
  is($engine->requests, 1, 'one summary request');
};

subtest 'an engine without chat_response falls back to response_text_content' => sub {
  my $engine = NoHookEngine->new;
  my $raider = raider_for($engine);
  my ( $summary, $err ) = compress_result($raider);
  is($err, '', 'no error on the fallback path');
  is($summary, 'legacy summary', 'the legacy reader returns the summary');
  is($engine->requests, 1, 'one summary request');
};

done_testing;
