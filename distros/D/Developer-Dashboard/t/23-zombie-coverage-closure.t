use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use Time::HiRes qw(time);

use lib 'lib';

use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::GoRoutine ();

{
    my $helper = File::Spec->catfile( File::Spec->tmpdir, sprintf 'developer-dashboard-t47-%d-%d.helper', $$, int( time() * 1_000_000 ) );
    my $runtime = bless {}, 'Developer::Dashboard::RuntimeManager';
    my $helper_supports_internal_command = \&Developer::Dashboard::RuntimeManager::_helper_file_supports_internal_command;
    open my $helper_fh, '>', $helper or die "Unable to create $helper: $!";
    print {$helper_fh} "web-foreground\n";
    close $helper_fh or die "Unable to close $helper: $!";
    ok( -f $helper, 'helper fixture exists before helper command detection checks run' );
    my $supported = $helper_supports_internal_command->( $runtime, $helper, 'web-foreground' );
    is(
        $supported,
        1,
        '_helper_file_supports_internal_command detects the requested internal command token in helper content',
    );
    my $negative_supported = $helper_supports_internal_command->( $runtime, $helper, 'collector-foreground' );
    is(
        $negative_supported,
        0,
        '_helper_file_supports_internal_command returns false when the helper content does not include the requested command token',
    );
    unlink $helper or die "Unable to remove $helper: $!";
    ok( !-e $helper, 'helper fixture is removed after the helper command detection checks finish' );
}

{
    my $runner = bless {}, 'Developer::Dashboard::CollectorRunner';
    my %active = ( 424242 => 1 );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pid_is_running = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_reap_child_process = sub { return 1 };
    ok(
        $runner->_terminate_loop_workers( \%active ),
        '_terminate_loop_workers still succeeds when it has to execute the forced-kill branch for a stubborn worker pid',
    );
    is_deeply(
        \%active,
        {},
        '_terminate_loop_workers clears the active worker set after the forced-kill branch runs',
    );
}

{
    my $runner = bless {}, 'Developer::Dashboard::CollectorRunner';
    my %active = (
        7      => 1,
        0      => 1,
        -2     => 1,
        alpha  => 1,
    );
    is_deeply(
        [ $runner->_active_worker_pids( \%active ) ],
        [7],
        '_active_worker_pids filters out non-numeric and non-positive worker keys',
    );
}

{
    my $scratch = tempdir( 'dd-fd-close-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $result_file = File::Spec->catfile( $scratch, 'result' );
    my $error_file = File::Spec->catfile( $scratch, 'stderr' );
    my $child_script = q{
        use strict;
        use warnings;
        use POSIX ();
        $| = 1;
        pipe my $keep_reader, my $keep_writer or die "Unable to create keep pipe: $!";
        pipe my $drop_reader, my $drop_writer or die "Unable to create drop pipe: $!";
        local $SIG{PIPE} = 'IGNORE';
        local $SIG{__WARN__} = sub {
            my ($warning) = @_;
            return if defined $warning && $warning =~ /Bad file descriptor/;
            warn $warning;
        };
        my $runner = bless {}, 'Developer::Dashboard::CollectorRunner';
        $runner->_close_inherited_fds(
            keep => [ undef, 'not-a-fd', fileno($keep_reader), fileno($keep_writer) ],
        );
        my $keep_ok = defined syswrite( $keep_writer, "kept\n" ) ? 1 : 0;
        my $drop_ok = defined syswrite( $drop_writer, "dropped\n" ) ? 1 : 0;
        print "$keep_ok:$drop_ok\n" or die "Unable to write result: $!";
        POSIX::_exit(0);
    };
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-MDeveloper::Dashboard::CollectorRunner', '-e', $child_script ],
        { stdout => $result_file, stderr => $error_file },
    );
    my $exit = Developer::Dashboard::GoRoutine::wait_process($pid);
    open my $error_fh, '<', $error_file or die "Unable to read $error_file: $!";
    my $error = do { local $/; <$error_fh> } // '';
    close $error_fh or die "Unable to close $error_file: $!";
    is( $error, '', 'GoRoutine descriptor fixture emits no warnings or errors' );
    is( $exit, 0, 'GoRoutine child exits successfully after the descriptor contract check' );
    open my $result_fh, '<', $result_file or die "Unable to read $result_file: $!";
    my $payload = <$result_fh>;
    close $result_fh or die "Unable to close $result_file: $!";
    chomp $payload if defined $payload;
    is(
        $payload,
        '1:0',
        '_close_inherited_fds ignores invalid keep entries while preserving numeric descriptors that must stay open',
    );
}

done_testing();

__END__

=pod

=head1 NAME

t/23-zombie-coverage-closure.t

=head1 PURPOSE

Provides isolated regression coverage for the zombie-process fixes that were
hard to exercise reliably inside broader runtime tests.

=head1 WHAT IT TESTS

This test file verifies two narrow internal behaviors:

=over 4

=item *

the runtime helper command probe can recognize a matching internal helper
command string from a helper file body

=item *

the collector loop shutdown path can execute its forced-kill cleanup branch and
still clear the tracked active worker set

=back

=head1 WHY IT EXISTS

The broader runtime and refactor suites carry a lot of setup and monkey-patched
state. These two coverage points are simpler and more reliable when exercised in
their own minimal test file.

=head1 WHEN TO USE

Use this focused regression while changing collector child-reaping behavior,
forced worker shutdown, or the runtime helper command detection code. It is
meant for narrow zombie-fix iterations where the broader runtime suites would
add unnecessary setup noise.

=head1 HOW TO USE

Run it directly while iterating on collector zombie handling or runtime helper
resolution:

  d2 docker compose exec -T dev prove -lv t/23-zombie-coverage-closure.t

Run it under coverage when closing the final library coverage gap:

  d2 docker compose exec -T -e HARNESS_PERL_SWITCHES=-MDevel::Cover dev prove -lv t/23-zombie-coverage-closure.t

=head1 EXAMPLES

Direct focused rerun:

  d2 docker compose exec -T dev prove -lv t/23-zombie-coverage-closure.t

Covered focused rerun:

  d2 docker compose exec -T -e HARNESS_PERL_SWITCHES=-MDevel::Cover dev prove -lv t/23-zombie-coverage-closure.t

=head1 WHAT USES IT

This file is a focused regression for the collector zombie cleanup and runtime
helper command-detection code paths in
C<Developer::Dashboard::CollectorRunner> and
C<Developer::Dashboard::RuntimeManager>.

=cut
