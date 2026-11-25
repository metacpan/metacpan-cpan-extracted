use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempfile);
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
# DD-732. The INSTALL stays conditional - running npm ci when the tree is already
# there is pure waste - but the ASSERTION must not be. Inside the branch it ran only
# on the first invocation in a tree, so this file planned 1..4 once and 1..3 for ever
# after, in the same tree at the same commit. That made the suite total a property of
# the working tree rather than of the commit, and a genuine drop of one test
# indistinguishable from the ordinary difference between a first and a second run.
#
# Assert the POSTCONDITION rather than the action: the tree is present. That is the
# state the rest of this file depends on, it is true in both cases, and it also
# catches an install that exited 0 and produced nothing - which the exit-code
# assertion could not.
if ( !-d $node_modules ) {
    my ( $install_out, $install_err, $install_exit ) = capture {
        local %ENV = %ENV;
        _configure_npm_test_env();
        system( $npm_bin, 'ci', '--ignore-scripts' );
    };
    diag($install_out), diag($install_err) if $install_exit != 0;
}
ok( -d $node_modules, 'the fast-check dependency tree is present' );

my ( $stdout, $stderr, $exit ) = _run_fuzz_with_progress();

is( $exit,   0,  'fast-check property tests pass' );
is( $stderr, '', 'fast-check property tests do not emit stderr' );
like( $stdout, qr/^>/m, 'npm run produced the expected script runner banner' );

done_testing;

# _run_fuzz_with_progress()
# Runs the npm fuzz script and relays its stdout into the test log line by
# line WHILE it runs. The fuzz starts two Perl processes per property run
# (100 at the default count) and needs about a minute of CPU, so on a busy
# machine it can take several minutes. Holding all of its output until the
# end made a slow run look exactly like a stuck one to anything watching the
# log for silence. The script prints one progress line per property run, and
# each line is passed on here as a TAP note as soon as it arrives.
# Input: none.
# Output: list of the script's whole stdout, its whole stderr, and its wait
# status, the same three values the assertions below have always checked.
sub _run_fuzz_with_progress {
    local %ENV = %ENV;
    _configure_npm_test_env();
    $ENV{DD_FAST_CHECK_RUNS}     = _fast_check_run_count();
    $ENV{DD_FAST_CHECK_PROGRESS} = '1';

    # stderr goes to a file so it stays out of the stdout pipe and can still
    # be asserted empty. The child inherits the redirected handle; the test's
    # own STDERR is restored as soon as the child has been started.
    my ( $err_fh, $err_path ) = tempfile( 'dd-fast-check-stderr-XXXXXX', TMPDIR => 1, UNLINK => 1 );
    close $err_fh or die "Unable to close $err_path: $!";
    open my $saved_stderr, '>&', \*STDERR or die "Unable to save STDERR: $!";
    open STDERR, '>', $err_path or die "Unable to redirect STDERR to $err_path: $!";
    my $started = open my $out_fh, '-|', $npm_bin, 'run', 'fuzz:scorecard';
    my $start_error = $!;
    open STDERR, '>&', $saved_stderr or die "Unable to restore STDERR: $!";
    close $saved_stderr or die "Unable to close the saved STDERR handle: $!";
    die "Unable to start $npm_bin run fuzz:scorecard: $start_error" if !$started;

    note('fast-check fuzz run started; one progress line follows per property run');
    my $out = q{};
    while ( my $line = <$out_fh> ) {
        $out .= $line;
        ( my $shown = $line ) =~ s/\s+\z//;
        note($shown) if $shown ne q{};
    }
    # A non-zero exit of the child makes close return false with $! unset;
    # that is a test result for the assertions below, not an error here.
    close $out_fh;
    my $status = $?;

    open my $err_in, '<', $err_path or die "Unable to read $err_path: $!";
    my $err = do { local $/; <$err_in> };
    close $err_in or die "Unable to close $err_path: $!";
    return ( $out, defined $err ? $err : q{}, $status );
}

sub _find_command {
    my ($name) = @_;
    for my $dir ( split /:/, ( $ENV{PATH} || '' ) ) {
        my $candidate = File::Spec->catfile( $dir, $name );
        return $candidate if -x $candidate;
    }
    return;
}

sub _configure_npm_test_env {
    $ENV{npm_config_audit}           = 'false';
    $ENV{npm_config_fund}            = 'false';
    $ENV{npm_config_update_notifier} = 'false';
    $ENV{NO_UPDATE_NOTIFIER}         = '1';
    return;
}

sub _fast_check_run_count {
    my $perl5opt = $ENV{PERL5OPT} // q{};
    my $harness  = $ENV{HARNESS_PERL_SWITCHES} // q{};
    return 5 if $perl5opt =~ /Devel::Cover/ || $harness =~ /Devel::Cover/;
    return 50;
}

__END__

=pod

=head1 NAME

t/35-js-fast-check.t - run the Scorecard-targeted fast-check property suite

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the repository-side
Scorecard and workflow guardrails, specifically the JavaScript C<fast-check>
property suite that exercises the d2 encode and decode path.

=head1 WHY IT EXISTS

It exists because the repository's fuzzing signal is only credible when the
property suite runs under the same test discipline as the Perl code. Keeping
the wrapper here makes npm dependency preparation, stdout and stderr checks, and
the workflow contract visible in one place instead of leaving them implicit in
GitHub Actions only.

=head1 WHEN TO USE

Use this file when changing the Scorecard fuzz workflow, the npm property
harness, or the d2 encode and decode path covered by C<fast-check>.

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
