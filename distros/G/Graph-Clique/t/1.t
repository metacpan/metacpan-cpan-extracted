#!/usr/bin/perl
use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use Test::More tests => 1;


use Test::More qw(no_plan);
use_ok('Graph::Clique', qw(getcliques));
#BEGIN { use_ok('Graph::Clique'), qw(getcliques) };
#require_ok( 'Graph::Clique' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %tests = (
	 Clique =>  [
			[1,2], [1,3], [1,4], [1,5],
			[2,3], [2,4],
			[3,4],
			[5,6], [5,7], [5,9],
			[6,9],
			[7,8],
			[8,9],
		    ]
);

#use_ok('Graph::Clique', qw(getcliques)); 
can_ok('Graph::Clique', qw(getcliques));

#is_deeply(getcliques(), $tests{Clique});
