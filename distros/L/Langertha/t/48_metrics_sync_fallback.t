#!/usr/bin/env perl
# ABSTRACT: poll_metrics runs over the sync fallback without IO::Async/Net::Async::HTTP
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

use HTTP::Response;

my $canned = <<'EOF';
# HELP vllm:num_requests_running Number of running requests
# TYPE vllm:num_requests_running gauge
vllm:num_requests_running{model_name="Qwen/Qwen2.5-7B-Instruct"} 3
# HELP vllm:prompt_tokens_total Prompt tokens processed
# TYPE vllm:prompt_tokens_total counter
vllm:prompt_tokens_total{model_name="Qwen/Qwen2.5-7B-Instruct"} 18234
EOF

# Mock user_agent: a real LWP::UserAgent subclass whose request() returns the
# canned Prometheus body. This is what the sync fallback runs over.
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
      [ 'Content-Type' => 'text/plain' ], $self->{canned});
  }
  sub requests { $_[0]->{requests} }
}

require LWP::UserAgent;
require Langertha::Engine::vLLM;

my $mock_ua = MockUA->new( canned => $canned );

# No _async_http injected -> Role::AsyncHTTP selects the sync fallback because
# Net::Async::HTTP is blocked from @INC.
my $vllm = Langertha::Engine::vLLM->new(
  url        => 'http://test.invalid:8000/v1',
  model      => 'Qwen/Qwen2.5-7B-Instruct',
  user_agent => $mock_ua,
);

my @warnings;
my $records = do {
  local $SIG{__WARN__} = sub { push @warnings, "@_" };
  $vllm->poll_metrics('vllm:');
};

is(ref($records), 'ARRAY', 'poll_metrics returned the parsed ArrayRef over the sync path');
my %by_name = map { $_->{name} => $_ } @$records;
is($by_name{'vllm:num_requests_running'}{value}, 3, 'parsed the canned gauge value');
is(scalar @{$mock_ua->requests}, 1, 'exactly one /metrics request went through the sync shim');
is(scalar(grep { /synchronous/i } @warnings), 1, 'sync-fallback warning fired once');

# An injected client whose futures are still pending when returned (a real
# async client on the user's own loop). The sync wrappers must let the future
# drive itself via ->get, not build a private IO::Async loop (IO::Async is
# blocked in this process, so doing that would die). SelfDrivingFuture stands in
# for any loop-aware Future subclass: its await() runs the pending work, as
# IO::Async::Future does with its loop.
{
  package SelfDrivingFuture;
  use parent -norequire, 'Future';
  our @PENDING;
  sub await {
    my ($self) = @_;
    ( shift @PENDING )->() while !$self->is_ready && @PENDING;
    return $self;
  }
}
{
  package PendingClient;
  sub new { bless { requests => [] }, shift }
  sub do_request {
    my ($self, %args) = @_;
    push @{$self->{requests}}, $args{request};
    my $future = SelfDrivingFuture->new;
    push @SelfDrivingFuture::PENDING, sub {
      $future->done(HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/plain' ], $canned));
    };
    return $future;
  }
}
{
  my $client = PendingClient->new;
  my $injected = Langertha::Engine::vLLM->new(
    url         => 'http://test.invalid:8000/v1',
    model       => 'Qwen/Qwen2.5-7B-Instruct',
    _async_http => $client,
  );
  my $records = eval { $injected->poll_metrics('vllm:') };
  is($@, '', 'poll_metrics over a pending injected client does not need IO::Async');
  is(ref($records), 'ARRAY', 'records came back through the injected client');
  my $response = eval { $injected->export_otlp($records // [], endpoint => 'http://test.invalid:4318/v1/metrics') };
  is($@, '', 'export_otlp over a pending injected client does not need IO::Async');
  is(eval { $response->code }, 200, 'export_otlp returned the response');
  is(scalar @{$client->{requests}}, 2, 'both requests went through the injected client');
}

ok(!$INC{'IO/Async/Loop.pm'}, 'IO::Async::Loop never loaded on the sync path');
ok(!$INC{'Net/Async/HTTP.pm'}, 'Net::Async::HTTP never loaded on the sync path');

done_testing;
