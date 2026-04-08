#!/usr/bin/env perl
use strict;
use warnings;
use EV::Memcached;

$| = 1;

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "memcached error: @_\n" },
);

$mc->set(greeting => 'Hello, world!', sub {
    my ($res, $err) = @_;
    die "SET failed: $err" if $err;
    print "SET ok\n";

    $mc->get('greeting', sub {
        my ($val, $err) = @_;
        die "GET failed: $err" if $err;

        print "GET greeting = $val\n";
        $mc->disconnect;
    });
});

EV::run;
