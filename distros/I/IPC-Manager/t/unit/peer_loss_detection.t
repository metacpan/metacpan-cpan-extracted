use Test2::V0;
use Test2::Require::Module 'Digest::SHA';

use Time::HiRes qw/time/;
use File::Temp qw/tempdir/;
use File::Spec;

use IPC::Manager::Service::Handle;
use IPC::Manager::Client::JSONFile;
use IPC::Manager::Client::LocalMemory;
use IPC::Manager::Client::MessageFiles;
use IPC::Manager::Serializer::JSON;

my $S = 'IPC::Manager::Serializer::JSON';

# Build a Handle around a constructed client so we can drive
# _pending_peer_active directly without going through full service
# spawn machinery.  service_name / ipcm_info are required attributes
# but never used on the code paths we exercise.
sub _make_handle {
    my ($client, $service_name) = @_;
    return IPC::Manager::Service::Handle->new(
        service_name => $service_name,
        ipcm_info    => 'fake',
        client       => $client,
        interval     => 0.05,
    );
}

# Fork a child that registers a peer (returns its refs out of @keep)
# then SIGKILL the child.  Mirrors the helper used by the FS / JSONFile
# SIGKILL-cleanup tests.
sub kill_child_after {
    my ($code) = @_;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        my @keep = $code->();
        kill 'KILL', $$;
        require POSIX;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);
    return $pid;
}

# ----------------------------------------------------------------------
# JSONFile: SIGKILL'd peer is detected by _pending_peer_active even
# though peer_exists keeps returning truthy until peer_left runs.
# ----------------------------------------------------------------------

subtest 'JSONFile: SIGKILL detection in _pending_peer_active' => sub {
    my $route = IPC::Manager::Client::JSONFile->spawn(serializer => $S);

    my $requester = IPC::Manager::Client::JSONFile->connect('requester', $S, $route);
    my $handle    = _make_handle($requester, 'victim');

    # Live peer first: returns active.
    my $live = IPC::Manager::Client::JSONFile->connect('live', $S, $route);
    ok($handle->_pending_peer_active('live', $$), 'live peer reported active');
    $live->disconnect;

    # SIGKILL'd peer: entry persists, captured pid is dead, must be
    # treated as gone.
    my $child_pid = kill_child_after(sub {
        my $c = IPC::Manager::Client::JSONFile->connect('victim', $S, $route);
        return $c;
    });

    ok($requester->peer_exists('victim'), 'stale entry still in JSON state');
    ok(
        !$handle->_pending_peer_active('victim', $child_pid),
        '_pending_peer_active reports SIGKILL\'d peer as gone',
    );

    $requester->disconnect;
    IPC::Manager::Client::JSONFile->unspawn($route);
};

# ----------------------------------------------------------------------
# JSONFile: peer that suspends with a deadline that elapses is treated
# as gone by _pending_peer_active.
# ----------------------------------------------------------------------

subtest 'JSONFile: suspend-expiry triggers peer-gone detection' => sub {
    my $route = IPC::Manager::Client::JSONFile->spawn(serializer => $S);

    my $requester = IPC::Manager::Client::JSONFile->connect('requester', $S, $route);
    my $svc       = IPC::Manager::Client::JSONFile->connect('svc',       $S, $route);
    my $handle    = _make_handle($requester, 'svc');

    # Service suspends with an already-elapsed deadline.
    $svc->suspend(expires_at => time - 1);

    is($requester->peer_suspend_expires('svc'),
       in_set(D()),
       'suspend deadline recorded');

    ok(
        !$handle->_pending_peer_active('svc', $$),
        '_pending_peer_active reports past-deadline suspend as gone',
    );

    # Future-deadline case: not yet expired -> still active.
    my $svc2 = IPC::Manager::Client::JSONFile->connect('svc2', $S, $route);
    $svc2->suspend(expires_at => time + 60);
    ok(
        $handle->_pending_peer_active('svc2', $$),
        'future-deadline suspend still active',
    );

    $requester->disconnect;
    IPC::Manager::Client::JSONFile->unspawn($route);
};

# ----------------------------------------------------------------------
# LocalMemory: suspend-expiry round-trip in-process.
# ----------------------------------------------------------------------

subtest 'LocalMemory: suspend-expiry triggers peer-gone detection' => sub {
    my $route = IPC::Manager::Client::LocalMemory->spawn(serializer => $S);

    my $requester = IPC::Manager::Client::LocalMemory->connect('requester', $S, $route);
    my $svc       = IPC::Manager::Client::LocalMemory->connect('svc',       $S, $route);
    my $handle    = _make_handle($requester, 'svc');

    $svc->suspend(expires_at => time - 1);
    ok(
        !$handle->_pending_peer_active('svc', $$),
        '_pending_peer_active reports past-deadline suspend as gone',
    );

    my $svc2 = IPC::Manager::Client::LocalMemory->connect('svc2', $S, $route);
    $svc2->suspend(expires_at => time + 60);
    ok(
        $handle->_pending_peer_active('svc2', $$),
        'future-deadline suspend still active',
    );

    $requester->disconnect;
    IPC::Manager::Client::LocalMemory->unspawn($route);
};

# ----------------------------------------------------------------------
# MessageFiles (Base::FS): .suspend sidecar round-trip plus SIGKILL
# detection through the suspend-supported branch.
# ----------------------------------------------------------------------

subtest 'MessageFiles: suspend sidecar + SIGKILL detection' => sub {
    my $dir = tempdir(CLEANUP => 1);

    my $requester = IPC::Manager::Client::MessageFiles->new(
        serializer => $S, route => $dir, id => 'requester',
    );

    my $svc = IPC::Manager::Client::MessageFiles->new(
        serializer => $S, route => $dir, id => 'svc',
    );

    my $handle = _make_handle($requester, 'svc');

    $svc->suspend(expires_at => time - 1);

    ok(-f File::Spec->catfile($dir, 'svc.suspend'), '.suspend sidecar written');
    is($requester->peer_suspend_expires('svc'), in_set(D()), 'sidecar read back');

    ok(
        !$handle->_pending_peer_active('svc', $$),
        '_pending_peer_active reports past-deadline suspend as gone',
    );

    # SIGKILL detection on a Base::FS driver
    my $child_pid = kill_child_after(sub {
        my $c = IPC::Manager::Client::MessageFiles->new(
            serializer => $S, route => $dir, id => 'doomed',
        );
        return $c;
    });

    ok(
        !$handle->_pending_peer_active('doomed', $child_pid),
        'SIGKILL\'d peer detected on Base::FS driver',
    );

    $requester->disconnect;
};

# ----------------------------------------------------------------------
# Reconnect clears suspend deadline (peer is back).
# ----------------------------------------------------------------------

subtest 'JSONFile: reconnect clears suspend deadline' => sub {
    my $route = IPC::Manager::Client::JSONFile->spawn(serializer => $S);

    my $svc = IPC::Manager::Client::JSONFile->connect('svc', $S, $route);
    $svc->suspend(expires_at => time + 60);

    my $probe = IPC::Manager::Client::JSONFile->connect('probe', $S, $route);
    is($probe->peer_suspend_expires('svc'), in_set(D()), 'deadline present after suspend');

    my $svc2 = IPC::Manager::Client::JSONFile->reconnect('svc', $S, $route);
    is($probe->peer_suspend_expires('svc'), undef, 'deadline cleared on reconnect');

    $svc2->disconnect;
    $probe->disconnect;
    IPC::Manager::Client::JSONFile->unspawn($route);
};

# ----------------------------------------------------------------------
# DBI (via SQLite): suspend deadline persisted in ipcm_peers, SIGKILL
# detection through the suspend-supported branch.
# ----------------------------------------------------------------------

SKIP: {
    my $skip = !eval { require IPC::Manager::Client::SQLite; IPC::Manager::Client::SQLite->viable };
    skip "SQLite driver not available", 2 if $skip;

    my $DBIC = 'IPC::Manager::Client::SQLite';

    subtest 'DBI/SQLite: suspend-expiry round-trip + active resets it' => sub {
        my $route = $DBIC->spawn(serializer => $S);

        my $requester = $DBIC->connect('requester', $S, $route);
        my $svc       = $DBIC->connect('svc',       $S, $route);
        my $handle    = _make_handle($requester, 'svc');

        $svc->suspend(expires_at => time - 1);
        is($requester->peer_suspend_expires('svc'), in_set(D()), 'deadline persisted in DB');
        ok(
            !$handle->_pending_peer_active('svc', $$),
            '_pending_peer_active reports past-deadline DBI suspend as gone',
        );

        # Future-deadline case still active
        my $svc2 = $DBIC->connect('svc2', $S, $route);
        $svc2->suspend(expires_at => time + 60);
        ok(
            $handle->_pending_peer_active('svc2', $$),
            'future-deadline DBI suspend still active',
        );

        # Reconnecting clears the deadline
        my $svc_back = $DBIC->reconnect('svc', $S, $route);
        is($requester->peer_suspend_expires('svc'), undef, 'deadline cleared on reconnect');

        $svc_back->disconnect;
        $requester->disconnect;
        $DBIC->unspawn($route);
    };

    subtest 'DBI/SQLite: SIGKILL detection in _pending_peer_active' => sub {
        my $route = $DBIC->spawn(serializer => $S);

        my $requester = $DBIC->connect('requester', $S, $route);
        my $handle    = _make_handle($requester, 'doomed');

        my $child_pid = kill_child_after(sub {
            my $c = $DBIC->connect('doomed', $S, $route);
            return $c;
        });

        ok($requester->peer_exists('doomed'), 'stale row present (no peer_left yet)');
        ok(
            !$handle->_pending_peer_active('doomed', $child_pid),
            '_pending_peer_active reports SIGKILL\'d DBI peer as gone',
        );

        $requester->disconnect;
        $DBIC->unspawn($route);
    };
}

done_testing;
