#!/usr/bin/env perl
use strict;
use warnings;

# EV::Redis works seamlessly with AnyEvent when EV is the backend.
use EV;
use AnyEvent;
use EV::Redis;

$| = 1;

my $cv = AE::cv;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

# Reset counter, then start periodic incrementing
$redis->del('ae_counter');
my $w; $w = AE::timer 0, 1, sub {
    $redis->incr('ae_counter', sub {
        my ($val, $err) = @_;
        die "INCR failed: $err\n" if $err;
        print "counter = $val\n";
        if ($val >= 5) {
            undef $w;
            $redis->del('ae_counter');
            $redis->disconnect;
            $cv->send;
        }
    });
};

$cv->recv;
