#!/usr/bin/env perl
# ABSTRACT: A 200 body that carries an error ends the raid loudly, not silently with ''
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Langertha::Engine::OpenAI;
use Langertha::Raider;

# Core k321 moved the tool loops onto chat_response, so a provider (or gateway)
# that answers HTTP 200 with an error object in the body croaks instead of
# parsing to no calls and empty text. Raider used to read replies with
# response_tool_calls + response_text_content, which both return empty on such a
# body, so the raid ended silently with "". It now reads them through the public
# Langertha::Role::Tools->tool_loop_response hook (karr k85), so the error is
# surfaced. This needs a real engine carrying that hook; the duck-typed engines
# in the other raid-loop tests exercise the legacy fallback path instead.

plan skip_all => 'this Langertha has no public tool_loop_response hook'
  unless Langertha::Engine::OpenAI->can('tool_loop_response')
      && Langertha::Engine::OpenAI->can('chat_response');

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

my @inline_tools = ({
  name => 'noop', description => 'no-op',
  input_schema => { type => 'object', properties => {} },
  code => sub { $_[0]->text_result('ok') },
});

sub raider_for {
  my ( $body ) = @_;
  my $engine = FakeOpenAI->new(api_key => 'x', body => $body);
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
  );
  return ( $engine, $raider );
}

# Runs the raid under an alarm, so a hang fails the test instead of stalling CI.
sub raid_result {
  my ( $raider ) = @_;
  my ( $result, $err );
  {
    local $@;
    $result = eval {
      local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
      alarm 5;
      my $r = $raider->raid('hi');
      alarm 0;
      $r;
    };
    $err = $@;
    alarm 0;
  }
  return ( $result, $err );
}

subtest 'a 200 body carrying an error ends the raid loudly, not with ""' => sub {
  my ( $engine, $raider ) = raider_for(
    { error => { message => 'upstream exploded', type => 'server_error' } });
  my ( $result, $err ) = raid_result($raider);
  unlike($err, qr/TIMEOUT/, 'the raid does not hang');
  ok($err, 'the raid dies instead of returning');
  like($err, qr/response carried an error/, 'the error in the body is surfaced');
  like($err, qr/upstream exploded/, 'the provider message is included');
  is($engine->requests, 1, 'the turn was sent');
};

subtest 'a normal 200 body yields the reply text through the hook path' => sub {
  my ( $engine, $raider ) = raider_for({
    id     => 'r1',
    model  => 'gpt-test',
    choices => [ {
      index         => 0,
      finish_reason => 'stop',
      message       => { role => 'assistant', content => 'hello there' },
    } ],
  });
  my ( $result, $err ) = raid_result($raider);
  is($err, '', 'no error on a normal reply');
  is("$result", 'hello there', 'the assistant text is returned');
  is($engine->requests, 1, 'one turn');
};

done_testing;
