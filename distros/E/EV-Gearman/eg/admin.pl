#!/usr/bin/perl
# Issue admin commands over the same connection.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

my $remaining = 3;
my $finish = sub { $remaining--; EV::break if $remaining == 0 };

$g->server_version(sub {
    print "version: $_[0]\n";
    $finish->();
});

$g->server_status(sub {
    print "=== status ===\n$_[0]\n";
    $finish->();
});

$g->server_workers(sub {
    print "=== workers ===\n$_[0]\n";
    $finish->();
});

EV::run;
