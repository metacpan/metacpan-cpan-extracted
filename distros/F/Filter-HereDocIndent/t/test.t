#!/usr/bin/perl -w
use strict;
use Filter::HereDocIndent;

use Test::More;
plan tests => 2;



#------------------------------------------------------------------------------
# test 1: basic filtering
#
do {
my ($var);
my $name = 'basic filtering';

    $var=<<'(MYDOC)';
    a
     b
   c
    (MYDOC)

if ($var eq "a\n b\nc\n")
	{ok 1, $name}
else
	{ok 0, $name}
};
#
# test 1: basic filtering
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# test 2: commented out here doc
#
sub test2 {
	my ($var);
	
	#$var=<<'(XXXX)';
	#a
	#b
	#c

	$var=<<'(MYDOC)';
	a
	b
	c
	(MYDOC)
	
	return $var;
}

do {
	my $name = 'commented out here doc';
	
	if (test2() eq "a\nb\nc\n")
		{ok 1, $name}
	else
		{ok 0, $name}
};
#
# test 2: commented out here doc
#------------------------------------------------------------------------------

