#!/usr/bin/env perl
use strict;
use warnings;

# AnyEvent has EV as one of its backends, so EV::Memcached
# works seamlessly in AnyEvent applications.

use AnyEvent;
use EV::Memcached;

$| = 1;

my $cv = AnyEvent->condvar;

my $mc = EV::Memcached->new(
    host     => $ENV{MC_HOST} // '127.0.0.1',
    port     => $ENV{MC_PORT} // 11211,
    on_error => sub { warn "error: @_\n" },
);

$mc->set('anyevent_test', 'it works!', sub {
    my ($res, $err) = @_;
    die "SET: $err" if $err;

    $mc->get('anyevent_test', sub {
        my ($val, $err) = @_;
        die "GET: $err" if $err;

        print "AnyEvent + EV::Memcached: $val\n";
        $mc->disconnect;
        $cv->send;
    });
});

$cv->recv;
