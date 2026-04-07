#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

my $redis = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Redis error: @_\n" },
);

$redis->set(greeting => 'Hello, world!', sub {
    my ($res, $err) = @_;
    die "SET failed: $err" if $err;

    $redis->get('greeting', sub {
        my ($res, $err) = @_;
        die "GET failed: $err" if $err;

        print "Got: $res\n";
        $redis->disconnect;
    });
});

EV::run;
