#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

package My::P1;
use Log::ger::Plugin 'WithDie';
use Log::ger;

sub x1a {
    log_error_die("foo");
}

sub x1b {
    log_fatal_die("bar");
}

sub x2a {
    my $log = Log::ger->get_logger;
    $log->error_die("baz");
}

sub x2b {
    my $log = Log::ger->get_logger;
    $log->fatal_die("qux");
}

package main;

dies_ok { My::P1::x1a() } qr/foo/;
dies_ok { My::P1::x1b() } qr/bar/;
dies_ok { My::P1::x2a() } qr/baz/;
dies_ok { My::P1::x2b() } qr/qux/;

done_testing;
