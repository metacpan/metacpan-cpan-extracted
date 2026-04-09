#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# Populate test keys
my $total = 50;
my $set = 0;
for my $i (1..$total) {
    my $prefix = $i % 3 == 0 ? 'user' : $i % 3 == 1 ? 'order' : 'session';
    $redis->set("scan:$prefix:$i", "val_$i", sub {
        start_scan() if ++$set == $total;
    });
}

sub start_scan {
    print "Scanning for 'scan:user:*' keys...\n\n";
    my @found;
    scan_iter(0, \@found);
}

sub scan_iter {
    my ($cursor, $found) = @_;

    $redis->scan($cursor, 'MATCH', 'scan:user:*', 'COUNT', 100, sub {
        my ($res, $err) = @_;
        die "SCAN failed: $err\n" if $err;

        my ($next_cursor, $keys) = @$res;
        push @$found, @$keys;

        printf "  cursor=%s  batch=%d  total_found=%d\n",
            $next_cursor, scalar @$keys, scalar @$found;

        if ($next_cursor == 0) {
            # Iteration complete
            print "\nFound " . scalar(@$found) . " user keys:\n";
            for my $k (sort @$found) {
                print "  $k\n";
            }
            cleanup();
        }
        else {
            scan_iter($next_cursor, $found);
        }
    });
}

sub cleanup {
    print "\nCleaning up...\n";
    $redis->keys('scan:*', sub {
        my ($keys, $err) = @_;
        my $n = scalar @$keys;
        my $d = 0;
        for my $k (@$keys) {
            $redis->del($k, sub { $redis->disconnect if ++$d == $n });
        }
    });
}

EV::run;
