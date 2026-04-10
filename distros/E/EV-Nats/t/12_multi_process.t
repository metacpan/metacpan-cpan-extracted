use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use POSIX qw(_exit);
use EV;
use EV::Nats;

my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
my $port = $ENV{TEST_NATS_PORT} || 4222;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => 1,
);
unless ($sock) {
    plan skip_all => "NATS server not available at $host:$port";
}
close $sock;

plan tests => 4;

my $n_msgs    = 50;
my $n_workers = 3;

# Spawn worker processes that subscribe and count messages
my @pids;
my @pipes;

for my $w (1 .. $n_workers) {
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # Child: subscribe, count messages, report count via pipe
        close $rd;
        my $count = 0;
        my $nats;
        $nats = EV::Nats->new(
            host     => $host,
            port     => $port,
            on_error => sub { warn "worker $w: @_\n" },
            on_connect => sub {
                $nats->subscribe('mp.fanout', sub { $count++ });
                $nats->subscribe('mp.queue', sub { $count++ }, 'workers');
            },
        );
        my $guard = EV::timer 8, 0, sub {
            $nats->disconnect;
            EV::break;
        };
        EV::run;
        print $wr "$count\n";
        close $wr;
        _exit(0);
    }

    close $wr;
    push @pids, $pid;
    push @pipes, $rd;
}

# Parent: wait for workers to connect, then publish
sleep 1;

my $pub;
$pub = EV::Nats->new(
    host     => $host,
    port     => $port,
    on_error => sub { die "pub: @_\n" },
    on_connect => sub {
        # fanout: each worker gets every message
        $pub->publish("mp.fanout", "fan-$_") for 1 .. $n_msgs;
        # queue: only one worker per message
        $pub->publish("mp.queue", "q-$_") for 1 .. $n_msgs;
        # flush then disconnect after a beat
        my $t; $t = EV::timer 2, 0, sub {
            undef $t;
            $pub->disconnect;
            EV::break;
        };
    },
);
EV::run;

# Collect results from workers
my @counts;
for my $i (0 .. $#pids) {
    waitpid $pids[$i], 0;
    my $rd = $pipes[$i];
    my $line = <$rd>;
    close $rd;
    chomp $line if defined $line;
    push @counts, ($line // 0) + 0;
}

# Each worker should get all fanout messages
my $total_fanout = 0;
my $total_queue  = 0;

for my $c (@counts) {
    # Each worker got at least $n_msgs (fanout) messages
    $total_fanout += $n_msgs if $c >= $n_msgs;
    $total_queue  += $c - $n_msgs if $c > $n_msgs;
}

# Fanout: all workers got all messages
is $total_fanout, $n_msgs * $n_workers,
    "fanout: all $n_workers workers received $n_msgs msgs each";

# Queue: total across workers = $n_msgs (load balanced)
is $total_queue, $n_msgs,
    "queue: total across workers = $n_msgs";

# Queue: no single worker got all queue messages (load balanced)
my @queue_counts = map { $_ - $n_msgs } grep { $_ > $n_msgs } @counts;
my $max_queue = @queue_counts ? (sort { $b <=> $a } @queue_counts)[0] : 0;
ok $max_queue < $n_msgs, "queue: load balanced (max worker got $max_queue/$n_msgs)";

# All workers exited cleanly
ok scalar(@counts) == $n_workers, "all $n_workers workers reported back";
