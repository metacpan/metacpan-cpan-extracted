#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

# Multiple connections to different Redis instances, sharing one EV loop.
my @conns;
my $done = 0;

for my $port (6379, 6381, 6382) {
    my $r = EV::Redis->new(
        host     => '127.0.0.1',
        port     => $port,
        on_error => sub { warn "[$port] Error: @_\n" },
    );

    $r->ping(sub {
        my ($res, $err) = @_;
        if ($err) { warn "[$port] PING failed: $err\n" }
        else      { print "[$port] $res\n" }

        $r->disconnect;
        EV::break if ++$done == scalar @conns;
    });

    push @conns, $r;
}

EV::run;
