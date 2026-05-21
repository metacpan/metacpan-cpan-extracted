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
use IPC::Manager::Serializer::JSON;

my $CLASS      = 'IPC::Manager::Client::SharedMem';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

# Spawn a short-lived child that registers a SharedMem client with the
# given id and then SIGKILLs itself before any DESTROY cleanup can run.
# Returns the child pid.
sub spawn_sigkilled_peer {
    my ($id, $route) = @_;

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if ($pid == 0) {
        # child
        my $ok = eval {
            my $con = $CLASS->connect($id, $SERIALIZER, $route);
            # Bypass DESTROY / disconnect entirely.
            kill 'KILL', $$;
            1;
        };
        # Should never reach here, but just in case kill is delayed.
        POSIX::_exit($ok ? 0 : 1);
    }

    # parent: reap the child and confirm SIGKILL signature
    waitpid($pid, 0);
    my $status = $?;
    die "child did not exit on SIGKILL: status=$status" unless ($status & 127) == 9;

    # Sanity: pid must be gone.
    my $tries = 0;
    while (kill(0, $pid) && $tries++ < 50) {
        select undef, undef, undef, 0.01;
    }

    return $pid;
}

subtest 'SIGKILLed peer can be re-registered (reap-and-replace)' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con_main = $CLASS->connect('rk_main', $SERIALIZER, $route);

    my $dead_pid = spawn_sigkilled_peer('rk_peer', $route);

    # The stale entry should still be present in shared memory.
    ok($con_main->peer_exists('rk_peer'),
        "stale peer entry persists after SIGKILL (registration not reaped by DESTROY)");
    is($con_main->peer_pid('rk_peer'), $dead_pid,
        "stale entry carries the dead child's pid");

    # A fresh register with the same id must succeed: init() should
    # detect the dead pid and reap-and-replace, not croak.
    my $con_replacement;
    ok(
        lives { $con_replacement = $CLASS->connect('rk_peer', $SERIALIZER, $route) },
        "re-registering with the same id after SIGKILL succeeds (no 'already exists' croak)",
    ) or note $@;

    # From the main client's view, peer_pid for rk_peer should now be
    # our pid (the replacement registered in this process).
    is($con_main->peer_pid('rk_peer'), $$,
        "registration now carries the live replacement pid");

    $con_replacement->disconnect if $con_replacement;
    $con_main->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peer_left sweeps dead-pid entries' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con_a = $CLASS->connect('pl_a', $SERIALIZER, $route);

    # Synthesize a stale entry pointing at a definitely-dead pid by
    # forking-and-SIGKILLing a child that does NOT register itself,
    # then injecting a fake registration carrying that pid.  This
    # gives us a "registration that bypasses DESTROY" without the
    # noisy timing of the child registering first.
    my $dead_pid = fork;
    die "fork failed: $!" unless defined $dead_pid;
    if ($dead_pid == 0) { kill 'KILL', $$; POSIX::_exit(1) }
    waitpid($dead_pid, 0);
    my $tries = 0;
    while (kill(0, $dead_pid) && $tries++ < 50) {
        select undef, undef, undef, 0.01;
    }

    {
        my $state = $con_a->_lock_write;
        $state->{clients}{pl_dead}     = {pid => $dead_pid};
        $state->{messages}{pl_dead}    = [{from => 'pl_a', to => 'pl_dead', content => 'orphan'}];
        $state->{stats}{pl_dead}       = {read => {}, sent => {}};
        $con_a->_commit($state);
    }

    ok($con_a->peer_exists('pl_dead'),
        "stale entry visible via peer_exists before sweep");

    my $removed = $con_a->peer_left('pl_dead');
    ok($removed, "peer_left reported reaping at least one entry");

    ok(!$con_a->peer_exists('pl_dead'),
        "stale entry gone after peer_left sweep");

    # Confirm associated messages + stats were cleaned up too.
    my $state = $con_a->_lock_read;
    ok(!exists $state->{messages}{pl_dead},
        "messages for stale peer cleaned up");
    ok(!exists $state->{stats}{pl_dead},
        "stats for stale peer cleaned up");

    $con_a->disconnect;
    $CLASS->unspawn($route);
};

subtest 'foreign-pid safety: running pids are NOT reaped' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con_seed = $CLASS->connect('fp_seed', $SERIALIZER, $route);

    # Inject a stale-looking entry whose pid is actually alive (the
    # test harness's own pid).  pid_is_running($$) returns 1, so
    # init() must NOT reap -- it must croak as usual.
    {
        my $state = $con_seed->_lock_write;
        $state->{clients}{fp_target} = {pid => $$};
        $state->{messages}{fp_target} //= [];
        $con_seed->_commit($state);
    }

    like(
        dies { $CLASS->connect('fp_target', $SERIALIZER, $route) },
        qr/Client 'fp_target' already exists/,
        "registering over an entry whose pid is running still croaks",
    );

    # The entry must still be present (not silently reaped).
    ok($con_seed->peer_exists('fp_target'),
        "running-pid entry was preserved (not reaped by init)");

    # Cleanup the injected entry so unspawn / disconnect don't leak it.
    {
        my $state = $con_seed->_lock_write;
        delete $state->{clients}{fp_target};
        delete $state->{messages}{fp_target};
        $con_seed->_commit($state);
    }

    $con_seed->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peers() filters dead-pid entries' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);
    my $con   = $CLASS->connect('pf_observer', $SERIALIZER, $route);
    my $alive = $CLASS->connect('pf_alive',    $SERIALIZER, $route);

    # Manufacture a dead pid.
    my $dead_pid = fork;
    die "fork failed: $!" unless defined $dead_pid;
    if ($dead_pid == 0) { kill 'KILL', $$; POSIX::_exit(1) }
    waitpid($dead_pid, 0);
    my $tries = 0;
    while (kill(0, $dead_pid) && $tries++ < 50) {
        select undef, undef, undef, 0.01;
    }

    {
        my $state = $con->_lock_write;
        $state->{clients}{pf_dead} = {pid => $dead_pid};
        $con->_commit($state);
    }

    my @peers = $con->peers;
    is(\@peers, ['pf_alive'],
        "peers() omits the dead-pid entry and lists only the live peer");

    $alive->disconnect;
    $con->disconnect;
    $CLASS->unspawn($route);
};

done_testing;
