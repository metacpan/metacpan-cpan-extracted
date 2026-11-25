use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;
use YAML::XS ();

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $WORKFLOWS = File::Spec->catdir( $ROOT, '.github', 'workflows' );

plan skip_all => 'Scorecard guardrails are source-tree-only checks'
  if !-e File::Spec->catfile( $ROOT, '.git' );

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return $text // '';
}

for my $required (qw(LICENSE SECURITY.md SECURITY_CHECKS.md)) {
    ok( -f File::Spec->catfile( $ROOT, split m{/}, $required ),
        "$required is present in the source tree" );
}

ok( !-e File::Spec->catfile( $ROOT, '.github', 'dependabot.yml' ),
    'Dependabot automation remains disabled by keeping dependabot.yml absent' );

my $license = _slurp( File::Spec->catfile( $ROOT, 'LICENSE' ) );
like( $license, qr/\AMIT License\n\nCopyright \(c\) \d{4} Developer Dashboard Contributors\n/s,
    'LICENSE uses the canonical MIT heading and project copyright' );
like( $license, qr/THE SOFTWARE IS PROVIDED "AS IS"/,
    'LICENSE includes the canonical MIT warranty disclaimer' );

my $security = _slurp( File::Spec->catfile( $ROOT, 'SECURITY.md' ) );
like( $security, qr/Reporting A Vulnerability/i,
    'SECURITY.md documents vulnerability reporting' );
like( $security, qr/security@/i,
    'SECURITY.md includes a private reporting contact' );

for my $retired (qw(
  coverage.yml dockerhub-image.yml platform-compatibility.yml release-github.yml
  test.yml codeql.yml package-ghcr.yml fuzz-js.yml
  unit-tests.yml test-coverage.yml
  five-platform-coverage.yml linux-coverage.yml
  windows-amd64-unit-tests.yml windows-arm64-coverage.yml
)) {
    ok( !-e File::Spec->catfile( $WORKFLOWS, $retired ),
        "$retired stays absent from the active workflow set" );
}

my $property_test = _slurp( File::Spec->catfile( $ROOT, 't', '35-js-fast-check.t' ) );
like( $property_test, qr/'fuzz:scorecard'/,
    'the complete test suite retains the JavaScript property-based tests' );

done_testing();

__END__

=head1 NAME

34-scorecard-guardrails.t - guard the retained release security surface

=head1 DESCRIPTION

Checks security policy and that no GitHub Actions workflow is present: pull
requests are checked by the shared Jenkins job D2/testing-v1 instead.

=head1 PURPOSE

Keep the repository free of GitHub Actions workflows without reintroducing
CodeQL, GHCR, Dependabot automation, a standalone Test workflow, or a
standalone JavaScript fuzz workflow merely to satisfy historical Scorecard
assumptions.

=head1 WHY IT EXISTS

Removing workflows changes which automated Scorecard signals exist, but the
Jenkins job handles quality and identity. The absence of every retired
workflow, including the five-platform coverage orchestrator and its three
reusable platform workflows, must remain explicit.

=head1 WHEN TO USE

Run this test whenever changing F<.github/workflows/>, test or coverage
permissions, coverage gates or the decision to keep Dependabot
automation disabled.

=head1 HOW TO USE

  prove -lv t/34-scorecard-guardrails.t

=head1 WHAT USES IT

The Jenkins PR check and the release process use these assertions to guard
the retained security surface.

=head1 EXAMPLES

Check the workflow-absence contract directly:

  prove -lv t/34-scorecard-guardrails.t

Run it with the full suite:

  prove -lr t

=cut
