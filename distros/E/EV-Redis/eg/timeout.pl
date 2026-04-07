#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

# Demonstrate connect and command timeouts.
my $redis = EV::Redis->new(
    host            => '127.0.0.1',
    connect_timeout => 3000,    # 3 second connect timeout
    command_timeout => 5000,    # 5 second command timeout
    on_error        => sub { warn "Error: @_\n" },
    on_connect      => sub { print "Connected\n" },
);

# BLPOP with 2s timeout (within command_timeout)
$redis->blpop('myqueue', 2, sub {
    my ($res, $err) = @_;
    if ($err) {
        warn "BLPOP error: $err\n";
    }
    elsif ($res) {
        print "Got from queue: $res->[0] => $res->[1]\n";
    }
    else {
        print "BLPOP timed out (nil)\n";
    }
    $redis->disconnect;
});

EV::run;
