#!/usr/bin/perl
use strict;
use warnings;
use Log::Any qw{$log};
use Log::Any::Adapter;

@ARGV or die "...try giving me something to log, eh?\n";

Log::Any::Adapter->set('Syslog');

print "debugging log messages are enabled.\n" if $log->is_debug;
$log->debug(@ARGV);
