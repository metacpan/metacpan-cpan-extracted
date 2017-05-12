#!/usr/bin/perl 

use strict;
use warnings;
use Test::More tests => 1;
use List::EvenMoreUtils qw(do_sublist);

my @list = (
	{
		k	=> 7,
		v	=> 'd',
	},
	{
		k	=> 8,
		v	=> 'm',
	},
	{
		k	=> 7,
		v	=> 'o',
	},
	{
		k	=> 8,
		v	=> 'e',
	},
	{
		k	=> 8,
		v	=> 'a',
	},
	{
		k	=> 7,
		v	=> 'g',
	},
	{
		k	=> 8,
		v	=> 't',
	},
);

my @w = do_sublist( sub { $_->{k} }, sub { join('', map { $_->{v} } @_) }, @list);

is("@w", 'dog meat', 'do_sublists works');

