use Test2::V0;
use Test2::Require::Module 'IPC::SysV' => '2.09';

# Skip if Makefile.PL disabled SharedMem because the host's SysV IPC
# was broken at install time.  _viable() throws when disabled, so
# viable() returns false.
require IPC::Manager::Client::SharedMem;
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    unless (IPC::Manager::Client::SharedMem->viable) {
        my $reason = join('', @warnings) || 'viable() returned false';
        plan(skip_all => "IPC::Manager::Client::SharedMem not viable: $reason");
    }
}

use POSIX ();
use Time::HiRes qw/time/;

use IPC::Manager::Service::Handle;
use IPC::Manager::Serializer::JSON;

my $CLASS      = 'IPC::Manager::Client::SharedMem';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

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

# Fork a child that registers a peer (returned by $code) and then
# SIGKILLs itself before any DESTROY cleanup can run.  Mirrors the
# helper used by upstream peer_loss_detection.t.
sub kill_child_after {
    my ($code) = @_;
    my $pid = fork;
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        my @keep = $code->();
        kill 'KILL', $$;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    # Sanity: pid must actually be gone before we run assertions.
    my $tries = 0;
    while (kill(0, $pid) && $tries++ < 50) {
        select undef, undef, undef, 0.01;
    }

    return $pid;
}

subtest 'pre_suspend_hook persists deadline; peer_suspend_expires reads it' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    my $svc   = $CLASS->connect('svc',   $SERIALIZER, $route);
    my $probe = $CLASS->connect('probe', $SERIALIZER, $route);

    my $deadline = time + 60;
    $svc->pre_suspend_hook(expires_at => $deadline);

    is(
        $probe->peer_suspend_expires('svc'),
        $deadline,
        'separate client reads back the persisted deadline',
    );

    # No expires_at => leave the slot untouched.
    $svc->pre_suspend_hook();
    is(
        $probe->peer_suspend_expires('svc'),
        $deadline,
        'pre_suspend_hook with no expires_at does not clobber the slot',
    );

    # Unknown peer => undef, not a croak.
    is(
        $probe->peer_suspend_expires('does_not_exist'),
        undef,
        'peer_suspend_expires on unknown peer returns undef',
    );

    $svc->disconnect;
    $probe->disconnect;
    $CLASS->unspawn($route);
};

subtest 'reconnect clears the suspend deadline' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    my $svc = $CLASS->connect('svc', $SERIALIZER, $route);
    $svc->suspend(expires_at => time + 60);

    my $probe = $CLASS->connect('probe', $SERIALIZER, $route);
    is($probe->peer_suspend_expires('svc'), in_set(D()),
        'deadline present after suspend');

    my $svc2 = $CLASS->reconnect('svc', $SERIALIZER, $route);
    is($probe->peer_suspend_expires('svc'), undef,
        'deadline cleared on reconnect');

    $svc2->disconnect;
    $probe->disconnect;
    $CLASS->unspawn($route);
};

subtest 'fresh registration over a stale entry clears the deadline' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    # Inject a stale entry whose pid is a long-dead fork, plus a
    # suspend deadline.  init() should reap-and-replace AND wipe the
    # deadline.
    my $seed = $CLASS->connect('seed', $SERIALIZER, $route);

    my $dead_pid = fork;
    die "fork failed: $!" unless defined $dead_pid;
    if ($dead_pid == 0) { kill 'KILL', $$; POSIX::_exit(1) }
    waitpid($dead_pid, 0);
    my $tries = 0;
    while (kill(0, $dead_pid) && $tries++ < 50) {
        select undef, undef, undef, 0.01;
    }

    {
        my $state = $seed->_lock_write;
        $state->{clients}{stale} = {
            pid                => $dead_pid,
            suspend_expires_at => time + 999,
        };
        $state->{messages}{stale} //= [];
        $seed->_commit($state);
    }

    is($seed->peer_suspend_expires('stale'), in_set(D()),
        'stale entry carries a deadline before reap-and-replace');

    my $fresh = $CLASS->connect('stale', $SERIALIZER, $route);
    is($seed->peer_suspend_expires('stale'), undef,
        'fresh registration cleared the deadline');
    is($seed->peer_pid('stale'), $$,
        'fresh registration installed our pid');

    $fresh->disconnect;
    $seed->disconnect;
    $CLASS->unspawn($route);
};

subtest 'past-deadline suspend reported as gone via _pending_peer_active' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    my $requester = $CLASS->connect('requester', $SERIALIZER, $route);
    my $svc       = $CLASS->connect('svc',       $SERIALIZER, $route);
    my $handle    = _make_handle($requester, 'svc');

    $svc->suspend(expires_at => time - 1);

    is($requester->peer_suspend_expires('svc'), in_set(D()),
        'suspend deadline recorded');

    ok(
        !$handle->_pending_peer_active('svc', $$),
        '_pending_peer_active reports past-deadline suspend as gone',
    );

    # Future-deadline case: not yet expired -> still active.
    my $svc2 = $CLASS->connect('svc2', $SERIALIZER, $route);
    $svc2->suspend(expires_at => time + 60);
    ok(
        $handle->_pending_peer_active('svc2', $$),
        'future-deadline suspend still active',
    );

    $requester->disconnect;
    $CLASS->unspawn($route);
};

subtest 'SIGKILL detection via _pending_peer_active' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    my $requester = $CLASS->connect('requester', $SERIALIZER, $route);
    my $handle    = _make_handle($requester, 'victim');

    # Live peer first: returns active.
    my $live = $CLASS->connect('live', $SERIALIZER, $route);
    ok($handle->_pending_peer_active('live', $$), 'live peer reported active');
    $live->disconnect;

    # SIGKILL'd peer: entry persists, captured pid is dead, must be
    # treated as gone.
    my $child_pid = kill_child_after(sub {
        my $c = $CLASS->connect('victim', $SERIALIZER, $route);
        return $c;
    });

    ok($requester->peer_exists('victim'),
        'stale entry still in shared-memory state');
    ok(
        !$handle->_pending_peer_active('victim', $child_pid),
        '_pending_peer_active reports SIGKILL\'d peer as gone',
    );

    $requester->disconnect;
    $CLASS->unspawn($route);
};

done_testing;
