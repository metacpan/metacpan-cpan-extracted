#! /usr/bin/perl
# $Id: 20_mutex.t,v 1.5 2010/03/02 23:22:47 dk Exp $

alarm(10);

use strict;
use warnings;
use Test::More;
use IO::Lambda qw(:lambda);
use IO::Lambda::Mutex;

plan tests => 19;

# basic stuff
my $mutex = IO::Lambda::Mutex-> new;
ok( $mutex-> is_free, 'new mutex is free');

$mutex-> take;
ok( $mutex-> is_taken, 'new mutex is taken');
$mutex-> release;
ok( $mutex-> is_free, 'new mutex is free again');

# wait for mutex that shall be available immediately
my $waiter = $mutex-> waiter;
my $error = $waiter-> wait;
ok( not(defined $error), 'immediate wait ok');
ok( $mutex-> is_taken, 'awaited mutex is taken');
$mutex-> release;
ok( $mutex-> is_free, 'awaited mutex is free again');

# wait for blocked mutex
$mutex-> take;
$waiter = $mutex-> waiter;
my $flag = 0;
my $sleeper = lambda {
	context 0.2;
	timeout {
		$flag++;
		$mutex-> release;
	}
};
$sleeper-> start;
$error = $waiter-> wait;
ok( not(defined $error) && $flag == 1, 'unconditional wait ok');
ok( $mutex-> is_taken, 'awaited mutex is taken');
$mutex->release;
ok( $mutex-> is_free, 'awaited mutex is 0-queued and free');

# wait for blocked mutex with a timeout
$mutex-> take;
$waiter = $mutex-> waiter(0.001);
$flag = 0;
$sleeper-> reset;
$sleeper-> start;
$error = $waiter-> wait;
ok( defined($error) && $error eq 'timeout', 'conditional wait ok - timeout');
ok( $mutex-> is_taken, 'timeouted mutex is taken');

$waiter = $mutex-> waiter(1);
$error = $waiter-> wait;
ok( not(defined $error), 'conditional wait ok - no timeout');
ok( $mutex-> is_taken, 'non-timeouted mutex is taken');
$mutex->release;
ok( $mutex-> is_free, 'awaited mutex is 0-queued and free');

# deadlock prevention
$mutex-> take;
$waiter = $mutex-> waiter;
$waiter-> terminate;
$mutex-> release;
ok( $mutex-> is_free, 'deadlock prevention 1');

$mutex-> take;
$waiter = $mutex-> waiter;
$mutex-> remove($waiter);
$waiter-> terminate;
ok( $mutex-> is_taken, 'mutex is taken');
$mutex->release;
ok( $mutex-> is_free, 'deadlock prevention 2');

$flag = '';
lambda {
	context 
		$mutex-> pipeline( lambda { $flag .= 1 } ),
		$mutex-> pipeline( lambda { $flag .= 2 } ),
		$mutex-> pipeline( lambda { $flag .= 3 } )
		;
	&tails();
}-> wait;
ok( $flag == 123, 'pipeline');

$flag = '';
lambda {
	context $mutex-> pipeline( lambda { 
		$flag .= 1;
		context 0.2;
		timeout { };
	});
	tail {};
	
	context $mutex-> pipeline( lambda { 
		$flag .= 2;
	});
	tail {};
}-> wait;
ok( $flag == 12, 'pipeline: trying to get in queue before another lambda');
