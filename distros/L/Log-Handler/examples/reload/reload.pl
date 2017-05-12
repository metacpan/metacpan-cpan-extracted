#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Log::Handler;

my $log = Log::Handler->new();

$log->config(config => "logger1.conf");
$log->warning("foo");
$log->info("foo");

print "--------------------------------------\n";

$log->reload(config => "logger2.conf") or die $log->errstr;
$log->warning("bar");
$log->info("bar");
