use Test2::V0;
use Test2::Require::Module 'Atomic::Pipe' => '0.026';

use File::Temp qw/tempdir/;
use File::Spec;

use IPC::Manager::Client::AtomicPipe;
use IPC::Manager::Serializer::JSON;

my $S = 'IPC::Manager::Serializer::JSON';
my $C = 'IPC::Manager::Client::AtomicPipe';

sub kill_child_after {
    my ($route, $code) = @_;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        # @keep holds refs returned by the callback so their DESTROY
        # does not fire (running disconnect, cleaning the state we
        # want stale) before SIGKILL delivers.
        my @keep = $code->($route);
        kill 'KILL', $$;
        require POSIX;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);
    return $pid;
}

# Verifies the Base::FS layer fix carries through to AtomicPipe.

subtest 'reap-and-replace after SIGKILL' => sub {
    my $dir = tempdir(CLEANUP => 1);

    kill_child_after($dir, sub {
        my $r = shift;
        my $c = $C->new(serializer => $S, route => $r, id => 'apvictim');
        return $c;
    });

    ok(-e File::Spec->catfile($dir, 'apvictim'),     'stale FIFO on disk');
    ok(-e File::Spec->catfile($dir, 'apvictim.pid'), 'stale pidfile on disk');

    my $con;
    ok(
        lives { $con = $C->new(serializer => $S, route => $dir, id => 'apvictim') },
        'reap-and-replace allowed re-registration on AtomicPipe',
    ) or note $@;

    $con->disconnect;
};

subtest 'peer_left sweeps dead-pid FIFOs' => sub {
    my $dir      = tempdir(CLEANUP => 1);
    my $observer = $C->new(serializer => $S, route => $dir, id => 'apobs');

    kill_child_after($dir, sub {
        my $r = shift;
        my $c = $C->new(serializer => $S, route => $r, id => 'apdoomed');
        return $c;
    });

    ok(-e File::Spec->catfile($dir, 'apdoomed'), 'stale FIFO on disk');

    my $removed = $observer->peer_left;
    ok($removed >= 1, "peer_left reaped at least one entry ($removed)");
    ok(!-e File::Spec->catfile($dir, 'apdoomed'),     'stale FIFO gone after peer_left');
    ok(!-e File::Spec->catfile($dir, 'apdoomed.pid'), 'stale pidfile gone after peer_left');

    $observer->disconnect;
};

done_testing;
