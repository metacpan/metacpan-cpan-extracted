use Test2::V0;
use Test2::Require::Module 'IO::Socket::UNIX' => '1.55';

use File::Temp qw/tempdir/;
use File::Spec;

use IPC::Manager::Client::ConnectionUnix;
use IPC::Manager::Serializer::JSON;

my $S = 'IPC::Manager::Serializer::JSON';
my $C = 'IPC::Manager::Client::ConnectionUnix';

# Fork a child, run $code->($route) in it, then SIGKILL the child while
# whatever refs the callback returned are still in scope -- so DESTROY
# does not fire on them before SIGKILL delivers (DESTROY would call
# disconnect, which runs pre_disconnect_hook and is exactly what we want
# to skip to simulate ungraceful death).  POSIX::_exit avoids the END
# / DESTROY cascade in case SIGKILL is somehow deferred.
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
        my $c = $C->new(serializer => $S, route => $r, id => 'victim');
        return $c;
    });

    ok(-e File::Spec->catfile($dir, 'victim'),     'stale socket on disk after SIGKILL');
    ok(-e File::Spec->catfile($dir, 'victim.pid'), 'stale pidfile on disk after SIGKILL');

    my $con;
    ok(
        lives { $con = $C->new(serializer => $S, route => $dir, id => 'victim') },
        'fresh registration with same id succeeds (reap-and-replace)',
    ) or note $@;
    is($con->id, 'victim', 'id matches');

    $con->disconnect;
};

subtest 'peer_left sweeps dead-pid artifacts' => sub {
    my $dir      = tempdir(CLEANUP => 1);
    my $observer = $C->new(serializer => $S, route => $dir, id => 'observer');

    kill_child_after($dir, sub {
        my $r = shift;
        my $c = $C->new(serializer => $S, route => $r, id => 'doomed');
        return $c;
    });

    ok(-e File::Spec->catfile($dir, 'doomed'),     'stale socket on disk');
    ok(-e File::Spec->catfile($dir, 'doomed.pid'), 'stale pidfile on disk');

    my $removed = $observer->peer_left;
    is($removed, 1, 'peer_left reaped one stale entry');

    ok(!-e File::Spec->catfile($dir, 'doomed'),     'stale socket gone after peer_left');
    ok(!-e File::Spec->catfile($dir, 'doomed.pid'), 'stale pidfile gone after peer_left');

    $observer->disconnect;
};

subtest 'peers() filters dead-pid peers' => sub {
    my $dir      = tempdir(CLEANUP => 1);
    my $observer = $C->new(serializer => $S, route => $dir, id => 'obs');
    my $live     = $C->new(serializer => $S, route => $dir, id => 'live');

    kill_child_after($dir, sub {
        my $r = shift;
        my $c = $C->new(serializer => $S, route => $r, id => 'dead');
        return $c;
    });

    my @peers = $observer->peers;
    is(\@peers, ['live'], 'peers() includes live peer, excludes dead-pid peer');

    $live->disconnect;
    $observer->disconnect;
};

subtest 'foreign-pid safety still croaks' => sub {
    my $dir = tempdir(CLEANUP => 1);

    # Synthesize artifacts whose pidfile carries our own running pid.
    # pid_is_running returns 1 (ours), so init reap-and-replace must
    # NOT engage; the original "already exists" croak must still fire.
    my $path    = File::Spec->catfile($dir, 'foreign');
    my $pidfile = File::Spec->catfile($dir, 'foreign.pid');
    open(my $fh, '>', $path) or die $!;
    close $fh;
    open(my $pfh, '>', $pidfile) or die $!;
    print $pfh $$;
    close $pfh;

    like(
        dies { $C->new(serializer => $S, route => $dir, id => 'foreign') },
        qr/already exists/,
        'live foreign pid triggers original collision croak',
    );

    # Note: we deliberately do NOT assert the synth files survive the
    # failed registration -- the existing DESTROY-on-init-failure path
    # already cleans the main path artifact regardless of the reap
    # logic, and that pre-existing behavior is out of scope for this
    # test.  What matters is that the croak fired and our reap-and-
    # replace did not silently engage on the live foreign pid.

    unlink $path, $pidfile if -e $path || -e $pidfile;
};

done_testing;
