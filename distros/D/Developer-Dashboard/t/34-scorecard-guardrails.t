use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $repo_workflow = File::Spec->catfile( $ROOT, '.github', 'workflows', 'test.yml' );

plan skip_all => 'Scorecard guardrails are source-tree-only checks'
  if !-d File::Spec->catdir( $ROOT, '.git' ) || !-f $repo_workflow;

ok( _git_tracks('LICENSE'), 'root LICENSE is tracked for Scorecard license detection' );
ok( _git_tracks('LICENSE-Artistic-1.0-Perl'), 'alternate Artistic license text is tracked explicitly for the Perl 5 dual-license contract' );
ok( _git_tracks('SECURITY.md'), 'root SECURITY.md is tracked for Scorecard security-policy detection' );
ok( _git_tracks('.github/dependabot.yml'), 'Dependabot config is tracked for Scorecard dependency-update-tool detection' );
ok( _git_tracks('.github/workflows/codeql.yml'), 'CodeQL workflow is tracked for Scorecard SAST detection' );
ok( _git_tracks('.github/workflows/package-ghcr.yml'), 'GHCR packaging workflow is tracked for Scorecard packaging detection' );
ok( _git_tracks('.github/workflows/fuzz-js.yml'), 'fuzzing workflow is tracked for Scorecard fuzzing detection' );
ok( _git_tracks('.github/workflows/release-github.yml'), 'GitHub release workflow is tracked for Scorecard signed-release detection' );
ok( _git_tracks('.clusterfuzzlite/Dockerfile'), 'ClusterFuzzLite Dockerfile is tracked for Scorecard fuzzing detection' );

my $license = _slurp('LICENSE');
like( $license, qr/\AGNU GENERAL PUBLIC LICENSE/, 'LICENSE uses a canonical GPL text that GitHub can classify' );
unlike( $license, qr/The "Artistic License"/, 'LICENSE keeps the alternate Artistic text out of the root file so GitHub does not classify it as an unknown composite blob' );

my $license_artistic = _slurp('LICENSE-Artistic-1.0-Perl');
like( $license_artistic, qr/\AThe "Artistic License"/, 'alternate Artistic license file ships the canonical Artistic text' );

my $security = _slurp('SECURITY.md');
like( $security, qr/Reporting A Vulnerability/i, 'SECURITY.md documents vulnerability reporting' );
like( $security, qr/security@/i, 'SECURITY.md includes a private reporting contact' );

my $dependabot = _slurp('.github/dependabot.yml');
like( $dependabot, qr/package-ecosystem:\s*["']github-actions["']/, 'Dependabot manages GitHub Actions updates' );
like( $dependabot, qr/package-ecosystem:\s*["']npm["']/, 'Dependabot manages npm-based fuzzing dependencies' );

my $codeql = _slurp('.github/workflows/codeql.yml');
unlike( $codeql, qr/^permissions:\s*$(?:\n^[^\n]*:\s*write\s*$)+/ms, 'CodeQL workflow does not use top-level write permissions' );
like( $codeql, qr/jobs:\n\s+analyze:\n(?:.+\n)*?\s+permissions:\n(?:.+\n)*?\s+security-events:\s*write\b/ms, 'CodeQL workflow grants security-events write only at the job level' );
like( $codeql, qr/uses:\s*github\/codeql-action\/init\@[0-9a-f]{40}/, 'CodeQL init action is pinned by full SHA' );
like( $codeql, qr/uses:\s*github\/codeql-action\/analyze\@[0-9a-f]{40}/, 'CodeQL analyze action is pinned by full SHA' );

my $package_workflow = _slurp('.github/workflows/package-ghcr.yml');
unlike( $package_workflow, qr/^permissions:\s*$(?:\n^[^\n]*:\s*write\s*$)+/ms, 'packaging workflow does not use top-level write permissions' );
like( $package_workflow, qr/jobs:\n\s+package:\n(?:.+\n)*?\s+permissions:\n(?:.+\n)*?\s+packages:\s*write\b/ms, 'packaging workflow grants package publish access only at the job level' );
like( $package_workflow, qr/ghcr\.io/i, 'packaging workflow publishes to GHCR' );
like( $package_workflow, qr/uses:\s*docker\/build-push-action\@[0-9a-f]{40}/, 'docker build-push action is pinned by full SHA' );
like( $package_workflow, qr/uses:\s*docker\/login-action\@[0-9a-f]{40}/, 'docker login action is pinned by full SHA' );

my $github_release_workflow = _slurp('.github/workflows/release-github.yml');
unlike( $github_release_workflow, qr/^permissions:\s*$(?:\n^[^\n]*:\s*write\s*$)+/ms, 'GitHub release workflow does not use top-level write permissions' );
like( $github_release_workflow, qr/jobs:\n\s+release:\n(?:.+\n)*?\s+permissions:\n(?:.+\n)*?\s+contents:\s*write\b/ms, 'GitHub release workflow grants release-publish access only at the job level' );
like( $github_release_workflow, qr/gh\s+release\s+create\b/, 'GitHub release workflow creates GitHub releases' );
like( $github_release_workflow, qr/gh\s+release\s+upload\b/, 'GitHub release workflow updates existing GitHub releases' );
like( $github_release_workflow, qr/\.asc\b/, 'GitHub release workflow publishes a detached signature asset next to the release tarball' );
like( $github_release_workflow, qr/Developer-Dashboard-\*\.tar\.gz/, 'GitHub release workflow locates built distribution tarballs from the repo root' );

my $fuzz_workflow = _slurp('.github/workflows/fuzz-js.yml');
like( $fuzz_workflow, qr/fast-check/, 'fuzz workflow runs the fast-check property-based suite' );
like( $fuzz_workflow, qr/uses:\s*actions\/setup-node\@[0-9a-f]{40}/, 'setup-node action is pinned by full SHA in the fuzz workflow' );
like( $fuzz_workflow, qr/uses:\s*shogo82148\/actions-setup-perl\@[0-9a-f]{40}/, 'fuzz workflow installs Perl before invoking dashboard commands' );
like( $fuzz_workflow, qr/cpanm\s+--installdeps\s+--notest\s+\./, 'fuzz workflow installs the repo Perl runtime prerequisites' );

my $clusterfuzz = _slurp('.clusterfuzzlite/Dockerfile');
like( $clusterfuzz, qr/\AFROM\s+ubuntu:24\.04\@sha256:/, 'ClusterFuzzLite Dockerfile pins its base image by digest' );
like( $clusterfuzz, qr/\bcpanm\b/, 'ClusterFuzzLite Dockerfile provisions the Perl fuzz runner stack' );

my $package_json = _slurp('package.json');
like( $package_json, qr/"fast-check"\s*:/, 'package.json declares fast-check for fuzz/property testing' );

my $package_lock = _slurp('package-lock.json');
like( $package_lock, qr/"fast-check"/, 'package-lock.json locks the fast-check dependency' );

for my $workflow (
    qw(
    .github/workflows/test.yml
    .github/workflows/release-cpan.yml
    .github/workflows/codeql.yml
    .github/workflows/package-ghcr.yml
    .github/workflows/fuzz-js.yml
    .github/workflows/release-github.yml
    )
  )
{
    my $text = _slurp($workflow);
    like( $text, qr/^permissions:\s*$/m, "$workflow declares an explicit permissions block" );
    like( $text, qr/^concurrency:\s*$/m, "$workflow declares an explicit concurrency block" );
    like( $text, qr/^\s*timeout-minutes:\s*\d+\s*$/m, "$workflow sets an explicit timeout to avoid hung jobs" );
    unlike( $text, qr/uses:\s*[^@\s]+\@[Vv]?\d+(?:\.\d+)*(?:\s|$)/, "$workflow does not use floating action tags" );
    unlike( $text, qr/curl\s+-L\s+https:\/\/cpanmin\.us\s*\|\s*perl/, "$workflow does not install cpanm via curl pipe" );
}

my $release_cpan_workflow = _slurp('.github/workflows/release-cpan.yml');
like( $release_cpan_workflow, qr/Developer-Dashboard-\*\.tar\.gz/, 'PAUSE release workflow locates dzil tarballs from the repo root instead of a nonexistent .build tree' );
unlike( $release_cpan_workflow, qr/\.build\/\*\.tar\.gz/, 'PAUSE release workflow no longer looks for tarballs under a nonexistent .build directory' );
like(
    $release_cpan_workflow,
    qr/grep -E '\^Total\[\[:space:\]\]\+100\\\.0\[\[:space:\]\]\+100\\\.0\[\[:space:\]\]\+100\\\.0\$'/,
    'PAUSE release workflow enforces the same 100% lib coverage gate as the main CI workflow without depending on fixed column spacing',
);

for my $coverage_workflow (
    qw(
    .github/workflows/test.yml
    .github/workflows/release-cpan.yml
    .github/workflows/release-github.yml
    )
  )
{
    my $text = _slurp($coverage_workflow);
    like(
        $text,
        qr/grep -E '\^Total\[\[:space:\]\]\+100\\\.0\[\[:space:\]\]\+100\\\.0\[\[:space:\]\]\+100\\\.0\$'/,
        "$coverage_workflow matches the Total coverage line by regex instead of a brittle fixed-width string",
    );
    unlike(
        $text,
        qr/grep -F "Total\s{10,}100\.0\s+100\.0\s+100\.0"/,
        "$coverage_workflow no longer hard-codes one Devel::Cover spacing layout",
    );
}

my $blank_env_dockerfile = _slurp('integration/blank-env/Dockerfile');
like( $blank_env_dockerfile, qr/\AFROM\s+ubuntu:24\.04\@sha256:/, 'blank-env Dockerfile pins its Ubuntu base image by digest' );

done_testing;

sub _git_tracks {
    my ($path) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'git', '-C', $ROOT, 'ls-files', '--error-unmatch', $path );
    };
    return $exit == 0;
}

sub _slurp {
    my ($relative_path) = @_;
    my $path = File::Spec->catfile( $ROOT, split m{/}, $relative_path );
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

__END__

=pod

=head1 NAME

t/34-scorecard-guardrails.t - enforce repository-side Scorecard guardrails

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the repository-side Scorecard and workflow guardrails. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the repository-side Scorecard and workflow guardrails has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the repository-side Scorecard and workflow guardrails, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/34-scorecard-guardrails.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/34-scorecard-guardrails.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/34-scorecard-guardrails.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
