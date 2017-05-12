#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use Test::More tests => 4;

use_ok('File::Find::Match', qw( MATCH IGNORE ));
require_ok('File::Find::Match');

my $finder = new File::Find::Match;

isa_ok($finder, 'File::Find::Match');
can_ok($finder,
	qw(
		new
		find
	)
);


