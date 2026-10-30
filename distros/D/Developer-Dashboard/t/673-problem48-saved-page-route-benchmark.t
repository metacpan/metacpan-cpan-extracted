use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Test::More;

my $script = "$Bin/../script/problem48-saved-page-route-benchmark";
my $repo_lib = abs_path("$Bin/../lib");
my $native_watch_backend_available;
{
    local @INC = ( $repo_lib, @INC );
    require Developer::Dashboard::IndicatorStore::Watch;
    my $watcher = Developer::Dashboard::IndicatorStore::Watch->new;
    $native_watch_backend_available = defined $watcher ? 1 : 0;
}

my ( $help_stdout, $help_stderr, $help_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--help' );
    return $? >> 8;
};
is( $help_exit, 0, 'saved-page route benchmark help exits successfully' );
is( $help_stderr, q{}, 'saved-page route benchmark help emits no stderr' );
like( $help_stdout, qr/--iterations N.*--runs ODD_N.*--skill-nav-fragments N.*--indicators N.*--no-prompt-summary-cache.*--legacy-config-snapshot-signature/s,
    'saved-page route benchmark documents its workload options' );

my ( $run_stdout, $run_stderr, $run_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3 );
    return $? >> 8;
};
is( $run_exit, 0, 'small saved-page route benchmark completes' );
is( $run_stderr, q{}, 'saved-page route benchmark emits no stderr' );
like( $run_stdout,
    qr/route=\/app\/welcome nav_fragments=5 skill_nav_fragments=0 response_status=200 response_bytes=\d+ response_sha256=[0-9a-f]{64} exact_repeat_parity=yes/,
    'benchmark records saved route status, response hash, and repeat parity' );
my ($response_hash) = $run_stdout =~ /response_sha256=([0-9a-f]{64})/;
ok( defined $response_hash, 'default route benchmark exposes a response hash for parity comparisons' );
like( $run_stdout, qr/iterations=2 runs=3 .*median_ms_per_request=[0-9.]+/,
    'benchmark records workload size and median route latency' );
like( $run_stdout, qr/native_watch_backend=(?:available|unavailable)/,
    'benchmark reports whether the optional native watch backend is available' );
my ($snapshot_hits) = $run_stdout =~ /saved_nav_snapshot_cache_requested=enabled hits=(\d+)/;
ok( defined $snapshot_hits, 'benchmark reports observed saved-nav snapshot cache hits' );
if ($native_watch_backend_available) {
    like( $run_stdout, qr/nav_cache=enabled nav_inventory_scans=1/,
        'native watcher-backed default benchmark scans unchanged nav inventory once' );
    like( $run_stdout, qr/page_containment_checks=6/,
        'native watcher-backed snapshot checks containment while filling once' );
    cmp_ok( $snapshot_hits, '>', 0, 'native watcher-backed benchmark records actual snapshot hits' );
} else {
    is( $snapshot_hits, 0, 'optional-backend fallback reports no saved-nav snapshot hits' );
}
like( $run_stdout, qr/nav_content_cache=enabled\n.*nav_fragment_file_reads=5\n/s,
    'default benchmark populates each literal fragment once and avoids warmed file reads' );
like( $run_stdout, qr/nav_candidate_searches=0\n/s,
    'saved nav lookups use their scanned layer provenance without searching all page roots' );
like( $run_stdout, qr/nav_fragment_file_reads=5\b/,
    'default benchmark reads each literal nav fragment once, then serves the validated cache' );
like( $run_stdout, qr/page_root_cache=enabled page_root_lookups=6/,
    'default benchmark discovers ordered page roots once per request' );

my ( $legacy_signature_stdout, $legacy_signature_stderr, $legacy_signature_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--nav-fragments', 5, '--legacy-config-snapshot-signature' );
    return $? >> 8;
};
is( $legacy_signature_exit, 0, 'saved-page benchmark can restore the prior JSON config-signature implementation' );
is( $legacy_signature_stderr, q{}, 'legacy config-signature benchmark emits no stderr' );
like( $legacy_signature_stdout, qr/config_snapshot_signature=legacy-json/,
    'benchmark reports the selected legacy config-signature control' );
my ($legacy_signature_hash) = $legacy_signature_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $legacy_signature_hash, $response_hash,
    'legacy JSON config-signature mode preserves the saved-page route response bytes' );

my ( $portable_stdout, $portable_stderr, $portable_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--no-native-watch' );
    return $? >> 8;
};
is( $portable_exit, 0, 'saved-page route benchmark can force the portable watcher fallback' );
is( $portable_stderr, q{}, 'portable watcher benchmark emits no stderr' );
like( $portable_stdout, qr/native_watch_backend=unavailable/,
    'portable watcher control reports its forced backend state' );
like( $portable_stdout, qr/saved_nav_snapshot_cache_requested=enabled hits=0/,
    'portable watcher control does not claim native snapshot cache hits' );
my ($portable_hash) = $portable_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $portable_hash, $response_hash, 'portable fallback preserves the exact rendered response' );

my ( $prompt_cache_stdout, $prompt_cache_stderr, $prompt_cache_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--nav-fragments', 1, '--indicators', 2 );
    return $? >> 8;
};
is( $prompt_cache_exit, 0, 'saved-page route benchmark can exercise indicator-backed prompt summary reuse' );
is( $prompt_cache_stderr, q{}, 'indicator-backed prompt-summary benchmark emits no stderr' );
like( $prompt_cache_stdout, qr/prompt_summary_cache=enabled freshness_checks=6 hits=6 indicators=2/,
    'unchanged prompt summaries are guarded by the indicator freshness contract' );
my ($prompt_cache_hash) = $prompt_cache_stdout =~ /response_sha256=([0-9a-f]{64})/;

my ( $prompt_uncached_stdout, $prompt_uncached_stderr, $prompt_uncached_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--nav-fragments', 1, '--indicators', 2, '--no-prompt-summary-cache' );
    return $? >> 8;
};
is( $prompt_uncached_exit, 0, 'saved-page route benchmark can disable prompt-summary reuse' );
is( $prompt_uncached_stderr, q{}, 'uncached prompt-summary benchmark emits no stderr' );
like( $prompt_uncached_stdout, qr/prompt_summary_cache=disabled freshness_checks=0 hits=0 indicators=2/,
    'uncached mode rebuilds the prompt summary on every route request' );
my ($prompt_uncached_hash) = $prompt_uncached_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $prompt_uncached_hash, $prompt_cache_hash,
    'prompt-summary caching preserves exact route response bytes' );


my ( $duplicate_stdout, $duplicate_stderr, $duplicate_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--duplicate-page-containment' );
    return $? >> 8;
};
is( $duplicate_exit, 0, 'saved-page route benchmark can model the former duplicate containment check' );
is( $duplicate_stderr, q{}, 'duplicate-check benchmark mode emits no stderr' );
like( $duplicate_stdout, qr/page_containment=duplicate page_containment_checks=42/,
    'root provenance avoids repeated candidate checks while each path remains containment-checked' );
like( $duplicate_stdout,
    qr/response_sha256=\Q$response_hash\E exact_repeat_parity=yes/,
    'removing the redundant containment check preserves exact response bytes' );

my ( $uncached_roots_stdout, $uncached_roots_stderr, $uncached_roots_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--no-page-roots-cache' );
    return $? >> 8;
};
is( $uncached_roots_exit, 0, 'saved-page benchmark can disable request-local root reuse' );
is( $uncached_roots_stderr, q{}, 'uncached root benchmark emits no stderr' );
like( $uncached_roots_stdout, qr/page_root_cache=disabled page_root_lookups=12/,
    'uncached page-root control rediscovers roots for primary page lookups, not provenance-resolved nav fragments' );
like( $uncached_roots_stdout,
    qr/response_sha256=\Q$response_hash\E exact_repeat_parity=yes/,
    'request-local root reuse preserves exact response bytes' );

my ( $scaled_roots_stdout, $scaled_roots_stderr, $scaled_roots_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--nav-fragments', 10 );
    return $? >> 8;
};
is( $scaled_roots_exit, 0, 'saved-page route benchmark accepts a larger shared-nav fixture' );
is( $scaled_roots_stderr, q{}, 'scaled nav benchmark emits no stderr' );
like( $scaled_roots_stdout, qr/nav_fragments=10 .*page_root_cache=enabled page_root_lookups=6/s,
    'ten-fragment requests still discover page roots once per request' );

my ( $scaled_uncached_roots_stdout, $scaled_uncached_roots_stderr, $scaled_uncached_roots_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--nav-fragments', 10, '--no-page-roots-cache' );
    return $? >> 8;
};
is( $scaled_uncached_roots_exit, 0, 'scaled route control accepts disabled root reuse' );
is( $scaled_uncached_roots_stderr, q{}, 'scaled root control emits no stderr' );
like( $scaled_uncached_roots_stdout, qr/nav_fragments=10 .*page_root_cache=disabled page_root_lookups=12/s,
    'ten-fragment nav loads also bypass repeated page-root discovery with known layer provenance' );
my ($scaled_hash) = $scaled_roots_stdout =~ /response_sha256=([0-9a-f]{64})/;
my ($scaled_uncached_hash) = $scaled_uncached_roots_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $scaled_uncached_hash, $scaled_hash, 'scaled root-cache control preserves exact response bytes' );

my ( $skill_nav_stdout, $skill_nav_stderr, $skill_nav_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2 );
    return $? >> 8;
};
is( $skill_nav_exit, 0, 'saved-page benchmark builds an installed-skill nav fixture' );
is( $skill_nav_stderr, q{}, 'skill-nav benchmark emits no stderr' );
like( $skill_nav_stdout, qr/skill_nav_fragments=2 .*exact_repeat_parity=yes/s,
    'benchmark reports skill-nav count and repeated response parity' );
like( $skill_nav_stdout, qr/skill_nav_content_parity=yes/,
    'rendered route includes all navigation content from the temporary installed skills' );
like( $skill_nav_stdout, qr/skill_layer_resolutions=\d+ mode=single/,
    'skill-nav route reports the number of layer resolutions in its optimized mode' );
like( $skill_nav_stdout, qr/skill_literal_nav_cache=enabled\n.*skill_nav_content_reads=2\b/s,
    'default skill-nav route loads each literal skill fragment once and reuses it on warm requests' );

my ( $uncached_skill_nav_stdout, $uncached_skill_nav_stderr, $uncached_skill_nav_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2,
        '--no-skill-literal-nav-cache' );
    return $? >> 8;
};
is( $uncached_skill_nav_exit, 0, 'saved-page benchmark can disable literal skill-nav page reuse' );
is( $uncached_skill_nav_stderr, q{}, 'uncached skill-nav benchmark emits no stderr' );
like( $uncached_skill_nav_stdout, qr/skill_literal_nav_cache=disabled\n.*skill_nav_content_reads=36\b/s,
    'disabled skill-nav cache reloads each fragment for both route render passes during setup, warmup, and measured requests' );
my ($cached_skill_nav_hash) = $skill_nav_stdout =~ /response_sha256=([0-9a-f]{64})/;
my ($uncached_skill_nav_hash) = $uncached_skill_nav_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $uncached_skill_nav_hash, $cached_skill_nav_hash,
    'literal skill-nav cache and uncached control preserve identical route bytes' );

my ( $uncached_inventory_stdout, $uncached_inventory_stderr, $uncached_inventory_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2,
        '--no-skill-nav-inventory-cache' );
    return $? >> 8;
};
is( $uncached_inventory_exit, 0, 'saved-page benchmark can disable the skill-nav inventory cache' );
is( $uncached_inventory_stderr, q{}, 'uncached skill-nav inventory benchmark emits no stderr' );
like( $skill_nav_stdout, qr/skill_nav_inventory_cache=enabled skill_nav_inventory_scans=\d+/,
    'benchmark reports recursive skill-nav directory scans with inventory caching enabled' );
like( $uncached_inventory_stdout, qr/skill_nav_inventory_cache=disabled skill_nav_inventory_scans=\d+/,
    'benchmark reports recursive skill-nav directory scans when inventory caching is disabled' );
my ($cached_inventory_scans) = $skill_nav_stdout =~ /skill_nav_inventory_scans=(\d+)/;
my ($uncached_inventory_scans) = $uncached_inventory_stdout =~ /skill_nav_inventory_scans=(\d+)/;
cmp_ok( $cached_inventory_scans, '<', $uncached_inventory_scans,
    'validated inventory cache reduces recursive directory scans on repeated requests' );
my ($uncached_inventory_hash) = $uncached_inventory_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $uncached_inventory_hash, $cached_skill_nav_hash,
    'inventory cache and recursive-scan control preserve exact route bytes' );

my ( $duplicate_skill_stdout, $duplicate_skill_stderr, $duplicate_skill_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2,
        '--duplicate-skill-layer-resolution' );
    return $? >> 8;
};
is( $duplicate_skill_exit, 0, 'saved-page route benchmark can recreate the former repeated skill-layer lookup' );
is( $duplicate_skill_stderr, q{}, 'duplicate skill-layer benchmark emits no stderr' );
like( $duplicate_skill_stdout, qr/skill_layer_resolutions=\d+ mode=duplicate/,
    'benchmark reports the repeated layer-resolution control' );
my ($single_skill_resolutions) = $skill_nav_stdout =~ /skill_layer_resolutions=(\d+)/;
my ($duplicate_skill_resolutions) = $duplicate_skill_stdout =~ /skill_layer_resolutions=(\d+)/;
cmp_ok( $duplicate_skill_resolutions, '>', $single_skill_resolutions,
    'the duplicate control performs more skill-layer resolutions' );
my ($single_skill_hash) = $skill_nav_stdout =~ /response_sha256=([0-9a-f]{64})/;
my ($duplicate_skill_hash) = $duplicate_skill_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $duplicate_skill_hash, $single_skill_hash, 'reusing resolved skill layers preserves exact route output' );

my ( $duplicate_skill_nav_stdout, $duplicate_skill_nav_stderr, $duplicate_skill_nav_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2,
        '--duplicate-skill-nav-layer-resolution' );
    return $? >> 8;
};
is( $duplicate_skill_nav_exit, 0, 'saved-page benchmark can restore per-fragment skill-layer resolution' );
is( $duplicate_skill_nav_stderr, q{}, 'duplicate skill-nav layer control emits no stderr' );
like( $duplicate_skill_nav_stdout, qr/skill_layer_resolutions=\d+ mode=duplicate/,
    'duplicate skill-nav control reports repeated layer resolution' );
my ($duplicate_nav_skill_resolutions) = $duplicate_skill_nav_stdout =~ /skill_layer_resolutions=(\d+)/;
cmp_ok( $duplicate_nav_skill_resolutions, '>', $single_skill_resolutions,
    'the skill-nav control resolves layers once per fragment in addition to route enumeration' );
my ($duplicate_nav_skill_hash) = $duplicate_skill_nav_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $duplicate_nav_skill_hash, $single_skill_hash,
    'reusing layers for skill-nav enumeration preserves exact route output' );

my ( $legacy_skill_nav_stdout, $legacy_skill_nav_stderr, $legacy_skill_nav_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2,
        '--legacy-skill-nav-enumeration' );
    return $? >> 8;
};
is( $legacy_skill_nav_exit, 0, 'saved-page benchmark can run the former skill-nav enumeration path' );
is( $legacy_skill_nav_stderr, q{}, 'legacy skill-nav enumeration control emits no stderr' );
like( $legacy_skill_nav_stdout, qr/skill_nav_enumeration=legacy/,
    'benchmark identifies the former per-skill enumeration control' );
my ($legacy_layer_resolutions) = $legacy_skill_nav_stdout =~ /skill_layer_resolutions=(\d+)/;
cmp_ok( $legacy_layer_resolutions, '>', $single_skill_resolutions,
    'former skill-nav enumeration performs per-skill layer resolution' );
my ($legacy_skill_nav_hash) = $legacy_skill_nav_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $legacy_skill_nav_hash, $single_skill_hash,
    'former skill-nav enumeration produces byte-identical route output' );

my ( $parsed_skill_nav_stdout, $parsed_skill_nav_stderr, $parsed_skill_nav_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--skill-nav-fragments', 2,
        '--parse-raw-skill-nav' );
    return $? >> 8;
};
is( $parsed_skill_nav_exit, 0, 'saved-page benchmark can restore raw-nav parsing' );
is( $parsed_skill_nav_stderr, q{}, 'raw-nav parser control emits no stderr' );
like( $parsed_skill_nav_stdout, qr/raw_skill_nav_parse=enabled/,
    'benchmark reports the raw-nav parser control state' );
my ($parsed_skill_nav_hash) = $parsed_skill_nav_stdout =~ /response_sha256=([0-9a-f]{64})/;
is( $parsed_skill_nav_hash, $single_skill_hash,
    'skipping structured parsing for raw skill nav preserves exact route output' );


my ( $invalid_skill_nav_stdout, $invalid_skill_nav_stderr, $invalid_skill_nav_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--skill-nav-fragments', -1 );
    return $? >> 8;
};
isnt( $invalid_skill_nav_exit, 0, 'saved-page benchmark rejects negative skill-nav fixture counts' );
like( $invalid_skill_nav_stderr, qr/--skill-nav-fragments must be a non-negative integer/,
    'invalid skill-nav count gives its accepted range' );

my ( $uncached_stdout, $uncached_stderr, $uncached_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--no-nav-cache' );
    return $? >> 8;
};
is( $uncached_exit, 0, 'saved-page route benchmark can bypass the nav inventory cache' );
is( $uncached_stderr, q{}, 'uncached benchmark emits no stderr' );
like( $uncached_stdout, qr/nav_cache=disabled nav_inventory_scans=9/,
    'uncached benchmark reports one directory scan per route request' );
like( $uncached_stdout,
    qr/response_sha256=\Q$response_hash\E exact_repeat_parity=yes/,
    'bypassing nav caching preserves the exact rendered response' );

my ( $uncached_fragment_stdout, $uncached_fragment_stderr, $uncached_fragment_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 2, '--runs', 3, '--no-nav-fragment-cache' );
    return $? >> 8;
};
is( $uncached_fragment_exit, 0, 'saved-page route benchmark can disable literal nav content reuse' );
is( $uncached_fragment_stderr, q{}, 'uncached nav-content benchmark emits no stderr' );
like( $uncached_fragment_stdout, qr/nav_content_cache=disabled\n.*nav_fragment_file_reads=45\n/s,
    'uncached control rereads five literal fragments on every measured and warmup request' );
like( $uncached_fragment_stdout,
    qr/response_sha256=\Q$response_hash\E exact_repeat_parity=yes/,
    'literal nav content-cache control preserves exact response bytes' );

my ( $invalid_stdout, $invalid_stderr, $invalid_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--iterations', 0 );
    return $? >> 8;
};
isnt( $invalid_exit, 0, 'saved-page route benchmark rejects zero iterations' );
like( $invalid_stderr, qr/--iterations must be a positive integer/,
    'invalid iteration count reports the correction' );

my ( $profile_stdout, $profile_stderr, $profile_exit ) = capture {
    local $ENV{P48_LIB} = $repo_lib;
    system( $^X, $script, '--profile' );
    return $? >> 8;
};
isnt( $profile_exit, 0, 'profile mode rejects execution without NYTProf' );
like( $profile_stderr, qr/--profile requires perl -d:NYTProf/,
    'profile error describes how to enable NYTProf' );

done_testing;

__END__

=pod

=head1 NAME

673-problem48-saved-page-route-benchmark.t - test the saved page route benchmark

=head1 PURPOSE

Checks the saved-page performance tool's option handling, default five-fragment
and larger page fixtures, HTTP status, normalized response repeatability, and
profile guard. It also checks validated literal-nav cache reuse and the
no-cache control's file-read counts. A paired route-inventory run verifies that
directory scans decrease while its uncached control returns identical bytes.
Collector indicator fixtures measure prompt-summary freshness reuse against a
no-cache control and verify exact route-response parity.
Parity checks use the default run's response hash because rendered output may
include installation-root-dependent values; a fixed repository-specific hash
would fail when the test runs from an extracted distribution.

=head1 WHY IT EXISTS

Problem 48 requires evidence from more than one dashboard path. This test
ensures that the `/app/welcome` route benchmark remains deterministic enough to
compare v5.88 and current source without treating the live clock as a content
change.

=head1 WHEN TO USE

Run after changing the benchmark's saved page, navigation fixtures, response
normalization, source selection, profile setup, or result format.
The no-cache control deliberately rereads literal nav files on every request;
the default mode must instead load each unchanged fragment once and return
byte-identical output.
The C<--no-skill-nav-inventory-cache> mode is the recursive-scan control; it
must retain the exact response hash while reporting more directory scans.
The C<--no-native-watch> control exercises the portable path on Linux hosts
where the optional FFI watcher is installed. Snapshot-hit reporting distinguishes
requested cache mode from an actually validated cache hit.
The C<--indicators> option seeds collector-managed state for prompt-summary
measurements; C<--no-prompt-summary-cache> disables rendered summary reuse
while leaving collector and filesystem freshness validation intact.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/673-problem48-saved-page-route-benchmark.t

=head1 WHAT USES IT

Problem 48 profiling uses this test to protect the route benchmark interface
and make invalid invocations fail visibly.

=head1 EXAMPLES

  prove -lv t/673-problem48-saved-page-route-benchmark.t
  d2 docker compose exec dev prove -lv t/673-problem48-saved-page-route-benchmark.t
  d2 docker compose exec dev perl script/problem48-saved-page-route-benchmark --nav-fragments 100
  d2 docker compose exec dev perl script/problem48-saved-page-route-benchmark --no-nav-fragment-cache
  d2 docker compose exec dev perl script/problem48-saved-page-route-benchmark --skill-nav-fragments 50 --no-skill-nav-inventory-cache
  d2 docker compose exec dev perl script/problem48-saved-page-route-benchmark --indicators 50
  d2 docker compose exec dev perl script/problem48-saved-page-route-benchmark --indicators 50 --no-prompt-summary-cache

=cut
