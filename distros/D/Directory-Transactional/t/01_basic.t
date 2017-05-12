#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use ok 'Directory::Transactional'; # force Moose to load Moose by running before Test::TempDir

use Test::TempDir qw(temp_root);

my $work;

{
	alarm 5;
	my $d = Directory::Transactional->new( root => temp_root );
	alarm 0;

	isa_ok( $d, "Directory::Transactional" );

	$work = $d->_work;

	ok( -d $work, "work dir created" );

}

ok( not( -d $work ), "work dir removed" );

done_testing;
