use Test2::V0;

use File::Temp qw/tempdir/;
use File::Spec;

use IPC::Manager::Client::MessageFiles;
use IPC::Manager::Serializer::JSON;

my $S = 'IPC::Manager::Serializer::JSON';
my $C = 'IPC::Manager::Client::MessageFiles';

sub kill_child_after {
    my ($route, $code) = @_;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        my @keep = $code->($route);
        kill 'KILL', $$;
        require POSIX;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);
    return $pid;
}

subtest 'reap-and-replace after SIGKILL' => sub {
    my $dir = tempdir(CLEANUP => 1);

    kill_child_after($dir, sub {
        my $r = shift;
        my $c = $C->new(serializer => $S, route => $r, id => 'mfvictim');
        return $c;
    });

    ok(-d File::Spec->catfile($dir, 'mfvictim'),     'stale peer dir on disk');
    ok(-e File::Spec->catfile($dir, 'mfvictim.pid'), 'stale pidfile on disk');

    my $con;
    ok(
        lives { $con = $C->new(serializer => $S, route => $dir, id => 'mfvictim') },
        'reap-and-replace allowed re-registration on MessageFiles',
    ) or note $@;

    $con->disconnect;
};

subtest 'peer_left sweeps dead-pid peer dirs' => sub {
    my $dir      = tempdir(CLEANUP => 1);
    my $observer = $C->new(serializer => $S, route => $dir, id => 'mfobs');

    kill_child_after($dir, sub {
        my $r = shift;
        my $c = $C->new(serializer => $S, route => $r, id => 'mfdoomed');
        return $c;
    });

    ok(-d File::Spec->catfile($dir, 'mfdoomed'), 'stale peer dir on disk');

    my $removed = $observer->peer_left;
    is($removed, 1, 'peer_left reaped one stale entry');
    ok(!-e File::Spec->catfile($dir, 'mfdoomed'),     'stale peer dir gone after peer_left');
    ok(!-e File::Spec->catfile($dir, 'mfdoomed.pid'), 'stale pidfile gone after peer_left');

    $observer->disconnect;
};

done_testing;
