#!/usr/bin/env perl
# ABSTRACT: async subs must not require a module in their own frame while a coderef @INC hook is installed
use strict; use warnings;
use Test2::Bundle::More;

BEGIN {
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

# Future::AsyncAwait (0.71 on perl 5.38+) cannot suspend an async sub whose own
# frame still holds the `local $INC` that perl pushes while a coderef @INC hook
# runs: a first-time `require` in the async sub's body followed by an await on
# a pending future aborts the process with
#   Future::AsyncAwait panic: ... SAVEt_SV with gv != PL_errgv ($main::INC)
# The abort is a SIGABRT, not a die, so the scenario runs in a child perl: a
# regression shows up here as a failed assertion instead of taking this test
# file down with it. The child uses a pass-through hook, standing in for PAR,
# lib::relative-style loaders or a test blocker. (karr k193)

# poll_metrics_f is not covered: it loads nothing lazily (HTTP::Request is
# loaded with the role, and by LWP long before), so it has no first-time
# require to trip over.

note( 'perl < 5.38 does not localize $INC around @INC hook calls: the panic '
    . 'condition is not reachable here, this run only checks the call itself' )
  if $] < 5.038;

my @inc = map { "-I$_" } grep { !ref } @INC;

sub run_child {
  my ($code) = @_;
  my $preamble = <<'PERL';
BEGIN { unshift @INC, sub { return } }
use strict; use warnings;
$| = 1;   # keep output that precedes an abort
use Future;
use HTTP::Response;
require Langertha::Engine::vLLM;
{
  package PendingClient;
  sub new { bless { pending => [] }, shift }
  sub do_request {
    my ($self, %args) = @_;
    my $future = Future->new;
    push @{ $self->{pending} }, [ $future, $args{request} ];
    return $future;
  }
}
my $client = PendingClient->new;
my $engine = Langertha::Engine::vLLM->new(
  url         => 'http://test.invalid:8000/v1',
  model       => 'Qwen/Qwen2.5-7B-Instruct',
  _async_http => $client,
);
PERL
  open my $out, '-|', $^X, @inc, '-e', $preamble . $code
    or die "cannot run child perl: $!";
  my @lines = <$out>;
  close $out;
  chomp @lines;
  return ( $?, { map { split /=/, $_, 2 } grep { /=/ } @lines } );
}

subtest 'export_otlp_f loads OTLP lazily, then suspends on a pending request' => sub {
  my ( $status, $seen ) = run_child(<<'PERL');
print "preloaded=", ( $INC{'Langertha/Runtime/Metrics/OTLP.pm'} ? 1 : 0 ), "\n";
my $future = $engine->export_otlp_f( [], endpoint => 'http://test.invalid:4318/v1/metrics' );
print "pending=", ( $future->is_ready ? 0 : 1 ), "\n";
my ( $request_future, $request ) = @{ $client->{pending}[0] };
print "method=", $request->method, "\n";
$request_future->done( HTTP::Response->new( 200, 'OK' ) );
print "code=", $future->get->code, "\n";
PERL
  is( $seen->{preloaded}, 0,
    'OTLP was not loaded before the call (the require really is first-time)' );
  is( $status & 127, 0, 'child perl was not killed by a signal (no Future::AsyncAwait panic)' );
  is( $status >> 8, 0, 'child perl exited cleanly' );
  is( $seen->{pending}, 1, 'export_otlp_f suspended on the pending request future' );
  is( $seen->{method}, 'POST', 'the OTLP POST reached the injected client' );
  is( $seen->{code}, 200, 'export_otlp_f resolved with the response once the request completed' );
};

done_testing;
