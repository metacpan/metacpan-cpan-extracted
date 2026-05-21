use Test2::V0;

my $CLASS      = 'IPC::Manager::Client::SQLite';
my $SERIALIZER = 'IPC::Manager::Serializer::JSON';

skip_all "SQLite driver not available"
    unless eval { require IPC::Manager::Client::SQLite; $CLASS->viable };

use IPC::Manager::Serializer::JSON;

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

# Open a fresh raw DBI handle to inspect rows in the parent without
# going through the IPC::Manager::Client::SQLite layer.
sub _open_raw {
    my ($route) = @_;
    require DBI;
    return DBI->connect("dbi:SQLite:dbname=$route", undef, undef, {RaiseError => 1, PrintError => 0});
}

sub _peer_row {
    my ($route, $id) = @_;
    my $dbh = _open_raw($route);
    my $sth = $dbh->prepare("SELECT * FROM ipcm_peers WHERE `id` = ?");
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    $dbh->disconnect;
    return $row;
}

sub _msg_count_to {
    my ($route, $to) = @_;
    my $dbh = _open_raw($route);
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM ipcm_messages WHERE `to` = ?");
    $sth->execute($to);
    my ($n) = $sth->fetchrow_array;
    $sth->finish;
    $dbh->disconnect;
    return $n;
}

subtest 'reap-and-replace after SIGKILL' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    my $child_pid = kill_child_after($route, sub {
        my $r = shift;
        my $con = $CLASS->connect('victim', $SERIALIZER, $r);
        # Also send self a couple of messages so the inbox accrues
        # stale entries we expect to be reaped on re-registration.
        my $peer = $CLASS->connect('aux', $SERIALIZER, $r);
        $peer->send_message(victim => 'stale1');
        $peer->send_message(victim => 'stale2');
        return ($con, $peer);
    });

    # Pre-condition: stale row + stale inbox.
    my $row = _peer_row($route, 'victim');
    ok($row, 'stale peer row present after SIGKILL');
    is($row->{pid}, $child_pid, 'stale row carries dead child pid');
    is(_msg_count_to($route, 'victim'), 2, 'stale messages addressed to victim');

    # Re-register: should succeed via reap-and-replace, and stale
    # inbox should be cleared.
    my $con;
    ok(
        lives { $con = $CLASS->connect('victim', $SERIALIZER, $route) },
        'fresh registration with same id succeeds',
    ) or note $@;

    is(_msg_count_to($route, 'victim'), 0, 'stale messages cleared on reap');

    my $row2 = _peer_row($route, 'victim');
    is($row2->{pid}, $$, 'row now carries our pid');

    $con->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peer_left sweeps dead-pid rows' => sub {
    my $route    = $CLASS->spawn(serializer => $SERIALIZER);
    my $observer = $CLASS->connect('obs', $SERIALIZER, $route);

    kill_child_after($route, sub {
        my $r = shift;
        my $c = $CLASS->connect('doomed', $SERIALIZER, $r);
        return $c;
    });

    ok(_peer_row($route, 'doomed'), 'stale row present pre-sweep');

    my $removed = $observer->peer_left;
    is($removed, 1, 'peer_left reaped one stale row');

    ok(!_peer_row($route, 'doomed'), 'stale row deleted');

    $observer->disconnect;
    $CLASS->unspawn($route);
};

subtest 'peers() filters dead-pid rows' => sub {
    my $route    = $CLASS->spawn(serializer => $SERIALIZER);
    my $observer = $CLASS->connect('obs2', $SERIALIZER, $route);
    my $live     = $CLASS->connect('live', $SERIALIZER, $route);

    kill_child_after($route, sub {
        my $r = shift;
        my $c = $CLASS->connect('dead', $SERIALIZER, $r);
        return $c;
    });

    my @peers = sort $observer->peers;
    is(\@peers, ['live'], 'peers() includes live peer, excludes dead-pid peer');

    $live->disconnect;
    $observer->disconnect;
    $CLASS->unspawn($route);
};

subtest 'foreign-pid safety still croaks' => sub {
    my $route = $CLASS->spawn(serializer => $SERIALIZER);

    # Inject a stale row whose pid is our own running pid.
    # pid_is_running($$) returns 1 (ours), so init must croak with the
    # "already running" message instead of silently re-using the row.
    my $dbh = _open_raw($route);
    $dbh->do("INSERT INTO ipcm_peers(`id`, `pid`, `active`) VALUES (?, ?, ?)", undef, 'foreign', $$, time);
    $dbh->disconnect;

    like(
        dies { $CLASS->connect('foreign', $SERIALIZER, $route) },
        qr/already running/,
        'live foreign pid triggers "already running" croak',
    );

    my $row = _peer_row($route, 'foreign');
    is($row->{pid}, $$, 'foreign row preserved (not reaped)');

    $CLASS->unspawn($route);
};

done_testing;
