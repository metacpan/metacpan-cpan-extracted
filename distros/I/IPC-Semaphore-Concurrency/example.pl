#!/usr/bin/perl
#
# example.pl - Limiting process concurrency using IPC::Semaphore::Concurrency
#
# Author: Thomas Guyot-Sionnest <tguyot@gmail.com>
#
# This in a perl example of using semaphores to limit concurrent processes
# doing a specific task.
#
# This code is released to the public domain.
#

use strict;
use warnings;
use IPC::Semaphore::Concurrency;
use Errno;
use vars qw($sem_path_name $sem_max);

# Semaphore pathname for key generation (will be created if missing)
$sem_path_name = '/tmp/sem_test_5a76';
# Max concurrency - also used as semaphore proj_id
$sem_max = 4;

my $sem = IPC::Semaphore::Concurrency->new(
	path    => $sem_path_name,
	project => $sem_max,
	value   => $sem_max,
	);
if (@ARGV > 0 && $ARGV[0] eq 'reset') {
	$sem->remove();
	exit;
}

print "begin val: ".$sem->getval(0)."\n";
if ($sem->acquire(0, 0, 0, 1)) {
	print "Do work\n";
	sleep 10;
} elsif ($!{EWOULDBLOCK}) {
	print "Pass your turn\n";
} else {
	die("Unexpected Error: $!");
}

print "end val: ".$sem->getval(0)."\n"; # Value will be re-incremented as soon as the process exits

