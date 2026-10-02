#!/usr/bin/env perl
# ABSTRACT: chat_f resolves over the sync fallback without IO::Async/Net::Async::HTTP
use strict; use warnings;
use Test2::Bundle::More;

BEGIN {
  # Block the async stack for this process before anything loads it.
  unshift @INC, sub {
    my (undef, $file) = @_;
    die "blocked: $file\n" if $file =~ m{^(Net/Async/HTTP|IO/Async)};
    return;
  };
}

BEGIN {
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use Future::AsyncAwait;
use JSON::MaybeXS;
use HTTP::Response;

# A canned Ollama /api/chat response body — the engine's response_call parses
# message.content into a Langertha::Response.
my $canned = JSON::MaybeXS->new(utf8 => 1)->encode({
  model      => 'qwen3:8b',
  created_at => '2026-02-22T04:00:52.709332618Z',
  message    => { role => 'assistant', content => 'hello sync' },
  done       => JSON::MaybeXS::true(),
  done_reason        => 'stop',
  prompt_eval_count  => 5,
  eval_count         => 2,
});

# Mock user_agent: a real LWP::UserAgent subclass (satisfies Role::HTTP's isa
# constraint) whose request() records the call and returns the canned response.
# Injected as the engine's user_agent, this is exactly what the sync fallback
# (Role::AsyncHTTP -> Langertha::Request::SyncHTTP) runs over.
{
  package MockUA;
  use parent -norequire, 'LWP::UserAgent';
  sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new;
    $self->{canned}   = $args{canned};
    $self->{requests} = [];
    return $self;
  }
  sub request {
    my ($self, $request) = @_;
    push @{$self->{requests}}, $request;
    return HTTP::Response->new(200, 'OK',
      [ 'Content-Type' => 'application/json' ], $self->{canned});
  }
  sub requests { $_[0]->{requests} }
}

require LWP::UserAgent;
require Langertha::Engine::Ollama;

my $mock_ua = MockUA->new( canned => $canned );

# NB: no _async_http injected -> Role::AsyncHTTP must select the sync fallback
# because Net::Async::HTTP is blocked from @INC. It warns once and wraps the
# engine's user_agent in Langertha::Request::SyncHTTP.
my $ollama = Langertha::Engine::Ollama->new(
  url        => 'http://test.invalid:11434',
  model      => 'qwen3:8b',
  user_agent => $mock_ua,
);

my @warnings;
my $response = do {
  local $SIG{__WARN__} = sub { push @warnings, "@_" };
  $ollama->chat_f( messages => [ { role => 'user', content => 'hi' } ] )->get;
};

isa_ok($response, ['Langertha::Response'], 'chat_f resolved to a Response over the sync fallback');
like("$response", qr/hello sync/, 'content came back over the sync path');
is(scalar @{$mock_ua->requests}, 1, 'exactly one HTTP request went through the sync shim');
is(scalar(grep { /synchronous/i } @warnings), 1, 'sync-fallback warning fired once');

ok(!$INC{'IO/Async/Loop.pm'}, 'IO::Async::Loop never loaded on the sync path');
ok(!$INC{'Net/Async/HTTP.pm'}, 'Net::Async::HTTP never loaded on the sync path');

done_testing;
