#!perl

use strict;
use warnings;
use Test::More 0.98;
use Test::Warn;

package My::P1;
use Log::ger::Plugin 'WithWarn';
use Log::ger;

sub x1 {
    log_warn_warn("foo");
}

sub x2 {
    my $log = Log::ger->get_logger;
    $log->warn_warn("bar");
}

package main;

use vars '$str';
use Log::ger::Output;
Log::ger::Output->set('String', string => \$str);

$str = '';
warning_like { My::P1::x1() } qr/foo/;
warning_like { My::P1::x2() } qr/bar/;
is($str, "foo\nbar\n");

done_testing;
