use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;
use YAML::XS ();

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

plan skip_all => 'workflow YAML files are excluded from the built distribution'
  if !-d File::Spec->catdir( $ROOT, '.github', 'workflows' );

# _slurp($path)
# Purpose: read a whole text file into one string.
# Input: a filesystem path.
# Output: the file's full content, or dies on open failure.
# Matches t/15-release-metadata.t's own _slurp helper, rather than adding a
# new slurp dependency this project's other tests do not already use.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

# trigger_block($workflow_file)
# Purpose: resolve a GitHub Actions workflow's `on:` trigger block by value,
#   never by assuming a key name - YAML 1.1 reads a bare `on` as the boolean
#   true, and this file is parsed by whichever YAML::XS the host happens to
#   carry (t/34's own documented gotcha).
# Input: a workflow filename under .github/workflows/ (e.g. 'test.yml').
# Output: a hashref of that workflow's trigger block, or {} if none is found.
sub trigger_block {
    my ($workflow_file) = @_;
    my $doc = YAML::XS::LoadFile( File::Spec->catfile( $ROOT, '.github', 'workflows', $workflow_file ) );
    my ($block) = grep { ref $_ eq 'HASH' }
      map { $doc->{$_} } grep { m/\A(?:on|true|1)\z/ } keys %$doc;
    return $block // {};
}

my %triggers = map { $_ => trigger_block($_) }
  qw(test.yml codeql.yml package-ghcr.yml fuzz-js.yml);

for my $file ( sort keys %triggers ) {
    ok( ref $triggers{$file} eq 'HASH' && keys %{ $triggers{$file} },
        "the on: trigger block for $file was located, so the assertions below have a subject" );
}

# AC-1: SKILLS.md's CI description must match the current on: blocks exactly.
# Each workflow's REAL trigger set, read live rather than trusted from memory -
# this is the same fact this ticket's own card was filed to correct, and it had
# already drifted again by the time of the fix (test.yml/fuzz-js.yml gained
# pull_request, package-ghcr.yml gained tags/workflow_dispatch since the card
# was written), which is exactly why this is a standing regression test and not
# a one-off doc edit.
ok( exists $triggers{'test.yml'}{push}, 'test.yml runs on push' );
is_deeply( $triggers{'test.yml'}{push}{branches}, ['master'], 'test.yml pushes are scoped to master' );
ok( exists $triggers{'test.yml'}{pull_request}, 'test.yml also runs on pull_request' );
ok( !exists $triggers{'test.yml'}{schedule}, 'test.yml has no schedule trigger' );
ok( !exists $triggers{'test.yml'}{workflow_dispatch}, 'test.yml has no manual-dispatch trigger' );

ok( exists $triggers{'codeql.yml'}{push}, 'codeql.yml runs on push' );
is_deeply( $triggers{'codeql.yml'}{push}{branches}, ['**'], 'codeql.yml pushes are NOT scoped to master - every branch' );
ok( exists $triggers{'codeql.yml'}{pull_request}, 'codeql.yml also runs on pull_request' );
ok( exists $triggers{'codeql.yml'}{schedule}, 'codeql.yml also runs on a schedule' );

ok( exists $triggers{'package-ghcr.yml'}{push}, 'package-ghcr.yml runs on push' );
is_deeply( $triggers{'package-ghcr.yml'}{push}{branches}, ['master'], 'package-ghcr.yml branch pushes are scoped to master' );
ok( exists $triggers{'package-ghcr.yml'}{push}{tags}, 'package-ghcr.yml ALSO runs on version tags, not only branch pushes' );
ok( exists $triggers{'package-ghcr.yml'}{workflow_dispatch}, 'package-ghcr.yml also runs via manual dispatch' );
ok( !exists $triggers{'package-ghcr.yml'}{pull_request}, 'package-ghcr.yml has no pull_request trigger' );

ok( exists $triggers{'fuzz-js.yml'}{push}, 'fuzz-js.yml runs on push' );
is_deeply( $triggers{'fuzz-js.yml'}{push}{branches}, ['master'], 'fuzz-js.yml pushes are scoped to master' );
ok( exists $triggers{'fuzz-js.yml'}{pull_request}, 'fuzz-js.yml also runs on pull_request' );
ok( exists $triggers{'fuzz-js.yml'}{workflow_dispatch}, 'fuzz-js.yml also runs via manual dispatch' );

# The actual regression guard: SKILLS.md's prose must acknowledge that none of
# the four workflows runs ONLY on push to master. The old wording ("runs Test,
# CodeQL, Package GHCR, and JS Fuzz on every push to master") was wrong for all
# four, not only CodeQL as originally filed.
my $skills_md = _slurp( File::Spec->catfile( $ROOT, 'SKILLS.md' ) );
unlike( $skills_md, qr/runs\s+Test,\s*CodeQL,\s*Package\s*GHCR,\s*and\s*JS\s*Fuzz\s+on\s+every\s*\n?\s*push\s+to\s+`master`/s,
    'SKILLS.md no longer makes the single blanket push-to-master claim for all four workflows' );
like( $skills_md, qr/pull request/i,
    "SKILLS.md's CI description mentions pull requests, which test.yml, codeql.yml and fuzz-js.yml all trigger on" );
like( $skills_md, qr/tag/i,
    "SKILLS.md's CI description mentions tags, which package-ghcr.yml also triggers on" );
like( $skills_md, qr/schedule|weekly/i,
    "SKILLS.md's CI description mentions the schedule, which only codeql.yml has" );
like( $skills_md, qr/every branch/i,
    "SKILLS.md's CI description states that codeql.yml's push trigger is NOT scoped to master" );

# AC-2: no other workflow-trigger claim in SKILLS.md or README.md is left
# inconsistent. Neither file may still assert the disproven "only master" claim.
my $readme = _slurp( File::Spec->catfile( $ROOT, 'README.md' ) );
unlike( $readme, qr/runs\s+Test,\s*CodeQL,\s*Package\s*GHCR,\s*and\s*JS\s*Fuzz\s+on\s+every\s*\n?\s*push\s+to\s+`master`/s,
    'README.md does not repeat the disproven blanket push-to-master claim either' );

# AC-3: platform portability is exercised by real GitHub-hosted macOS and
# Windows runners, not inferred from the Linux-only main test workflow.
{
    my $workflow_path = File::Spec->catfile( $ROOT, '.github', 'workflows', 'platform-compatibility.yml' );
    ok( -f $workflow_path, 'a dedicated cross-platform compatibility workflow exists' );
    if ( -f $workflow_path ) {
        my $workflow = YAML::XS::LoadFile($workflow_path);
        my $jobs = $workflow->{jobs} || {};
        my $job = $jobs->{'perl-tests'};
        ok( ref($job) eq 'HASH', 'the platform compatibility workflow defines a full-suite Perl job' );
        if ( ref($job) eq 'HASH' ) {
            my $matrix = $job->{strategy}{matrix}{include} || [];
            my @runners = sort map { $_->{runner} // '' } @{$matrix};
            is_deeply(
                \@runners,
                [ sort qw(macos-26 macos-26-intel ubuntu-24.04-arm ubuntu-latest windows-latest) ],
                'the full-suite matrix covers Linux, macOS, and Windows on x64, plus Linux and macOS arm64',
            );
            my ($test_step) = grep { ($_->{name} // '') eq 'Run complete test suite' } @{ $job->{steps} };
            like( $test_step->{run} || '', qr/prove\s+-lr\s+t/,
                'the platform job runs the complete Perl test suite' );
            my $benchmark_steps = join "\n", map { $_->{run} // '' } @{ $job->{steps} };
            like( $benchmark_steps,
                qr/problem48-status-route-benchmark.*--indicators\s+50.*--portable-config-cache/s,
                'the platform job measures the portable config snapshot route on every runner' );
            like( $benchmark_steps,
                qr/problem48-status-route-benchmark.*--indicators\s+50.*--iterations/s,
                'the platform job measures the automatic native-or-portable route for comparison' );
        }
        my $windows_arm = $jobs->{'windows-arm64-native-watcher'};
        ok( ref($windows_arm) eq 'HASH', 'Windows ARM64 has a dedicated native-runtime job' );
        if ( ref($windows_arm) eq 'HASH' ) {
            is( $windows_arm->{ 'runs-on' }, 'windows-11-arm',
                'the dedicated job runs on a Windows ARM64 hosted runner' );
            my $steps = join "\n", map { ($_->{run} // '') . "\n" . ($_->{name} // '') } @{ $windows_arm->{steps} || [] };
            like( $steps, qr/Config\{archname\}.*arm64/i,
                'the Windows ARM job verifies it uses a native ARM64 Perl runtime' );
            my ($native_test_step) = grep { ($_->{name} // '') eq 'Run Windows ARM64 native filesystem watcher test' } @{ $windows_arm->{steps} || [] };
            like( $native_test_step->{run} || '', qr/prove\s+-lv\s+t\/669-problem48-inotify-watch\.t/,
                'the Windows ARM job executes the native filesystem watcher regression test' );
        }
    }
}

done_testing();

__END__

=for comment FULL-POD-DOC START

=head1 NAME

t/227-skills-md-ci-triggers.t - verify GitHub Actions triggers and cross-platform runner coverage

=head1 PURPOSE

This test verifies GitHub Actions trigger configuration, the platform matrix, and the cross-platform status-route benchmark steps used alongside the full Perl test suite. It runs in a source checkout and skips in a built distribution, which intentionally excludes workflow files. Read it when CI configuration changes or a workflow-related regression points here.

=head1 WHY IT EXISTS

DD-1001 found that the skills guide's single sentence ("runs Test, CodeQL, Package GHCR, and JS Fuzz on every push to C<master>") was wrong for CodeQL, which also runs on every branch push, every pull request, and a weekly schedule. Re-verifying live while fixing it found the claim had ALSO drifted for the other three workflows in the few days since the card was filed - test.yml and fuzz-js.yml gained C<pull_request>, and package-ghcr.yml gained C<tags> and C<workflow_dispatch>. A one-off prose edit would drift again the same way; this test re-reads the real YAML every run so the next drift fails loudly instead of sitting unnoticed.

The platform-matrix assertions additionally ensure that automatic and
forced-portable status-route timings and the full Perl suite are scheduled on
Linux x64/arm64, macOS Intel/arm64, and Windows x64. A separate Windows ARM64
job checks the native watcher with the runner-provided Perl. This is important
because Linux-only checks cannot establish the behavior of portable fallbacks,
native modules, or comparable latency on other operating systems. Windows
ARM64 is a focused watcher smoke test, not a full-suite leg: the hosted image
currently provides Perl 5.32.1, below this project's Perl 5.38 minimum, and
the Perl setup action does not support that runner target.

=head1 WHEN TO USE

Use this file in a repository checkout whenever a C<.github/workflows/*.yml> trigger block or platform matrix changes, or when a focused CI failure points here. In a packaged installation the workflow directory is absent, so the test reports a documented skip.

=head1 HOW TO USE

Run it directly with C<prove -lv t/227-skills-md-ci-triggers.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. It verifies full-suite jobs on Linux, macOS, and Windows x64, additional Linux/macOS arm64 full-suite jobs, a Windows ARM64 native watcher smoke job, and both config freshness measurements on each full-suite runner.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the release verification loop rely on this file to prevent silent drift in CI trigger and runner coverage.

=head1 EXAMPLES

Example 1:

  prove -lv t/227-skills-md-ci-triggers.t

Run the focused regression test by itself while changing a workflow's C<on:> block or the skills guide's CI prose.

Example 2:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
