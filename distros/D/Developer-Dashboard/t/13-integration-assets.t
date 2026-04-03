use strict;
use warnings;

use Developer::Dashboard::JSON qw(json_decode);
use Test::More;

ok( -f 'doc/integration-test-plan.md', 'integration test plan document exists' );
ok( -f 'integration/blank-env/Dockerfile', 'blank-environment Dockerfile exists' );
ok( -f 'integration/blank-env/docker-compose.yml', 'blank-environment docker compose file exists' );
ok( -f 'integration/blank-env/run-integration.pl', 'blank-environment integration runner exists' );
ok( -f 'integration/blank-env/run-host-integration.sh', 'host-side blank-environment integration launcher exists' );
ok( -f 'integration/browser/run-bookmark-browser-smoke.pl', 'bookmark browser smoke script exists' );

open my $plan_fh, '<', 'doc/integration-test-plan.md' or die $!;
my $plan = do { local $/; <$plan_fh> };
close $plan_fh;
like( $plan, qr/dzil build/, 'integration plan covers host dzil build' );
like( $plan, qr/cpanm/, 'integration plan covers cpanm install' );
unlike( $plan, qr/cpanm --notest/, 'integration plan no longer skips tarball install tests with cpanm --notest' );
like( $plan, qr/dashboard serve/, 'integration plan covers installed web lifecycle' );
like( $plan, qr/helper logout/i, 'integration plan covers helper logout cleanup' );
like( $plan, qr/Chromium|browser/i, 'integration plan covers browser-backed verification' );
like( $plan, qr/\.developer-dashboard/, 'integration plan covers fake-project local runtime overrides' );
like( $plan, qr/host-built tarball/i, 'integration plan requires host-built tarball flow' );
like( $plan, qr/broken collector|broken Perl collector|healthy collector/i, 'integration plan covers collector failure isolation' );
like( $plan, qr/Runtime::Result/, 'integration plan covers Runtime::Result-based hook verification' );
like( $plan, qr/run-host-integration\.sh/, 'integration plan points to the host-side launcher' );
like( $plan, qr/run-bookmark-browser-smoke\.pl/, 'integration plan documents the fast bookmark browser smoke runner' );

open my $testing_fh, '<', 'doc/testing.md' or die $!;
my $testing = do { local $/; <$testing_fh> };
close $testing_fh;
like( $testing, qr/run-bookmark-browser-smoke\.pl/, 'testing doc documents the bookmark browser smoke runner' );
like( $testing, qr/headless\s+Chromium/s, 'testing doc explains that the bookmark smoke runner uses headless Chromium' );

open my $smoke_fh, '<', 'integration/browser/run-bookmark-browser-smoke.pl' or die $!;
my $smoke = do { local $/; <$smoke_fh> };
close $smoke_fh;
like( $smoke, qr/--bookmark-file/, 'bookmark smoke script accepts an explicit bookmark file path' );
like( $smoke, qr/--expect-ajax-path/, 'bookmark smoke script accepts ajax path assertions' );
like( $smoke, qr/__END__/, 'bookmark smoke script carries POD trailer' );

open my $runner_fh, '<', 'integration/blank-env/run-integration.pl' or die $!;
my $runner = do { local $/; <$runner_fh> };
close $runner_fh;
like( $runner, qr/Developer-Dashboard\.tar\.gz/, 'integration runner consumes mounted tarball artifact' );
like( $runner, qr/tar -xzf/, 'integration runner extracts the tarball inside the container' );
like( $runner, qr/dashboard update/, 'integration runner exercises dashboard update' );
like( $runner, qr/Runtime::Result/, 'integration runner exercises Runtime::Result-aware hook chaining' );
like( $runner, qr/dashboard docker compose --project .* --dry-run config/, 'integration runner exercises docker compose dry-run' );
like( $runner, qr/dashboard auth add-user helper_login helper-login-pass-123/, 'integration runner exercises helper login path' );
unlike( $runner, qr/cpanm --notest/, 'integration runner installs the tarball without cpanm --notest' );
like( $runner, qr/broken\.collector/, 'integration runner provisions a broken config collector regression case' );
like( $runner, qr/healthy\.collector/, 'integration runner provisions a healthy config collector regression case' );
like( $runner, qr/dashboard indicator list after restart/, 'integration runner checks indicator isolation after restart' );
like( $runner, qr/_browser_binary|chromium-browser|google-chrome|apt-get install -y --no-install-recommends chromium/s, 'integration runner resolves or bootstraps a headless browser for browser checks' );
like( $runner, qr/IPC::Open3|open3/, 'integration runner uses a live subprocess bridge for long-running command output' );
like( $runner, qr/IO::Select/, 'integration runner monitors long-running command streams without fully buffering them first' );
like( $runner, qr/legacy-ajax-stream|project-stream\.txt/, 'integration runner provisions a long-running saved ajax stream regression case' );
like( $runner, qr/_capture_stream_prefix/, 'integration runner captures early ajax stream chunks during the long-running saved ajax regression case' );
like( $runner, qr/_distribution_version/, 'integration runner reads the expected installed version from the extracted tarball instead of hard-coding a release number' );
like( $runner, qr/\.developer-dashboard/, 'integration runner provisions a fake-project local runtime tree' );
like( $runner, qr/cpanm install host-built tarball.*dashboard init.*api-dashboard/s, 'integration runner builds the fake-project local runtime only after the tarball install step' );
like( $runner, qr/__END__/, 'integration runner carries POD trailer' );

open my $docker_fh, '<', 'integration/blank-env/Dockerfile' or die $!;
my $dockerfile = do { local $/; <$docker_fh> };
close $docker_fh;
like( $dockerfile, qr/\bchromium\b/, 'integration Dockerfile installs Chromium for browser verification' );
unlike( $dockerfile, qr/\bDist::Zilla\b/, 'integration Dockerfile no longer installs Dist::Zilla because host builds the tarball' );

open my $compose_fh, '<', 'integration/blank-env/docker-compose.yml' or die $!;
my $compose = do { local $/; <$compose_fh> };
close $compose_fh;
like( $compose, qr/DASHBOARD_TARBALL/, 'integration compose file mounts the host-built tarball into the container' );
unlike( $compose, qr/\.\.\/\.\.:\/workspace/, 'integration compose file does not mount the repo source into the container' );

open my $host_fh, '<', 'integration/blank-env/run-host-integration.sh' or die $!;
my $host = do { local $/; <$host_fh> };
close $host_fh;
like( $host, qr/\.perl5/, 'host launcher bootstraps a local perl toolchain when needed' );
like( $host, qr/rm -rf Developer-Dashboard-\* Developer-Dashboard-\*\.tar\.gz/, 'host launcher removes old release build directories and tarballs before building a new one' );
like( $host, qr/LOCAL_DZIL.*build/s, 'host launcher builds the tarball on the host with Dist::Zilla' );
like( $host, qr/DASHBOARD_TARBALL/, 'host launcher exports the tarball path for docker compose' );
like( $host, qr/run --rm blank-env/, 'host launcher runs the blank-environment integration service' );
unlike( $host, qr/run --build --rm blank-env/, 'host launcher does not rebuild the integration image when using the prebuilt container path' );
like( $host, qr/dd-int-test:latest/, 'host launcher POD documents the prebuilt dd-int-test image path' );

if ( -f 'dist.ini' ) {
    open my $dist_fh, '<', 'dist.ini' or die $!;
    my $dist = do { local $/; <$dist_fh> };
    close $dist_fh;
    like( $dist, qr/exclude_filename = Makefile\.PL/, 'dist.ini excludes checked-in Makefile.PL from dzil gather phase' );
    like( $dist, qr/\[AutoPrereqs\]/, 'dist.ini includes AutoPrereqs for built distribution dependencies' );
    like( $dist, qr/^JSON::XS = 0$/m, 'dist.ini pins JSON::XS explicitly for built distribution runtime metadata' );
}
else {
    ok( !-f 'dist.ini', 'release tarball excludes dist.ini from shipped assets' );
    open my $meta_fh, '<', 'META.json' or die $!;
    my $meta = json_decode( do { local $/; <$meta_fh> } );
    close $meta_fh;
    ok( exists $meta->{prereqs}, 'META.json ships generated prerequisite metadata in the tarball' );
    ok( exists $meta->{prereqs}{runtime}, 'META.json keeps runtime prerequisite sections in the tarball' );
    ok( exists $meta->{prereqs}{runtime}{requires}{'JSON::XS'}, 'META.json keeps JSON::XS in shipped runtime prerequisites' );
}

done_testing;

__END__

=head1 NAME

13-integration-assets.t - verify blank-environment integration assets exist

=head1 DESCRIPTION

This test verifies that the blank-environment Docker integration plan and
runner assets are present and cover the intended install and smoke flow.

=cut
