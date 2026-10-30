use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

plan skip_all => 'GitHub workflow sources are excluded from source distributions'
  if !-d File::Spec->catdir( $ROOT, '.github' );

# _slurp($path)
# Purpose: read one repository-owned file for its release automation contract.
# Input: filesystem path to a workflow, Dockerfile, or source manifest.
# Output: complete file content; an absent file is represented by the empty string.
sub _slurp {
    my ($path) = @_;
    return q{} if !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $path after reading: $!";
    return defined $content ? $content : q{};
}

my $workflow_path = File::Spec->catfile( $ROOT, '.github', 'workflows', 'dockerhub-image.yml' );
my $dockerfile_path = File::Spec->catfile( $ROOT, '.github', 'docker', 'Dockerfile' );
my $workflow = _slurp($workflow_path);
my $dockerfile = _slurp($dockerfile_path);

ok( -f $workflow_path, 'the Docker Hub publishing workflow exists in .github/workflows' );
ok( -f $dockerfile_path, 'the multi-platform runtime Dockerfile exists under .github/docker' );

like( $workflow, qr/^name:\s*Publish Docker Hub Image\s*$/m, 'workflow has a clear Docker Hub publishing name' );
like( $workflow, qr/^\s+branches:\s*\n\s+-\s*master\s*$/m, 'automatic publishing is scoped to master pushes' );
like( $workflow, qr/^\s+workflow_dispatch:\s*$/m, 'the image can also be published by an explicit manual dispatch' );
like( $workflow, qr/^\s{4}environment:\s*\n\s{6}name:\s*release\s*$/m, 'the publishing job reads the configured secrets from the release GitHub Environment' );
like( $workflow, qr/DOCKER_HUB_USER/, 'Docker Hub username comes from the configured GitHub environment' );
like( $workflow, qr/DOCKER_HUB_TOKEN/, 'Docker Hub token comes from the configured GitHub environment' );
like( $workflow, qr/registry:\s*docker\.io/, 'the workflow logs in to Docker Hub rather than GHCR' );
like( $workflow, qr/platforms:\s*linux\/amd64\s*,\s*linux\/arm64/, 'the published manifest supports Linux amd64 and arm64 clients' );
like( $workflow, qr/\$\{\{\s*steps\.version\.outputs\.version\s*\}\}/, 'one Docker tag uses the source distribution version' );
like( $workflow, qr/:latest\b/, 'a second Docker tag identifies the newest master build' );
like( $workflow, qr/\.github\/docker\/Dockerfile/, 'the build action uses the repository Dockerfile' );
like( $workflow, qr/docker\/build-push-action\@[0-9a-f]{40}/, 'the multi-platform image is built and pushed with a pinned action' );
like( $workflow, qr/^\s+DIST_VERSION=\$\{\{\s*steps\.version\.outputs\.version\s*\}\}\s*$/m, 'the distribution version uses a non-generic build argument that cannot override skill VERSION values' );

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
unlike( $workflow, qr/platforms:[^\n]*darwin|platforms:\s*[^\n]*macos/i, 'the workflow does not request an unsupported macOS container platform' );

my $dist = _slurp( File::Spec->catfile( $ROOT, 'dist.ini' ) );
my $dockerignore = _slurp( File::Spec->catfile( $ROOT, '.dockerignore' ) );
like( $workflow, qr/awk[^\n]*version|sed[^\n]*version/i, 'workflow derives the image version from dist.ini at build time' );
like( $dist, qr/^version\s*=\s*\d+\.\d{2}\s*$/m, 'the source distribution has the X.XX version that supplies the image tag' );
like( $dockerignore, qr/^!Developer-Dashboard-\*\.tar\.gz\s*$/m, 'the shared Docker context re-includes release archives after build-artifact exclusions for d2 docker.images.build' );
like( $dockerignore, qr/^\.env(?:\.\*)?\s*$/m, 'local environment files stay out of Docker build contexts' );

done_testing();

__END__

=head1 NAME

t/228-dockerhub-image-workflow.t - enforce the Docker Hub image build and publish contract

=head1 PURPOSE

This repository-only test locks down the Docker Hub publication path for the
latest checked-out master source. It checks that the GitHub workflow uses the configured Docker Hub
credentials, publishes version and latest tags for Linux amd64 and arm64, and
that the Dockerfile runs the repository installer, creates a Dist::Zilla
archive, and installs that archive into the resulting CLI image.

=head1 WHY IT EXISTS

The CPAN release artifact can lag behind the code on master. A workflow that
simply installs the MetaCPAN package would therefore publish an image with old
code while labeling it current. These assertions keep the image build anchored
to the checkout and its freshly generated tarball.

=head1 WHEN TO USE

Run this test whenever changing Docker Hub publication, the multi-platform
Dockerfile, the version/tag contract, or the workflow's credential wiring.

=head1 HOW TO USE

    prove -lv t/228-dockerhub-image-workflow.t
    d2 docker compose exec dev prove -lv t/228-dockerhub-image-workflow.t

=head1 WHAT USES IT

The normal repository test suite runs this test before the Docker Hub workflow
is considered ready to publish a versioned image and the latest tag. Dist::Zilla
excludes GitHub automation files from released archives, so the test skips when
it runs from an installed source archive.

=head1 EXAMPLES

=over 4

=item *

Confirm a master push builds the source tarball rather than selecting only the
published CPAN release.

=item *

Confirm the resulting image manifest has Linux amd64 and arm64 variants and
provides a versioned rollback tag plus C<latest>.

=back

=cut
