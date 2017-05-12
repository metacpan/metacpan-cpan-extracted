#!/usr/local/bin/perl

use Test::More tests => 3;
BEGIN { use_ok('Loop') };

use warnings;
use strict;

use Data::Dumper;

my %char2mil = qw
	(
	a	alpha
	b	bravo
	c	charlie
	d	delta
	e	echo
	f	foxtrot
	);

my %char2civ = qw
	(
	a	alice
	b	bob
	c	charlie
	d	dave
	e	eve
	f	frank
	);

########################################################################
# use Loop::Hash to iterate through a hash's key/value pairs, and 
# return a map that converts one hash to the other.
########################################################################

my %mil2civ;
   %mil2civ = Loop::Hash %char2mil, sub
	{
	my($char,$mil)=@_;
	my $civ = $char2civ{$char};
	return($mil,$civ);
	};

my %expected_mil2civ = qw
	(
	alpha	alice
	bravo	bob
	charlie	charlie
	echo	eve
	delta	dave
	echo	eve
	foxtrot	frank
	);

is_deeply(\%mil2civ,\%expected_mil2civ,"Loop::Hash, keys, values, and 'map'");

########################################################################
# check for values that also exist as keys in the same hash
# this will test for nested iteration on the same hash
# and can also test non-map'ed calls to Loop::Hash
########################################################################

my @nested;

Loop::Hash %mil2civ, sub
	{
	my($key1,$val1)=@_;

	Loop::Hash %mil2civ, sub
		{
		my($key2,$val2)=@_;
	
		push(@nested,$val1) if($val1 eq $key2);
		}	
	};

my @exp_nested = qw (charlie);

is_deeply(\@nested,\@exp_nested,"Loop::Hash, nested call, no mapping");


