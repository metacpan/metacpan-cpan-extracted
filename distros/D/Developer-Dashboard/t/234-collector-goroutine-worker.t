use strict;
use warnings;

use File::Spec;
use Test::More;

use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::GoRoutine ();

{
    package Local::CollectorRunnerFiles;
    sub collector_log { return File::Spec->catfile( File::Spec->tmpdir, 'collector.log' ) }
}

my $runner = bless {
    files => bless( {}, 'Local::CollectorRunnerFiles' ),
}, 'Developer::Dashboard::CollectorRunner';
my @spawned;

{
    no warnings qw(redefine once);
    local *Developer::Dashboard::CollectorRunner::is_windows = sub { 0 };
    local *Developer::Dashboard::CollectorRunner::_windows_background_worker_command
      = sub { return ( 'perl', 'worker-helper', 'collector-worker-foreground', '--name', 'sample', '--loop-pid', 77 ) };
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub {
        die 'legacy process split was reached';
    };
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        push @spawned, [ @_ ];
        return 4242;
    };

    my $pid = eval { $runner->_start_loop_worker( { command => 'true' }, 'sample', 'collector sample' ) };
    is( $@, '', 'POSIX worker startup uses the GoRoutine process API, not the legacy split path' );
    is( $pid, 4242, 'worker startup returns the native process identifier' );
}

is( scalar @spawned, 1, 'the GoRoutine process API starts exactly one worker helper' );
is_deeply(
    $spawned[0][0],
    [ 'perl', 'worker-helper', 'collector-worker-foreground', '--name', 'sample', '--loop-pid', 77 ],
    'the worker is launched as a literal helper argument vector',
);
is( $spawned[0][1]{stdout}, File::Spec->catfile( File::Spec->tmpdir, 'collector.log' ),
    'worker standard output is routed to the collector log' );
is( $spawned[0][1]{stderr}, File::Spec->catfile( File::Spec->tmpdir, 'collector.log.stderr' ),
    'worker standard error is routed to the collector error log' );

done_testing;

__END__

=head1 NAME

234-collector-goroutine-worker.t - verify native GoRoutine worker launching

=head1 DESCRIPTION

This contract test isolates C<CollectorRunner::_start_loop_worker>. On a
POSIX-path simulation it supplies a worker helper argument vector and verifies
the runner starts that helper through C<Developer::Dashboard::GoRoutine::spawn>
instead of entering a fork-style parent/child branch.

=head1 PURPOSE

Guard the migration of collector workers to the cross-platform GoRoutine
process API while preserving the helper's arguments, PID, and log destinations.

=head1 WHY IT EXISTS

Collector loop helpers run asynchronously and must retain their separate
process identity and existing log contract. This focused test prevents the
collector launch path from regressing to an inline or fork-specific branch.

=head1 WHEN TO USE

Run after rebuilding the Dashboard XS extension in the dev Docker container.
This test is intentionally independent of a real collector configuration or
process table.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/234-collector-goroutine-worker.t

=head1 WHAT USES IT

The distribution test suite runs this contract alongside collector lifecycle
tests to verify the worker launch path.

=head1 EXAMPLES

  my $pid = $runner->_start_loop_worker($job, 'daily-report', $title);

The returned PID identifies the separate helper process; the helper then reads
the persisted collector job and executes one scheduled run.

=cut
