#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

my $stream = 'mystream';

# Produce 5 messages
my $produced = 0;
for my $i (1..5) {
    $redis->xadd($stream, '*', 'sensor', "temp_$i", 'value', int(20 + rand 10), sub {
        my ($id, $err) = @_;
        die "XADD failed: $err\n" if $err;
        print "Produced: $id\n";
        $produced++;
    });
}

# After producing, consume them all
$redis->xrange($stream, '-', '+', sub {
    my ($entries, $err) = @_;
    die "XRANGE failed: $err\n" if $err;

    print "\nConsuming $stream (" . scalar(@$entries) . " entries):\n";
    for my $entry (@$entries) {
        my ($id, $fields) = @$entry;
        # fields is a flat array: [key, val, key, val, ...]
        my %data = @$fields;
        printf "  %s  sensor=%s value=%s\n", $id, $data{sensor}, $data{value};
    }

    # Stream length
    $redis->xlen($stream, sub {
        my ($len, $err) = @_;
        print "\nStream length: $len\n";

        # Trim to last 3 entries
        $redis->xtrim($stream, 'MAXLEN', 3, sub {
            my ($trimmed, $err) = @_;
            print "Trimmed $trimmed entries\n";

            # Cleanup
            $redis->del($stream, sub { $redis->disconnect });
        });
    });
});

EV::run;
