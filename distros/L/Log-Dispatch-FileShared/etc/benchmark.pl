#!/usr/local/bin/perl -w
use strict;
use Time::HiRes qw(time);
use lib qw(../lib);
use Log::Dispatch::File;
use Log::Dispatch::FileShared;

my $count = 10000;
my $logfile = 'test.log';

{
	# Preload the objects so that any required modules (if any) are loaded.
	Log::Dispatch::File->new(
    	name      => 'test',
    	min_level => 'debug',
    	filename  => $logfile,
	);
	#->log( 'level' => 'debug', 'message' => "Start up.\n" );
	Log::Dispatch::FileShared->new(
    	name      => 'test',
    	min_level => 'debug',
    	filename  => $logfile,
	);
	#->log( 'level' => 'debug', 'message' => "Start up.\n" );
	unlink($logfile);
}


if (1) {
	print "Measuring $count logs of using defaults...\n";
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::FileShared... ";
		my $o = Log::Dispatch::FileShared->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::File...       ";
		my $o = Log::Dispatch::File->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
}



if (1) {
	print "Measuring $count logs of using autoflush=0, flock=0...\n";
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::FileShared... ";
		my $o = Log::Dispatch::FileShared->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
	    	autoflush => 0,
	    	'flock'   => 0,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::File...       ";
		my $o = Log::Dispatch::File->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
	    	autoflush => 0,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
}


if (1) {
	print "Measuring $count logs of using autoflush=1, flock=0...\n";
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::FileShared... ";
		my $o = Log::Dispatch::FileShared->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
	    	autoflush => 1,
	    	'flock'   => 0,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::File...       ";
		my $o = Log::Dispatch::File->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
	    	autoflush => 1,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
}


if (1) {
	print "Measuring $count logs of using flock=1...\n";
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::FileShared... ";
		my $o = Log::Dispatch::FileShared->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::File...       ";
		my $o = Log::Dispatch::File->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
}


if (1) {
	print "Measuring $count logs of using close_after_write=1, flock=0...\n";
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::FileShared... ";
		my $o = Log::Dispatch::FileShared->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
	    	close_after_write => 1,
	    	'flock' => 0,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
	{
		sleep 1; # makes measurements more fair and accurate
		print "\tLog::Dispatch::File...       ";
		my $o = Log::Dispatch::File->new(
	    	name      => 'test',
	    	min_level => 'debug',
	    	filename  => $logfile,
	    	close_after_write => 1,
		);
		my $t0 = time();
		for (my $i=0; $i<$count; $i++) {
			$o->log( 'level' => 'debug', 'message' => "This is a debug message.\n" );
		}
		my $t1 = time();
		printf("%.3f seconds\t(avg %.5f)\n", $t1 - $t0, ($t1 - $t0) / $count);
		unlink($logfile);
	}
}