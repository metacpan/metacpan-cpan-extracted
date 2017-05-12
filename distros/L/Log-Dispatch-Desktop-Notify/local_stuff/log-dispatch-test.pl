#!/usr/bin/perl -I lib
use strict;
use warnings;
use Log::Dispatch;
use Log::Dispatch::Desktop::Notify;

my $log = Log::Dispatch->new();

$log->add(Log::Dispatch::Desktop::Notify->new(
	      min_level => 'info',
	  ));

$log->log( level => 'info', message => "Blah, blah\n" );
