use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

my $node_bin = _find_command('node');
my $npm_bin  = _find_command('npm');

plan skip_all => 'JS fast-check fuzz test requires node and npm on PATH'
  if !$node_bin || !$npm_bin;

my $package_json = File::Spec->catfile( $ROOT, 'package.json' );
my $package_lock = File::Spec->catfile( $ROOT, 'package-lock.json' );

plan skip_all => 'JS fast-check fuzz test requires source-tree package.json and package-lock.json'
  if !-f $package_json || !-f $package_lock;

my $node_modules = File::Spec->catdir( $ROOT, 'node_modules' );
if ( !-d $node_modules ) {
    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = %ENV;
        $ENV{npm_config_audit} = 'false';
        $ENV{npm_config_fund}  = 'false';
        system( $npm_bin, 'ci', '--ignore-scripts' );
    };
    is( $exit, 0, 'npm ci prepares the fast-check dependency tree' )
      or diag($stdout), diag($stderr);
}

my ( $stdout, $stderr, $exit ) = capture {
    system( $npm_bin, 'run', 'fuzz:scorecard' );
};

is( $exit,   0,  'fast-check property tests pass' );
is( $stderr, '', 'fast-check property tests do not emit stderr' );
like( $stdout, qr/^>/m, 'npm run produced the expected script runner banner' );

done_testing;

sub _find_command {
    my ($name) = @_;
    for my $dir ( split /:/, ( $ENV{PATH} || '' ) ) {
        my $candidate = File::Spec->catfile( $dir, $name );
        return $candidate if -x $candidate;
    }
    return;
}

__END__

=pod

=head1 NAME

t/35-js-fast-check.t - run the Scorecard-targeted fast-check property suite

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the repository-side
Scorecard and workflow guardrails, specifically the JavaScript C<fast-check>
property suite that exercises the dashboard encode and decode path.

=head1 WHY IT EXISTS

It exists because the repository's fuzzing signal is only credible when the
property suite runs under the same test discipline as the Perl code. Keeping
the wrapper here makes npm dependency preparation, stdout and stderr checks, and
the workflow contract visible in one place instead of leaving them implicit in
GitHub Actions only.

=head1 WHEN TO USE

Use this file when changing the Scorecard fuzz workflow, the npm property
harness, or the dashboard encode and decode path covered by C<fast-check>.

=head1 HOW TO USE

Run it directly with C<prove -lv t/35-js-fast-check.t> while iterating, then
keep it green under C<prove -lr t> and the covered test path before release.
This wrapper can bootstrap C<node_modules> with C<npm ci> when needed. It skips
when C<node> or C<npm> are missing, and it also skips from packaged install
trees that do not ship the checkout-only C<package.json> and
C<package-lock.json> manifests needed by the JavaScript fuzz harness.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the GitHub Actions
fuzz workflow all rely on this file to keep the repo-side fuzzing signal
honest.

=head1 EXAMPLES

Example 1:

  prove -lv t/35-js-fast-check.t

Run the Perl wrapper that prepares and invokes the JavaScript property suite.

Example 2:

  npm run fuzz:scorecard

Run the underlying JavaScript property suite directly when you are debugging
the npm side rather than the Perl wrapper.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/35-js-fast-check.t

Confirm the wrapper still behaves correctly under the covered Perl test path.

Example 4:

  prove -lr t

Rejoin the full repository suite after changing the fuzz-property path or its
workflow contract.

=for comment FULL-POD-DOC END

=cut
