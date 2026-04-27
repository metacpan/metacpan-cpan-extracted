use Test2::V0;
use Test2::Require::Module 'Atomic::Pipe' => '0.026';

use Atomic::Pipe;
use IPC::Manager::Client::AtomicPipe;

# We need a pid that is guaranteed NOT to be running.  Fork a child that
# exits immediately and waitpid() it so its pid becomes a zombie-reaped
# (i.e. fully gone) pid.  kill(0, $dead_pid) should then fail with ESRCH.
sub dead_pid {
    my $pid = fork;
    defined $pid or die "fork: $!";
    if ($pid == 0) { exit 0 }
    waitpid($pid, 0);

    # Sanity: kill(0, $pid) should now return false.
    if (kill(0, $pid)) {
        skip_all("Could not obtain a dead pid for testing (kill(0, $pid) still true)");
    }
    return $pid;
}

subtest 'peer_left sweeps reassembly state entries whose pid is gone' => sub {
    my $dead_pid = dead_pid();
    my $live_pid = $$;

    # Bypass init — we only need to exercise peer_left / the sweep helper.
    my $client = bless {}, 'IPC::Manager::Client::AtomicPipe';

    # Fake the Atomic::Pipe internals just enough to hold reassembly state.
    my $pipe = {
        Atomic::Pipe::STATE() => {
            parts => {
                "${dead_pid}:0" => [2, 1],
                "${live_pid}:0" => [0],
            },
            buffers => {
                "${dead_pid}:0" => "partial dead message",
                "${live_pid}:0" => "partial live message",
            },
        },
    };
    bless $pipe, 'Atomic::Pipe';
    $client->{pipe} = $pipe;

    my $removed = $client->peer_left('whoever');

    is($removed, 1, "one orphaned tag removed");

    my $state = $pipe->{Atomic::Pipe::STATE()};
    ok(!exists $state->{parts}->{"${dead_pid}:0"},   "dead pid parts entry gone");
    ok(!exists $state->{buffers}->{"${dead_pid}:0"}, "dead pid buffer entry gone");
    ok( exists $state->{parts}->{"${live_pid}:0"},   "live pid parts entry preserved");
    ok( exists $state->{buffers}->{"${live_pid}:0"}, "live pid buffer entry preserved");
};

subtest 'peer_left is a no-op when there is no pipe or state' => sub {
    my $client = bless {}, 'IPC::Manager::Client::AtomicPipe';
    is($client->peer_left('anyone'), 0, "returns 0 when there is no pipe");

    my $pipe = bless {}, 'Atomic::Pipe';
    $client->{pipe} = $pipe;
    is($client->peer_left('anyone'), 0, "returns 0 when there is no state");
};

subtest 'base Client peer_left is a no-op' => sub {
    require IPC::Manager::Client;
    my $noop = bless {}, 'IPC::Manager::Client';
    ok(defined(&IPC::Manager::Client::peer_left), "peer_left is defined on base Client");
    ok(!eval { $noop->peer_left('x'); 1 } ? 0 : 1, "base peer_left does not throw");
};

done_testing;
