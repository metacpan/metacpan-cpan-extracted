use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Memcached;

eval { require Devel::Refcount };
if ($@) { plan skip_all => "Devel::Refcount not available" }

my $host = $ENV{TEST_MEMCACHED_HOST} || '127.0.0.1';
my $port = $ENV{TEST_MEMCACHED_PORT} || 11211;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
unless ($sock) { plan skip_all => "No memcached at $host:$port" }
close $sock;

sub run_ev {
    my $t = EV::timer 5, 0, sub { fail("timeout"); EV::break };
    EV::run;
}

# --- basic lifecycle: no leak ---
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub {},
    );
    $mc->on_connect(sub { EV::break });
    run_ev();

    is(Devel::Refcount::refcount($mc), 1, "refcount after connect: 1");

    $mc->set("leak_test", "val", sub {
        $mc->get("leak_test", sub {
            EV::break;
        });
    });
    run_ev();

    is(Devel::Refcount::refcount($mc), 1, "refcount after commands: 1");

    $mc->disconnect;
}

# --- connect/disconnect cycle: no leak ---
{
    for my $i (1..5) {
        my $mc = EV::Memcached->new(
            host => $host, port => $port,
            on_error => sub {},
        );
        $mc->on_connect(sub {
            $mc->set("cycle_$i", "v", sub {
                $mc->disconnect;
                EV::break;
            });
        });
        run_ev();
    }
    pass("5 connect/disconnect cycles without crash");
}

# --- mget lifecycle ---
{
    my $mc = EV::Memcached->new(
        host => $host, port => $port,
        on_error => sub {},
    );
    $mc->on_connect(sub { EV::break });
    run_ev();

    $mc->set("ml_1", "a");
    $mc->set("ml_2", "b");
    $mc->noop(sub {
        $mc->mget(["ml_1", "ml_2", "ml_3"], sub {
            my ($results, $err) = @_;
            is(scalar keys %$results, 2, "mget: 2 hits");
            is(Devel::Refcount::refcount($mc), 1, "refcount after mget: 1");
            $mc->disconnect;
            EV::break;
        });
    });
    run_ev();
}

done_testing;
