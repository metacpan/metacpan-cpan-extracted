use strict;
use warnings;

use Test::More;

use File::Spec;
use File::Temp qw( tempdir );
use Log::Dispatch;
use Log::Dispatch::File::Locked;
use POSIX qw( :sys_wait_h );
use Try::Tiny;

my $ChildCount = 10;
for my $close_after_write ( 0, 1 ) {
    my @v = _run_children($close_after_write);
    subtest(
        "close_after_write = $close_after_write",
        sub {
            _test_file_locked(@v);
        }
    );
}

done_testing();

sub _run_children {
    my $close_after_write = shift;

    my $dir  = tempdir( CLEANUP => 1 );
    my $file = File::Spec->catfile( $dir, 'lock-test.log' );

    my $logger = _dispatch_for_file( $close_after_write, $file );

    my %pids;
    for ( 1 .. $ChildCount ) {
        if ( my $pid = fork ) {
            $pids{$pid} = 1;
        }
        else {
            _write_to_file( $close_after_write, $file );
            exit 0;
        }
    }

    my %exit_status;
    try {
        local $SIG{ALRM}
            = sub { die 'Waited 30 seconds for children to exit' };
        alarm 30;

        while ( keys %pids ) {
            my $pid = waitpid( -1, WNOHANG );
            if ( delete $pids{$pid} ) {
                $exit_status{$pid} = $?;
            }
        }
    };

    return ( $file, $@, \%exit_status );
}

sub _write_to_file {
    my $close_after_write = shift;
    my $file              = shift;

    my $dispatch = _dispatch_for_file( $close_after_write, $file );

    # The sleep makes a deadlock much more likely if the locking logic is not
    # working correctly. Without it each child process runs so quickly that
    # they are unlikely to step on each other.
    $dispatch->info(1);
    sleep 1;
    $dispatch->info(2);
    $dispatch->info(3);

    return;
}

sub _dispatch_for_file {
    my $close_after_write = shift;
    my $file              = shift;

    return Log::Dispatch->new(
        outputs => [
            [
                'File::Locked',
                filename          => $file,
                mode              => 'append',
                close_after_write => $close_after_write,
                min_level         => 'debug',
                newline           => 1,
            ]
        ],
    );
}

sub _test_file_locked {
    my $file  = shift;
    my $exc   = shift;
    my $exits = shift;

    is(
        $exc,
        q{},
        'no exception forking children and writing to file'
    );

    is(
        keys %{$exits},
        $ChildCount,
        "$ChildCount children exited",
    );

    for my $pid ( keys %{$exits} ) {
        is(
            $exits->{$pid},
            0,
            "$pid exited with 0"
        );
    }

    _test_file_content($file);
}

sub _test_file_content {
    my $file = shift;

    open my $fh, '<', $file
        or die "Cannot read $file: $!";
    my @lines;
    while ( defined( my $line = <$fh> ) ) {
        chomp $line;
        push @lines, $line;
    }

    close $fh or die $!;

    return if is_deeply(
        [ sort @lines ],
        [ (1) x $ChildCount, (2) x $ChildCount, (3) x $ChildCount ],
        'file contains expected content'
    );

    open my $diag_fh, '<', $file or die $!;
    diag(
        do { local $/ = undef; <$diag_fh> }
    );
    close $diag_fh or die $!;
}
