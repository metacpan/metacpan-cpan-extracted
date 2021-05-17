#!perl

use strict;
use warnings;
use Test::More 0.98;

use vars '$str';
use Log::ger::Output 'String', string => \$str;

package My::P1;
use Log::ger::Plugin 'HashArgs';
use Log::ger;

sub x {
    log(level=>"warn", message=>"warnmsg");
    log(level=>"debug", message=>"debugmsg");
}

package My::P2;
use Log::ger::Plugin 'HashArgs', method_name => 'foo';
use Log::ger ();

my $log = Log::ger->get_logger;
sub x {
    $log->foo(level=>"warn", message=>"warnmsg2");
    $log->foo(level=>"debug", message=>"debugmsg2");
}

package main;

$str = "";
My::P1::x();
is($str, "warnmsg\n");

$str = "";
My::P2::x();
is($str, "warnmsg2\n");

DONE_TESTING:
done_testing;
