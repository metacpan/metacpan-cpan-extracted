#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# HyperLogLog: estimate unique visitors per day
my $today     = 'visitors:2026-04-08';
my $yesterday = 'visitors:2026-04-07';

# Simulate visits (some users visit both days)
my @today_users     = map { "user_$_" } (1..500, 300..700);
my @yesterday_users = map { "user_$_" } (200..600);

my $done = 0;
my $total = 2;

# Bulk add with fire-and-forget, final PFADD with callback
for my $u (@today_users[0..$#today_users-1]) {
    $redis->pfadd($today, $u);
}
$redis->pfadd($today, $today_users[-1], sub {
    check_done() if ++$done == $total;
});

for my $u (@yesterday_users[0..$#yesterday_users-1]) {
    $redis->pfadd($yesterday, $u);
}
$redis->pfadd($yesterday, $yesterday_users[-1], sub {
    check_done() if ++$done == $total;
});

sub check_done {
    $redis->pfcount($today, sub {
        my ($count, $err) = @_;
        print "Today's unique visitors:     ~$count (actual: 700)\n";

        $redis->pfcount($yesterday, sub {
            my ($count, $err) = @_;
            print "Yesterday's unique visitors: ~$count (actual: 401)\n";

            # Merge both days for total uniques
            $redis->pfmerge('visitors:both', $today, $yesterday, sub {
                $redis->pfcount('visitors:both', sub {
                    my ($count, $err) = @_;
                    print "Combined unique visitors:    ~$count (actual: 700)\n";
                    $redis->del($today, $yesterday, 'visitors:both',
                        sub { $redis->disconnect });
                });
            });
        });
    });
}

EV::run;
