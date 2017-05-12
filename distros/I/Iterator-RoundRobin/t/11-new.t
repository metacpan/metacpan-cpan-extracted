#! /usr/bin/perl

use Test::More tests => 3;

use_ok( 'Iterator::RoundRobin' );

my ($fb);

{
	$fb = Iterator::RoundRobin->new([qw/perl python ruby/], [qw/c c++ c-sharp/]);
	ok($fb, 'Iterator::RoundRobin object created');
	isa_ok($fb, 'Iterator::RoundRobin', 'Iterator::RoundRobin object created');
}

