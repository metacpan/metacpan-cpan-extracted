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
is( $version, '0.94', 'module version bumped for Folder home-runtime path fix release' );
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
like( $readme, qr/exact numeric loopback admin access on `127\.0\.0\.1` does not require a password/, 'README documents passwordless exact-loopback admin access' );
like( $readme, qr/helper access is for everyone else/, 'README documents helper-tier browser access' );
like( $readme, qr/### Not Just For Perl/, 'README documents non-Perl suitability explicitly' );
like( $pm, qr/http:\/\/127\.0\.0\.1:7890\//, 'main POD documents the default local browser URL' );
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
}
else {
    pass('release workflow checks are skipped in built tarballs without .github metadata');
    pass('dependency-chain workflow checks are skipped in built tarballs without .github metadata');
    pass('provides-plugin workflow checks are skipped in built tarballs without .github metadata');
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
