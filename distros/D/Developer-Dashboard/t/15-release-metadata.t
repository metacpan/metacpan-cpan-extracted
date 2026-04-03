use strict;
use warnings;

use Developer::Dashboard::JSON qw(json_decode);
use Test::More;

open my $pm_fh, '<', 'lib/Developer/Dashboard.pm' or die $!;
my $pm = do { local $/; <$pm_fh> };
close $pm_fh;

open my $changes_fh, '<', 'Changes' or die $!;
my $changes = do { local $/; <$changes_fh> };
close $changes_fh;

open my $makefile_fh, '<', 'Makefile.PL' or die $!;
my $makefile = do { local $/; <$makefile_fh> };
close $makefile_fh;

open my $readme_fh, '<', 'README.md' or die $!;
my $readme = do { local $/; <$readme_fh> };
close $readme_fh;

open my $release_doc_fh, '<', 'doc/update-and-release.md' or die $!;
my $release_doc = do { local $/; <$release_doc_fh> };
close $release_doc_fh;

open my $security_fh, '<', 'SECURITY.md' or die $!;
my $security_doc = do { local $/; <$security_fh> };
close $security_fh;

open my $contributing_fh, '<', 'CONTRIBUTING.md' or die $!;
my $contributing_doc = do { local $/; <$contributing_fh> };
close $contributing_fh;

my $workflow = '';
if ( -f '.github/workflows/release-cpan.yml' ) {
    open my $workflow_fh, '<', '.github/workflows/release-cpan.yml' or die $!;
    $workflow = do { local $/; <$workflow_fh> };
    close $workflow_fh;
}

my $meta = {};
if ( -f 'META.json' ) {
    open my $meta_fh, '<', 'META.json' or die $!;
    $meta = json_decode( do { local $/; <$meta_fh> } );
    close $meta_fh;
}

my $dist = '';
if ( -f 'dist.ini' ) {
    open my $dist_fh, '<', 'dist.ini' or die $!;
    $dist = do { local $/; <$dist_fh> };
    close $dist_fh;
}

like( $pm, qr/our \$VERSION = '([^']+)'/, 'module declares a version' );
my ($version) = $pm =~ /our \$VERSION = '([^']+)'/;
is( $version, '1.33', 'module version bumped for the root-route editor patch release' );
like( $readme, qr/dashboard serve --ssl/, 'README documents the HTTPS serve flag' );
like( $pm, qr/C<dashboard serve --ssl>/, 'main POD documents the HTTPS serve flag' );
like( $release_doc, qr/dashboard serve --ssl/, 'release doc documents the HTTPS serve flag' );
like( $readme, qr/https:\/\/127\.0\.0\.1:7890\//, 'README documents the local HTTPS URL' );
like( $pm, qr/https:\/\/127\.0\.0\.1:7890\//, 'main POD documents the local HTTPS URL' );
like( $readme, qr/opening `\/` now redirects straight to\s+`\/app\/index`/s, 'README documents root redirect to the saved index bookmark' );
like( $pm, qr/opening C<\/> now redirects straight to\s+C<\/app\/index>/s, 'main POD documents root redirect to the saved index bookmark' );
like( $release_doc, qr/root path now redirects to `\/app\/index` when a saved `index` bookmark exists/s, 'release doc documents root redirect to the saved index bookmark' );
like( $readme, qr/unknown saved route such as `\/app\/foobar`.*prefilled blank bookmark/s, 'README documents unknown saved routes opening a prefilled bookmark editor' );
like( $pm, qr/unknown saved route such as C<\/app\/foobar>.*prefilled blank bookmark/s, 'main POD documents unknown saved routes opening a prefilled bookmark editor' );
like( $release_doc, qr/Unknown saved routes such as `\/app\/foobar` must now open the bookmark editor with a prefilled blank bookmark/s, 'release doc documents unknown saved routes opening a prefilled bookmark editor' );
like( $readme, qr/After a successful\s+helper login, the browser is sent back to that saved route, such as\s+`\/app\/index`/s, 'README documents post-login return to the original saved route' );
like( $pm, qr/After a\s+successful helper login, the browser is sent back to that saved route, such as\s+C<\/app\/index>/s, 'main POD documents post-login return to the original saved route' );
like( $release_doc, qr/successful\s+helper login returns the browser to the original route, such as `\/app\/index`/s, 'release doc documents post-login return to the original route' );
like( $readme, qr/Shared nav markup now wraps horizontally by default/, 'README documents the horizontal shared-nav layout' );
like( $pm, qr/Shared nav markup now wraps horizontally by default/, 'main POD documents the horizontal shared-nav layout' );
like( $release_doc, qr/Shared `nav\/\*\.tt` fragments now wrap horizontally/, 'release doc documents the shared-nav theme-aware layout' );
like( $readme, qr/perl -MFolder -e 'print Folder->docker'/, 'README documents plain Folder config-backed alias resolution' );
like( $pm, qr/perl -MFolder -e 'print Folder-E<gt>docker'/, 'main POD documents plain Folder config-backed alias resolution' );
like( $readme, qr/dashboard serve logs/, 'README documents the serve logs command' );
like( $pm, qr/C<dashboard serve logs>/, 'main POD documents the serve logs command' );
like( $readme, qr/dashboard serve logs -n 100/, 'README documents tailed serve logs usage' );
like( $pm, qr/C<dashboard serve logs -n 100>/, 'main POD documents tailed serve logs usage' );
like( $readme, qr/dashboard serve logs -f/, 'README documents followed serve logs usage' );
like( $pm, qr/C<dashboard serve logs -f>/, 'main POD documents followed serve logs usage' );
like( $readme, qr/dashboard serve workers N/, 'README documents the persistent serve workers command' );
like( $pm, qr/C<dashboard serve workers N>/, 'main POD documents the persistent serve workers command' );
like( $readme, qr/dashboard serve workers N.*--port PORT/s, 'README documents the serve workers auto-start port override' );
like( $pm, qr/C<dashboard serve workers N>.*C<--port PORT>/s, 'main POD documents the serve workers auto-start port override' );
like( $readme, qr/integration\/browser\/run-bookmark-browser-smoke\.pl/, 'README documents the bookmark browser smoke script' );
like( $pm, qr/integration\/browser\/run-bookmark-browser-smoke\.pl/, 'main POD documents the bookmark browser smoke script' );
like( $readme, qr/Ajax` helper calls inside saved bookmark `CODE\*` blocks should use an\s+explicit `file => 'name\.json'` argument/s, 'README documents the saved bookmark Ajax file requirement' );
like( $pm, qr/Legacy C<Ajax> helper calls inside saved bookmark C<CODE\*> blocks should use\s+an explicit C<file =E<gt> 'name\.json'> argument/s, 'main POD documents the saved bookmark Ajax file requirement' );
like( $readme, qr/stores the Ajax Perl code under the saved dashboard ajax tree/s, 'README documents the saved bookmark Ajax storage location' );
like( $pm, qr/stores the Ajax Perl code under the saved dashboard ajax tree/s, 'main POD documents the saved bookmark Ajax storage location' );
like( $readme, qr/defaulting to\s+Perl unless the file starts with a shebang/s, 'README documents saved bookmark ajax interpreter fallback' );
like( $pm, qr/defaulting to Perl unless the file\s+starts with a shebang/s, 'main POD documents saved bookmark ajax interpreter fallback' );
like( $readme, qr/stream both `stdout` and\s+`stderr` back to the browser as they happen/s, 'README documents live stdout and stderr ajax streaming' );
like( $pm, qr/stream both C<stdout> and C<stderr> back to the\s+browser as they happen/s, 'main POD documents live stdout and stderr ajax streaming' );
like( $readme, qr/singleton => 'NAME'.+dashboard ajax: NAME/s, 'README documents singleton-managed saved Ajax process replacement' );
like( $pm, qr/singleton =E<gt> 'NAME'.+dashboard ajax: NAME/s, 'main POD documents singleton-managed saved Ajax process replacement' );
like( $readme, qr/pagehide` cleanup beacon against\s+`\/ajax\/singleton\/stop\?singleton=NAME`/s, 'README documents browser pagehide singleton cleanup' );
like( $pm, qr/C<pagehide> cleanup beacon against\s+C<\/ajax\/singleton\/stop\?singleton=NAME>/s, 'main POD documents browser pagehide singleton cleanup' );
like( $readme, qr/clipped overlay viewport.*transform instead of via a second scrollbox/s, 'README documents the stable editor overlay geometry' );
like( $pm, qr/clipped overlay viewport.*transform instead of via a second scrollbox/s, 'main POD documents the stable editor overlay geometry' );
like( $changes, qr/^\Q$version\E\s+\d{4}-\d{2}-\d{2}$/m, 'Changes top entry matches module version' );

if ( %{$meta} ) {
    is( $meta->{version}, $version, 'META.json version matches module version' );
    ok( exists $meta->{prereqs}{runtime}, 'META.json includes shipped runtime prerequisite metadata' );
    ok( exists $meta->{prereqs}{runtime}{requires}{'JSON::XS'}, 'META.json runtime prerequisites include JSON::XS explicitly' );
    ok( exists $meta->{provides} && keys %{ $meta->{provides} || {} }, 'META.json includes explicit provides metadata' );
    is( $meta->{resources}{repository}{web}, 'https://github.mf/manif3station/developer-dashboard', 'META.json includes repository web metadata' );
}
elsif ( $dist ne '' ) {
    like( $dist, qr/^version = \Q$version\E$/m, 'dist.ini version matches module version when META.json is absent' );
    like( $dist, qr/^JSON::XS = 0$/m, 'dist.ini declares JSON::XS as an explicit runtime prerequisite' );
    like( $dist, qr/^\[MetaProvides::Package\]$/m, 'dist.ini enables explicit provides metadata generation' );
    like( $dist, qr/^\[MetaResources\]$/m, 'dist.ini enables explicit repository metadata generation' );
    like( $dist, qr/^repository\.web = https:\/\/github\.mf\/manif3station\/developer-dashboard$/m, 'dist.ini declares repository web metadata' );
}
else {
    fail('either META.json or dist.ini must be available for release metadata checks');
}

for my $script (qw(bin/dashboard bin/of bin/open-file bin/pjq bin/pyq bin/ptomq bin/pjp)) {
    like( $makefile, qr/["']\Q$script\E["']/, "Makefile.PL ships $script" );
}

like( $readme, qr/cpanm \/tmp\/Developer-Dashboard-\Q$version\E\.tar\.gz -v/, 'README documents tarball install verification' );
like( $readme, qr/rm -rf Developer-Dashboard-\* Developer-Dashboard-\*\.tar\.gz/, 'README documents old build directory and tarball cleanup before building a release' );
like( $readme, qr/http:\/\/127\.0\.0\.1:7890\//, 'README documents the default local browser URL' );
like( $readme, qr/DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS/, 'README documents the transient web token opt-in environment variable' );
like( $readme, qr/exact numeric loopback admin access on `127\.0\.0\.1` does not require a password/, 'README documents passwordless exact-loopback admin access' );
like( $readme, qr/helper access is for everyone else/, 'README documents helper-tier browser access' );
like( $readme, qr/### Not Just For Perl/, 'README documents non-Perl suitability explicitly' );
like( $pm, qr/http:\/\/127\.0\.0\.1:7890\//, 'main POD documents the default local browser URL' );
like( $pm, qr/DEVELOPER_DASHBOARD_ALLOW_TRANSIENT_URLS/, 'main POD documents the transient web token opt-in environment variable' );
like( $pm, qr/exact numeric loopback admin access on C<127\.0\.0\.1> does not require a\s+password/, 'main POD documents passwordless exact-loopback admin access' );
like( $pm, qr/helper access is for everyone else/, 'main POD documents helper-tier browser access' );
like( $pm, qr/=head2 Not Just For Perl/, 'main POD documents non-Perl suitability explicitly' );
like( $release_doc, qr/cpanm \/tmp\/Developer-Dashboard-\Q$version\E\.tar\.gz -v/, 'release doc documents tarball install verification' );
like( $release_doc, qr/tar -tzf Developer-Dashboard-\Q$version\E\.tar\.gz/, 'release doc documents tarball content verification' );
like( $release_doc, qr/rm -rf Developer-Dashboard-\* Developer-Dashboard-\*\.tar\.gz/, 'release doc documents old build directory and tarball cleanup before building a release' );
like( $security_doc, qr/security\@manif3station\.local/, 'SECURITY.md includes a private contact address' );
like( $contributing_doc, qr/prove -lr t/, 'CONTRIBUTING.md documents the test workflow' );
if ( $workflow ne '' ) {
    like( $workflow, qr/cpanm --notest App::Cmd/, 'release workflow bootstraps App::Cmd before Dist::Zilla' );
    like( $workflow, qr/Module::Pluggable::Object/, 'release workflow preinstalls the App::Cmd dependency chain explicitly' );
    like( $workflow, qr/Dist::Zilla::Plugin::MetaProvides::Package/, 'release workflow installs the provides metadata plugin explicitly' );
    like( $workflow, qr/actions\/checkout\@v5/, 'release workflow pins actions/checkout to the Node 24-ready major version' );
    like( $workflow, qr/FORCE_JAVASCRIPT_ACTIONS_TO_NODE24:\s*true/, 'release workflow opts JavaScript actions into Node 24' );
}
else {
    pass('release workflow checks are skipped in built tarballs without .github metadata');
    pass('dependency-chain workflow checks are skipped in built tarballs without .github metadata');
    pass('provides-plugin workflow checks are skipped in built tarballs without .github metadata');
    pass('checkout-version workflow checks are skipped in built tarballs without .github metadata');
    pass('node24 workflow checks are skipped in built tarballs without .github metadata');
}

done_testing;

__END__

=head1 NAME

15-release-metadata.t - verify release metadata and tarball validation guidance

=head1 DESCRIPTION

This test keeps the shipped version metadata, executable list, and release
verification instructions aligned so the published tarball matches the source
tree that passed the test suite.

=cut
