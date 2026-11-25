use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

plan skip_all => 'Docker image build files are checkout-only; installed tarballs omit them'
  if !-e File::Spec->catfile( $ROOT, '.git' );

sub _slurp {
    my ($path) = @_;
    return q{} if !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $path after reading: $!";
    return defined $content ? $content : q{};
}

my $dockerfile_path = File::Spec->catfile( $ROOT, '.github', 'docker', 'Dockerfile' );
my $dockerfile = _slurp($dockerfile_path);
my $dist = _slurp( File::Spec->catfile( $ROOT, 'dist.ini' ) );
my $dockerignore = _slurp( File::Spec->catfile( $ROOT, '.dockerignore' ) );
my $makefile_text = _slurp( File::Spec->catfile( $ROOT, 'Makefile.PL' ) );

ok( -f $dockerfile_path, 'the multi-platform runtime Dockerfile exists under .github/docker' );
like( $dockerfile, qr/^FROM\s+ubuntu:\S+\@sha256:[0-9a-f]{64}\s*$/m, 'the multi-platform Linux base image is pinned by manifest digest' );
like( $dockerfile, qr/^ARG\s+DIST_VERSION\s*$/m, 'the Dockerfile uses a namespaced distribution-version build argument' );
unlike( $dockerfile, qr/^ARG\s+VERSION\s*$/m, 'the Dockerfile does not inject a generic VERSION variable into packaged test runs' );
like( $dockerfile, qr/^COPY\s+\.\s+\/workspace\s*$/m, 'the checked-out master source is available to the build steps' );
like( $dockerfile, qr/RUN[^\n]*\.\/install\.sh|RUN\s+\.\/install\.sh/s, 'install.sh bootstraps system tools, Perl, and cpanm' );
like( $dockerfile, qr/DD_INSTALL_CPAN_TARGET=Developer::Dashboard\s+\.\/install\.sh/, 'bootstrap avoids trying to configure the unbuilt source checkout as a CPAN distribution' );
like( $dockerfile, qr/Dist::Zilla::Plugin::ManifestSkip/, 'the build installs the repository Dist::Zilla plugin set' );
like( $dockerfile, qr/dzil\s+build/, 'the checked-out current source is built into a tarball' );
like( $dockerfile, qr/archive\s*=\s*"Developer-Dashboard-\$\{DIST_VERSION\}\.tar\.gz"/, 'the image names the archive from the checked-out distribution version' );
like( $dockerfile, qr/cpanm\s+(?:--verbose\s+)?--notest\s+--reinstall\s+--local-lib=\/root\/perl5\s+"\$\{archive\}"/, 'the image installs the newly built tarball without repeating the full test suite already covered by repository gates' );
like( $dockerfile, qr/ENTRYPOINT\s+\[\s*"d2"\s*\]/, 'the published image starts the installed d2 command' );
like( $dockerfile, qr/arm64.*Apple Silicon|Apple Silicon.*arm64/is, 'the Dockerfile documents arm64 use on Apple Silicon without claiming a macOS container platform' );
like( $dist, qr/^version\s*=\s*\d+\.\d{2}\s*$/m, 'the source distribution has the X.XX version that supplies the image tag' );
like( $dockerignore, qr/^!Developer-Dashboard-\*\.tar\.gz\s*$/m, 'the shared Docker context re-includes release archives after build-artifact exclusions for d2 docker.images.build' );
like( $dockerignore, qr/^\.env(?:\.\*)?\s*$/m, 'local environment files stay out of Docker build contexts' );
like( $makefile_text, qr/-fobjc-arc/,
    'the macOS System Menu helper compiles with ARC for weak Objective-C references' );

done_testing();

__END__

=head1 NAME

t/228-docker-image-build-files.t - protect the files the Docker image is built from

=head1 PURPOSE

Verify the multi-platform runtime Dockerfile, the shared Docker ignore file, the
distribution version shape that supplies the image tag, and the macOS menu
helper compile flag in the MakeMaker file.

=head1 WHY IT EXISTS

These checks used to live in test files that skipped whole once the GitHub
workflows were removed, so the build files went untested. Those files were
deleted on 2026-11-23. The checks on files that still exist are kept here, word
for word, with no workflow gate, so they run on every platform.

=head1 WHEN TO USE

Run this test whenever changing the runtime Dockerfile, the Docker ignore file,
the distribution version, or the native helper build flags.

=head1 HOW TO USE

    prove -lv t/228-docker-image-build-files.t

=head1 WHAT USES IT

The full repository test suite runs this test on every platform from a source
checkout. Released archives leave the Docker build files out, so the test skips
only when it runs from an installed archive.

=head1 EXAMPLES

The Dockerfile must pin its Ubuntu base image by manifest digest, build the
checked-out source into an archive with C<dzil build>, and start the installed
C<d2> command.

=cut
