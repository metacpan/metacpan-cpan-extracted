#!/usr/bin/perl

# Ensure that we don't prematurely END-time delete due to forking

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use File::Spec::Functions ':ALL';
use File::Remove ();

# Create a directory
my $parent = catdir( 't', '09_fork_parent' );
my $child  = catdir( 't', '09_fork_child'  );
File::Remove::clear($parent);
File::Remove::remove($child);
ok( ! -d $parent, 'Parent directory does not exist' );
ok( ! -d $child,  'Child directory does not exist'  );
ok( mkdir( $parent, 0777 ), 'Created directory' );
ok( -d $parent, 'Directory exists' );

# Fork the test
my $pid = fork();
unless ( $pid ) {
	# Create a child-owned directory and flag for deletion
	File::Remove::clear($child);
	mkdir( $child, 0777 );
	sleep(2);

	# Exit from the child to stimulate END-time code
	exit(0);
}

# In the parent, wait 1 second for process to spawn
# and create the child directory
sleep(1);
ok( -d $child, 'Child directory created (by forked child)' );

# Wait for the child to exit
my $caught = wait();
is( $pid, $caught, 'The child exited' );
sleep(1); # Give a chance for flakey windows to delete directory
ok( -d $parent, 'Parent directory still exists' );
ok( ! -d $child, 'Child directory is removed' );
