#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Devel::ArgNames';

sub foo { arg_names() }

my ( $bar, $gorch, @blah );

is_deeply(
	[ foo($bar, $gorch, $blah[4]) ],
	[ qw($bar $gorch), undef ],
	"var names",
);


