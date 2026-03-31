use strict;
use warnings;

use Developer::Dashboard::JSON qw(json_decode);
use Test::More;

ok( -f 'doc/integration-test-plan.md', 'integration test plan document exists' );
ok( -f 'integration/blank-env/Dockerfile', 'blank-environment Dockerfile exists' );
ok( -f 'integration/blank-env/docker-compose.yml', 'blank-environment docker compose file exists' );
ok( -f 'integration/blank-env/run-integration.pl', 'blank-environment integration runner exists' );
ok( -f 'integration/blank-env/run-host-integration.sh', 'host-side blank-environment integration launcher exists' );

open my $plan_fh, '<', 'doc/integration-test-plan.md' or die $!;
my $plan = do { local $/; <$plan_fh> };
close $plan_fh;
like( $plan, qr/dzil build/, 'integration plan covers host dzil build' );
like( $plan, qr/cpanm/, 'integration plan covers cpanm install' );
like( $plan, qr/dashboard serve/, 'integration plan covers installed web lifecycle' );
like( $plan, qr/helper logout/i, 'integration plan covers helper logout cleanup' );
like( $plan, qr/Chromium|browser/i, 'integration plan covers browser-backed verification' );
like( $plan, qr/DEVELOPER_DASHBOARD_BOOKMARKS/, 'integration plan covers fake-project env overrides' );
like( $plan, qr/host-built tarball/i, 'integration plan requires host-built tarball flow' );
like( $plan, qr/run-host-integration\.sh/, 'integration plan points to the host-side launcher' );

open my $runner_fh, '<', 'integration/blank-env/run-integration.pl' or die $!;
my $runner = do { local $/; <$runner_fh> };
close $runner_fh;
like( $runner, qr/Developer-Dashboard\.tar\.gz/, 'integration runner consumes mounted tarball artifact' );
like( $runner, qr/tar -xzf/, 'integration runner extracts the tarball inside the container' );
like( $runner, qr/dashboard update/, 'integration runner exercises dashboard update' );
like( $runner, qr/dashboard docker compose --project .* --dry-run config/, 'integration runner exercises docker compose dry-run' );
like( $runner, qr/dashboard auth add-user helper_login helper-login-pass-123/, 'integration runner exercises helper login path' );
like( $runner, qr/chromium.*--headless/s, 'integration runner uses headless Chromium for browser checks' );
like( $runner, qr/DEVELOPER_DASHBOARD_BOOKMARKS/, 'integration runner exports fake-project env overrides' );
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
like( $host, qr/run --build --rm blank-env/, 'host launcher rebuilds the blank image before running integration' );

if ( -f 'dist.ini' ) {
    open my $dist_fh, '<', 'dist.ini' or die $!;
    my $dist = do { local $/; <$dist_fh> };
    close $dist_fh;
    like( $dist, qr/exclude_filename = Makefile\.PL/, 'dist.ini excludes checked-in Makefile.PL from dzil gather phase' );
    like( $dist, qr/\[AutoPrereqs\]/, 'dist.ini includes AutoPrereqs for built distribution dependencies' );
}
else {
    ok( !-f 'dist.ini', 'release tarball excludes dist.ini from shipped assets' );
    open my $meta_fh, '<', 'META.json' or die $!;
    my $meta = json_decode( do { local $/; <$meta_fh> } );
    close $meta_fh;
    ok( exists $meta->{prereqs}, 'META.json ships generated prerequisite metadata in the tarball' );
    ok( exists $meta->{prereqs}{runtime}, 'META.json keeps runtime prerequisite sections in the tarball' );
}

done_testing;

__END__

=head1 NAME

13-integration-assets.t - verify blank-environment integration assets exist

=head1 DESCRIPTION

This test verifies that the blank-environment Docker integration plan and
runner assets are present and cover the intended install and smoke flow.

=cut
