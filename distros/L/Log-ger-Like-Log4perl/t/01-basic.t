#!perl

use strict;
use warnings;
use Test::More 0.98;

package My::P1;
use Log::ger::Like::Log4perl;

sub x {
    WARN "w", "ar", sub { "n", "1" };
    DEBUG "debug1";
}

package My::P2;
use Log::ger::Like::Log4perl;

sub x {
    my $log = Log::ger::Like::Log4perl->get_logger;
    $log->log($WARN, "warn", 1+1);
    $log->debug("debug2");
}

package main;

use vars '$str';
use Log::ger::Output;
Log::ger::Output->set('String', string => \$str);

$str = '';
My::P1::x();
My::P2::x();
is($str, "warn1\nwarn2\n");

done_testing;

# XXX test logwarn(), logdie() et al
