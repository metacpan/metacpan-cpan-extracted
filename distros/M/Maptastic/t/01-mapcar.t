#!/usr/bin/perl -w

use strict 'vars', 'subs';
use Test::More tests => 6;

BEGIN { use_ok("Maptastic", ":perly"); }

ok(defined(${main::}{map_shift}), "import worked");
ok(!defined(${main::}{mapcar}), "import w/tags worked");

my @a = (1, 2, 3);
my @b = qw(Mary Jane);
my @c = ('A' .. 'E');
my %d = ( smokey => 1,
	  cheese => 6,
	  fire   => 7,
	  plant  => 3.5 );

my @spliced = map_shift { [ @_ ] } \@a, \@b, \@c;

is_deeply(\@spliced, [ [1,     "Mary", "A"],
		       [2,     "Jane", "B"],
		       [3,     undef,  "C"],
		       [undef, undef,  "D"],
		       [undef, undef,  "E"] ],
	  "map_shift");

my @mixed  = map_for { [ @_ ] } \@a, \@b, \@c;

is_deeply(\@mixed, [ [1,     "Mary", "A"],
		     [2,     "Jane", "B"],
		     [3,             "C"],
		     [               "D"],
		     [               "E"],
		   ],
	  "map_for");

my %hashed = map_each { ( $_[1] > 4 ? @_ : () ) } \%d;

is_deeply(\%hashed, { cheese => 6,
		      fire   => 7 },
	  "map_each");

