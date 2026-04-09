#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

my $lb = 'leaderboard';

# Add players with scores
my @players = (
    [1500, 'alice'],
    [2300, 'bob'],
    [1800, 'carol'],
    [3100, 'dave'],
    [2750, 'eve'],
    [1200, 'frank'],
);

my $added = 0;
for my $p (@players) {
    $redis->zadd($lb, $p->[0], $p->[1], sub {
        if (++$added == @players) {
            show_leaderboard();
        }
    });
}

sub show_leaderboard {
    # Top 3 (highest scores first)
    $redis->zrevrange($lb, 0, 2, 'WITHSCORES', sub {
        my ($res, $err) = @_;
        die "ZREVRANGE failed: $err\n" if $err;

        print "=== Top 3 ===\n";
        for (my $i = 0; $i < @$res; $i += 2) {
            printf "  #%d  %-10s %s pts\n", $i/2 + 1, $res->[$i], $res->[$i+1];
        }

        # Player rank and score
        $redis->zrevrank($lb, 'carol', sub {
            my ($rank, $err) = @_;
            $redis->zscore($lb, 'carol', sub {
                my ($score, $err) = @_;
                printf "\nCarol: rank #%d, %s pts\n", $rank + 1, $score;

                # Players with score 1500-2500
                $redis->zrangebyscore($lb, 1500, 2500, 'WITHSCORES', sub {
                    my ($res, $err) = @_;
                    print "\nPlayers with 1500-2500 pts:\n";
                    for (my $i = 0; $i < @$res; $i += 2) {
                        printf "  %-10s %s pts\n", $res->[$i], $res->[$i+1];
                    }
                    $redis->del($lb, sub { $redis->disconnect });
                });
            });
        });
    });
}

EV::run;
