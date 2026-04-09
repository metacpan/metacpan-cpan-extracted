#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# SET with expiry (cache pattern)
print "Setting keys with TTL...\n";

$redis->setex('session:abc', 5, 'user_42', sub {
    my ($res, $err) = @_;
    print "  session:abc  TTL=5s  -> $res\n";
});

$redis->set('cache:page', 'html_content', 'EX', 10, sub {
    my ($res, $err) = @_;
    print "  cache:page   TTL=10s -> $res\n";
});

# SET with NX (only if not exists)
$redis->set('lock:job1', 'worker_1', 'NX', 'EX', 3, sub {
    my ($res, $err) = @_;
    printf "  lock:job1    NX      -> %s\n", $res // '(nil, already locked)';

    # Try again — should fail (already set)
    $redis->set('lock:job1', 'worker_2', 'NX', 'EX', 3, sub {
        my ($res, $err) = @_;
        printf "  lock:job1    NX 2nd  -> %s\n", $res // '(nil, already locked)';
    });
});

# Check TTLs after a delay
my $w; $w = EV::timer 2, 0, sub {
    undef $w;
    print "\nAfter 2 seconds:\n";

    my $done = 0;
    my $total = 3;
    for my $key (qw(session:abc cache:page lock:job1)) {
        $redis->ttl($key, sub {
            my ($ttl, $err) = @_;
            printf "  %-14s TTL=%ds\n", $key, $ttl;

            if (++$done == $total) {
                # Cleanup
                $redis->del('session:abc', 'cache:page', 'lock:job1',
                    sub { $redis->disconnect });
            }
        });
    }
};

EV::run;
