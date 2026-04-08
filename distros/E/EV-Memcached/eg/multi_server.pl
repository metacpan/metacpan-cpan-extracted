#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

# Multiple memcached connections with consistent key routing.
# Each key is hashed to a server index (simple modulo sharding).

my @servers = (
    { host => $ENV{MC_HOST} // '127.0.0.1',
      port => $ENV{MC_PORT} // 11211 },
    # Add more servers:
    # { host => '127.0.0.1', port => 11212 },
    # { host => '127.0.0.1', port => 11213 },
);

my @conns;
my $connected = 0;

for my $srv (@servers) {
    my $mc = EV::Memcached->new(
        host       => $srv->{host},
        port       => $srv->{port},
        on_error   => sub { warn "[$srv->{host}:$srv->{port}] @_\n" },
        on_connect => sub {
            printf "Connected to %s:%d\n", $srv->{host}, $srv->{port};
            if (++$connected == scalar @servers) {
                do_work();
            }
        },
    );
    push @conns, $mc;
}

sub route {
    my ($key) = @_;
    # Simple hash-based routing
    my $hash = 0;
    $hash = $hash * 31 + ord for split //, $key;
    return $conns[$hash % scalar @conns];
}

sub do_work {
    my $done = 0;
    my $total = 20;

    # Distribute keys across servers
    for my $i (1..$total) {
        my $key = "shard:item:$i";
        my $mc = route($key);

        $mc->set($key, "value_$i", sub {
            my ($res, $err) = @_;
            warn "SET $key: $err\n" if $err;

            # Read back from the correct server
            my $mc2 = route($key);
            $mc2->get($key, sub {
                my ($val, $err) = @_;
                if (++$done == $total) {
                    printf "Distributed %d keys across %d server(s)\n",
                        $total, scalar @servers;
                    $_->disconnect for @conns;
                }
            });
        });
    }
}

EV::run;
