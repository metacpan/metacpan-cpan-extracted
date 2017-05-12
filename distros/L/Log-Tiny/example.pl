#!/usr/bin/perl

use warnings;
use strict;
use lib 'lib';
use Log::Tiny;

my $log = Log::Tiny->new('example.log', '%F %P %S (%-5c) %m%n') or die 'Could not log! (' . Log::Tiny->errstr . ')';
my ($warn, $error, $trace, $debug) = (0, 0, 0, 0);
$log->DEBUG("Starting...");
$debug++;
foreach ( 1 .. 5 ) {
    $log->WARN( ++$warn );
    $log->TRACE( ++$trace );
}
$log->DEBUG("Finishing...");
$debug++;

print "debug $debug, warn $warn, trace $trace, error $error\n";

