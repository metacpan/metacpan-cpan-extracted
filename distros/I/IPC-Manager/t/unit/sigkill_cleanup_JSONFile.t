use Test2::V0;
use Test2::Require::Module 'Digest::SHA';

use File::Temp qw/tempdir/;

use IPC::Manager::Client::JSONFile;
use IPC::Manager::Serializer::JSON;
use IPC::Manager::Serializer::JSON;

my $S = 'IPC::Manager::Serializer::JSON';
my $C = 'IPC::Manager::Client::JSONFile';

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

sub _state {
    my ($route) = @_;
    open(my $fh, '<', $route) or die "Cannot open '$route': $!";
    my $raw = do { local $/; <$fh> };
    close $fh;
    return IPC::Manager::Serializer::JSON->deserialize($raw);
}

subtest 'reap-and-replace after SIGKILL' => sub {
    my $route = $C->spawn(serializer => $S);

    kill_child_after($route, sub {
        my $r = shift;
        my $c = $C->connect('jfvictim', $S, $r);
        return $c;
    });

    # Entry persists because DESTROY did not run in the child.
    my $state = _state($route);
    ok($state->{clients}{jfvictim}, 'stale entry in JSON state after SIGKILL');

    my $con;
    ok(
        lives { $con = $C->connect('jfvictim', $S, $route) },
        'fresh registration with same id succeeds (reap-and-replace)',
    ) or note $@;
    is($con->id, 'jfvictim', 'id matches');
    is($con->pid, $$, 'pid is ours (replaced stale entry)');

    $con->disconnect;
    $C->unspawn($route);
};

subtest 'peer_left sweeps dead-pid entries' => sub {
    my $route    = $C->spawn(serializer => $S);
    my $observer = $C->connect('jfobs', $S, $route);

    kill_child_after($route, sub {
        my $r = shift;
        my $c = $C->connect('jfdoomed', $S, $r);
        return $c;
    });

    my $state = _state($route);
    ok($state->{clients}{jfdoomed}, 'stale entry present pre-sweep');

    my $removed = $observer->peer_left;
    is($removed, 1, 'peer_left reaped one stale entry');

    $state = _state($route);
    ok(!$state->{clients}{jfdoomed},  'stale clients row gone');
    ok(!$state->{messages}{jfdoomed}, 'stale messages row gone');

    $observer->disconnect;
    $C->unspawn($route);
};

subtest 'peers() filters dead-pid entries' => sub {
    my $route    = $C->spawn(serializer => $S);
    my $observer = $C->connect('jfo', $S, $route);
    my $live     = $C->connect('jflive', $S, $route);

    kill_child_after($route, sub {
        my $r = shift;
        my $c = $C->connect('jfdead', $S, $r);
        return $c;
    });

    my @peers = $observer->peers;
    is(\@peers, ['jflive'], 'peers() includes live peer, excludes dead-pid peer');

    $live->disconnect;
    $observer->disconnect;
    $C->unspawn($route);
};

subtest 'foreign-pid safety still croaks' => sub {
    my $route = $C->spawn(serializer => $S);

    # First, prove we can register an id called 'foreign' normally so
    # the croak below is specifically about the collision logic, not
    # some other reason.
    my $tmp = $C->connect('warmup', $S, $route);
    $tmp->disconnect;

    # Open the file, inject a stale entry whose pid is our own running
    # pid.  pid_is_running($$) returns 1 (ours), so init reap-and-
    # replace must NOT engage: the original "already exists" croak
    # must still fire.
    my $state = _state($route);
    $state->{clients}{foreign} = {pid => $$};
    open(my $wfh, '>', $route) or die $!;
    print $wfh IPC::Manager::Serializer::JSON->serialize($state);
    close $wfh;

    like(
        dies { $C->connect('foreign', $S, $route) },
        qr/already exists/,
        'live foreign pid triggers original collision croak',
    );

    $state = _state($route);
    is($state->{clients}{foreign}{pid}, $$, 'foreign entry preserved (not reaped)');

    $C->unspawn($route);
};

done_testing;
