use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Platform ();

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
);
my $files           = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $collector_store = Developer::Dashboard::Collector->new( paths => $paths );
my $indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner          = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector_store,
    files      => $files,
    indicators => $indicator_store,
    paths      => $paths,
);

# ----------------------------------------------------------------------------
# Finding 1: the run_once timeout must round-trip as milliseconds instead of
# being stored under the seconds-keyed field and re-inflated x1000 on reload.
# ----------------------------------------------------------------------------
{
    my $captured;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_run_job = sub {
        my ( undef, %args ) = @_;
        $captured = \%args;
        return ( '', '', 0, 0 );
    };

    $runner->run_once(
        { name => 'timeout.ms', command => 'true', cwd => $home, timeout_ms => 2000 } );
    is( $captured->{timeout_ms}, 2000,
        'run_once forwards a millisecond timeout to the executor unchanged' );

    my $persisted = $collector_store->read_job('timeout.ms');
    is( $persisted->{timeout_ms}, 2000,
        'persisted job records timeout_ms in milliseconds so it round-trips' );
    ok(
        !( defined $persisted->{timeout} && $persisted->{timeout} == 2000 ),
        'persisted job never stores the millisecond value under the seconds timeout field'
    );

    # Simulate the Windows worker re-reading the persisted job before running it.
    $runner->run_once($persisted);
    is( $captured->{timeout_ms}, 2000,
        'reloaded job keeps the same millisecond timeout instead of inflating it 1000x' );

    $runner->run_once(
        { name => 'timeout.sec', command => 'true', cwd => $home, timeout => 2 } );
    is( $captured->{timeout_ms}, 2000,
        'run_once converts a seconds timeout to milliseconds for the executor' );
    my $persisted_sec = $collector_store->read_job('timeout.sec');
    is( $persisted_sec->{timeout}, 2,
        'persisted job keeps a seconds timeout under the seconds field' );
    is( $persisted_sec->{timeout_ms}, 2000,
        'persisted job records the derived millisecond timeout for a seconds timeout' );
}

# _normalize_timeout_ms unit coverage for every input shape.
is( $runner->_normalize_timeout_ms( { timeout_ms => 500 } ), 500,
    '_normalize_timeout_ms prefers an explicit millisecond timeout' );
is( $runner->_normalize_timeout_ms( { timeout => 3 } ), 3000,
    '_normalize_timeout_ms converts a seconds timeout to milliseconds' );
is( $runner->_normalize_timeout_ms( {} ), undef,
    '_normalize_timeout_ms returns undef when no timeout is configured' );
is( $runner->_normalize_timeout_ms('not-a-hash'), undef,
    '_normalize_timeout_ms ignores a non-hash job' );

# ----------------------------------------------------------------------------
# Finding 2: a "* * * * *" cron must obey the per-minute dedup instead of
# firing on every one-second scheduling tick.
# ----------------------------------------------------------------------------
{
    my $cron_name = 'cron.everyminute';
    ok( $runner->_cron_due( '* * * * *', $cron_name ),
        'wildcard cron is due on the first tick of a minute' );
    ok( !$runner->_cron_due( '* * * * *', $cron_name ),
        'wildcard cron is de-duplicated within the same minute' );
}

# ----------------------------------------------------------------------------
# Finding 3: a signal-killed command must never be recorded as a success.
# ----------------------------------------------------------------------------
is( Developer::Dashboard::CollectorRunner::_exit_code_from_status(0), 0,
    '_exit_code_from_status maps a clean exit to 0' );
is( Developer::Dashboard::CollectorRunner::_exit_code_from_status( 3 << 8 ), 3,
    '_exit_code_from_status extracts a normal exit code' );
is( Developer::Dashboard::CollectorRunner::_exit_code_from_status(9), 137,
    '_exit_code_from_status flags a SIGKILL as 128+signal' );
is( Developer::Dashboard::CollectorRunner::_exit_code_from_status(15), 143,
    '_exit_code_from_status flags a SIGTERM as 128+signal' );
is( Developer::Dashboard::CollectorRunner::_exit_code_from_status(undef), 0,
    '_exit_code_from_status treats an undefined status as 0' );

SKIP: {
    skip 'signal-killed command test needs a POSIX shell', 2
      if Developer::Dashboard::Platform::is_windows();
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command(
        source     => 'kill -9 $$',
        cwd        => $home,
        timeout_ms => 5000,
    );
    ok( $exit_code != 0,
        'a signal-killed collector command is recorded as a failure, not a success' );
    ok( !$timed_out, 'a signal-killed collector command is not misreported as a timeout' );
}

# Confirm the existing timeout contract is unchanged by the signal-aware exit
# code: a timed-out command still returns 124 and is flagged as timed out.
SKIP: {
    skip 'timeout contract test needs a POSIX shell', 2
      if Developer::Dashboard::Platform::is_windows();
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command(
        source     => 'perl -e "sleep 3"',
        cwd        => $home,
        timeout_ms => 50,
    );
    is( $exit_code, 124, 'a timed-out collector command still returns 124' );
    ok( $timed_out, 'a timed-out collector command is still flagged as timed out' );
}

# ----------------------------------------------------------------------------
# Finding 4: timing out a command must terminate the complete command subtree.
# The helper records both itself and its long-lived child before blocking so the
# assertion covers the shell command and a descendant rather than only the
# direct process that CollectorRunner waits for.
# ----------------------------------------------------------------------------
{
    my $helper = File::Spec->catfile( $home, 'timeout-subtree.pl' );
    my $pidfile = File::Spec->catfile( $home, 'timeout-subtree.pids' );
    open my $helper_fh, '>', $helper or die "Unable to write $helper: $!";
    print {$helper_fh} <<'HELPER';
use strict;
use warnings;
$| = 1;
my ($pidfile) = @ARGV;
my $descendant;
if ( $^O eq 'MSWin32' ) {
    $descendant = system 1, $^X, '-e', '$| = 1; print "descendant-ready\\n"; sleep 30';
    die "Unable to spawn timeout descendant: $!" if !defined $descendant || $descendant < 1;
}
else {
    $descendant = fork();
    die "Unable to fork timeout descendant: $!" if !defined $descendant;
    if ( !$descendant ) {
        print "descendant-ready\n";
        sleep 30;
        exit 0;
    }
}
open my $pid_fh, '>', $pidfile or die "Unable to write $pidfile: $!";
print {$pid_fh} "$$ $descendant\n";
close $pid_fh or die "Unable to close $pidfile: $!";
print "parent-ready\n";
print STDERR "parent-stderr-ready\n";
sleep 30;
HELPER
    close $helper_fh or die "Unable to close $helper: $!";

    my $shell = Developer::Dashboard::Platform::is_windows() ? 'cmd' : 'sh';
    my $command = join ' ',
      map { Developer::Dashboard::Platform::shell_quote_for( $shell, $_ ) }
      ( $^X, $helper, $pidfile );
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command(
        source     => $command,
        cwd        => $home,
        timeout_ms => 100,
    );

    is( $exit_code, 124, 'a command-subtree timeout returns exit 124' );
    ok( $timed_out, 'a command-subtree timeout is flagged as timed out' );
    like( $stdout, qr/parent-ready/, 'stdout emitted before timeout remains captured' );
    like( $stderr, qr/parent-stderr-ready/, 'stderr emitted before timeout remains captured' );

    open my $pid_fh, '<', $pidfile or die "Unable to read $pidfile: $!";
    my $pids = <$pid_fh>;
    close $pid_fh;
    my ( $command_pid, $descendant_pid ) = $pids =~ /^(\d+)\s+(\d+)/;
    for ( 1 .. 100 ) {
        last if !kill( 0, $command_pid ) && !kill( 0, $descendant_pid );
        select undef, undef, undef, 0.01;
    }
    ok( !kill( 0, $command_pid ), 'timeout terminates the executing command process' );
    ok( !kill( 0, $descendant_pid ), 'timeout terminates the command descendant' );

    # Keep the RED case hermetic: the pre-fix implementation leaves these
    # processes alive, so remove them after observing the failed assertions.
    kill 9, grep { defined && kill( 0, $_ ) } ( $command_pid, $descendant_pid );
}

done_testing();

__END__

=head1 NAME

t/53-hunt-collectorrunner.t

=head1 PURPOSE

Focused regression coverage for three collector-runner defects: a millisecond
timeout being persisted under the seconds-keyed field and re-inflated on reload,
a wildcard C<* * * * *> cron bypassing the per-minute de-duplication, and a
signal-killed command being recorded as a success instead of a failure.

A fourth regression covers complete timed-out command subtree cleanup. The
runner uses a small uninstrumented launcher to record the direct command pid,
isolates POSIX commands into their own sessions, and uses Windows taskkill tree
mode. That avoids both the old orphaning behavior and Devel::Cover's expensive
fork-time reinitialization while preserving the timeout and captured-output
contracts.

=head1 WHY IT EXISTS

Each behavior is easy to get wrong again and hard to see in the broader runtime
suites, which carry heavy setup and monkey-patched process state. This file pins
the fixed behavior with the smallest possible reproductions so a regression in
C<Developer::Dashboard::CollectorRunner> shows up immediately and in isolation.

=head1 WHEN TO USE

Run it while changing collector timeout persistence, cron scheduling and slot
de-duplication, command exit-code interpretation, or the timeout process-group
kill path. It is the first check to run when touching C<run_once>, C<_run_command>,
or C<_cron_due>.

=head1 HOW TO USE

Run it directly while iterating:

  prove -lv t/53-hunt-collectorrunner.t

Run it under the repository coverage gate when closing the library coverage:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/53-hunt-collectorrunner.t

=head1 WHAT USES IT

This is a standalone author regression test for
C<Developer::Dashboard::CollectorRunner>. It is exercised by C<prove -lr t> and
by the repository coverage gate; nothing in the shipped library depends on it.

=head1 EXAMPLES

Reproduce the timeout round-trip and cron de-duplication fixes only:

  prove -lv t/53-hunt-collectorrunner.t :: --verbose

Confirm the signal-aware exit code and process-group timeout kill on a POSIX
host:

  prove -lv t/53-hunt-collectorrunner.t

=cut
