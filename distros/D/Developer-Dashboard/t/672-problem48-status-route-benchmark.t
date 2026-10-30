use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../script/problem48-status-route-benchmark";
my $repo_lib = abs_path("$Bin/../lib");

my ( $help_stdout, $help_stderr, $help_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--help' );
    return $? >> 8;
};
is( $help_exit, 0, 'status route benchmark help exits successfully' );
is( $help_stderr, q{}, 'status route benchmark help emits no stderr' );
like( $help_stdout, qr/--indicators N.*--iterations N.*--runs ODD_N/s,
    'status route benchmark help documents scale and sample options' );
like( $help_stdout, qr/--portable-config-cache/,
    'status route benchmark help documents a portable-config control' );

my ( $run_stdout, $run_stderr, $run_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--indicators', 2, '--iterations', 1, '--runs', 3 );
    return $? >> 8;
};
is( $run_exit, 0, 'small status route benchmark completes' );
is( $run_stderr, q{}, 'small status route benchmark emits no stderr' );
like( $run_stdout, qr/response_status=200 response_bytes=\d+ response_sha256=[0-9a-f]{64} exact_response_parity=yes/,
    'status route benchmark proves successful byte-identical responses' );
like( $run_stdout, qr/source_lib=\Q$repo_lib\E indicators=2 iterations=1 runs=3/s,
    'status route benchmark records selected source and workload size' );
like( $run_stdout, qr/config_merges=\d+ watcher_checks=\d+ watcher_hits=\d+/,
    'status route benchmark reports config-cache reuse and watcher validation counts' );
like( $run_stdout, qr/collector_projections=1\b/,
    'status route benchmark reports the single cached collector projection' );
like( $run_stdout, qr/collector_signature_encodes=1\b/,
    'status route benchmark reports that the validated collector signature is encoded once' );

my ( $portable_stdout, $portable_stderr, $portable_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--indicators', 2, '--iterations', 1, '--runs', 3, '--portable-config-cache' );
    return $? >> 8;
};
is( $portable_exit, 0, 'status route benchmark can force portable configuration validation' );
is( $portable_stderr, q{}, 'portable configuration benchmark emits no stderr' );
like( $portable_stdout, qr/config_snapshot=portable\b/,
    'portable configuration benchmark reports which freshness path ran' );
like( $portable_stdout, qr/exact_response_parity=yes/,
    'portable configuration validation preserves the exact status response' );

my ( $uncached_stdout, $uncached_stderr, $uncached_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--indicators', 2, '--iterations', 1, '--runs', 3, '--no-collector-cache' );
    return $? >> 8;
};
is( $uncached_exit, 0, 'status route benchmark can disable the collector projection cache' );
is( $uncached_stderr, q{}, 'uncached collector benchmark emits no stderr' );
like( $uncached_stdout, qr/collector_projections=6\b/,
    'uncached control rebuilds the collector projection for every warmup and sample request' );
like( $uncached_stdout, qr/exact_response_parity=yes/,
    'disabling the collector cache preserves the exact status response' );

my ( $signature_uncached_stdout, $signature_uncached_stderr, $signature_uncached_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--indicators', 2, '--iterations', 1, '--runs', 3, '--no-collector-signature-cache' );
    return $? >> 8;
};
is( $signature_uncached_exit, 0, 'status route benchmark can disable collector-signature reuse' );
is( $signature_uncached_stderr, q{}, 'uncached signature benchmark emits no stderr' );
like( $signature_uncached_stdout, qr/collector_signature_encodes=\d+/,
    'uncached signature benchmark reports collector signature work' );
unlike( $signature_uncached_stdout, qr/collector_signature_encodes=1\b/,
    'uncached signature control recomputes the collector signature on requests' );
like( $signature_uncached_stdout, qr/exact_response_parity=yes/,
    'disabling collector-signature reuse preserves the exact status response' );

my ( $bad_stdout, $bad_stderr, $bad_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--indicators', 0 );
    return $? >> 8;
};
isnt( $bad_exit, 0, 'status route benchmark rejects an empty inventory' );
like( $bad_stderr, qr/--indicators must be a positive integer/,
    'invalid benchmark input reports the exact correction' );

my ( $profile_stdout, $profile_stderr, $profile_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--profile' );
    return $? >> 8;
};
isnt( $profile_exit, 0, 'profile mode rejects a process without NYTProf' );
like( $profile_stderr, qr/--profile requires perl -d:NYTProf/,
    'profile mode explains how to enable NYTProf' );

done_testing;

__END__

=pod

=head1 NAME

672-problem48-status-route-benchmark.t - test matched status route benchmark

=head1 PURPOSE

Checks the Problem 48 `/system/status` benchmark's command-line contract,
source selection, byte-parity evidence, config and collector-projection cache
reuse counters, the no-cache comparison control, and explicit invalid-input
errors. Its portable-config option verifies that automatic collector sync can
be held constant while the config snapshot watcher alone is bypassed for a
cross-platform latency comparison.

=head1 WHY IT EXISTS

Performance work must use a reproducible route workload and must not infer
whole-dashboard speed from a helper microbenchmark. This test ensures the
benchmark can compare the current modules with another checked-out module tree
and reports whether watcher-backed config and normalized collector-projection
reuse actually occurred. Its no-cache controls verify that recomputing the
collector projection or collector-job signature does not alter the HTTP
response; its portable-config control verifies that bypassing only the config
watcher also preserves exact response bytes.

=head1 WHEN TO USE

Run after changing the benchmark script's setup, source selection, validation,
profile mode, or result format.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/672-problem48-status-route-benchmark.t

=head1 WHAT USES IT

Problem 48 profiling and regression work uses this test to protect the
benchmark interface and make failed comparisons explicit.

=head1 EXAMPLES

  prove -lv t/672-problem48-status-route-benchmark.t
  d2 docker compose exec dev prove -lv t/672-problem48-status-route-benchmark.t
  d2 docker compose exec dev perl script/problem48-status-route-benchmark --indicators 50 --iterations 100 --runs 21 --no-collector-cache
  d2 docker compose exec dev perl script/problem48-status-route-benchmark --indicators 50 --iterations 100 --runs 21 --portable-config-cache

=cut
