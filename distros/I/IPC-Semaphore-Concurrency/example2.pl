#!/usr/bin/perl
#
# example2.pl - Limiting process concurrency using IPC::Semaphore::Concurrency
#
# Author: Thomas Guyot-Sionnest <tguyot@gmail.com>
#
# This in a perl example of using semaphores to limit concurrent processes
# doing a specific task and queue them up.
#
# This code is released to the public domain.
#

use strict;
use warnings;
use IPC::Semaphore::Concurrency;
use Errno;
use vars qw($sem_path_name $sem_max $max_queue);

# Semaphore pathname for key generation (will be created if missing)
$sem_path_name = '/tmp/sem_test_b0c2';
# Max concurrency - also used as semaphore proj_id
$sem_max = 1;
# Max number of queued processes (-1 eq infinite)
$max_queue = 1;

my $sem = IPC::Semaphore::Concurrency->new(
	path     => $sem_path_name,
	project  => $sem_max,
	value    => $sem_max,
	) or die("Failed to create semaphore: $!");
if (@ARGV > 0 && $ARGV[0] eq 'reset') {
	$sem->remove();
	exit;
}

print "\nbegin val: ".$sem->getval(0)."\n";

if ((my $res = $sem->acquire(
	                sem  => 0,
	                wait => 1,
	                max  => $max_queue,
	                undo => 1,
	                ))) {
	print "Do work\n";
	sleep 10;
} elsif ($!{EWOULDBLOCK}) {
	print "Too many jobs queued up ($max_queue)!\n";
} else {
	die("Unexpected Error: $!");
}

print "\nend val: ".$sem->getval(0)."\n"; # Value will be re-incremented as soon as the process exits

