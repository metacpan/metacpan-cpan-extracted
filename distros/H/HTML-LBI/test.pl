#!/usr/bin/perl  
#############################################################
#  HTML::LBI
#  Whyte.Wolf DreamWeaver Library Module
#  Copyright (c) 2002 by S.D. Campbell <whytwolf@spots.ab.ca>
#
#  Last modified 06/03/2002
#
#  Test scripts to test that the HTML::DWT module has been
#  installed correctly.  See Test::More for more information.
#
#############################################################

use Carp;
use Test::More tests => 5;

#  Check to see if we can use and/or require the module

BEGIN { 
	use_ok('HTML::LBI');
	}
	
require_ok('HTML::LBI');

#  Create a new HTML::LBI object and test to see if it's a 
#  properly blessed reference.  Die if the file isn't found.

my $l = new HTML::LBI(filename => 'tmp/left.lbi') or die $HTML::DWT::errmsg;
is(defined($l), 1, 'PASSED: filename => absolute path');

my $l2 = new HTML::LBI(filename => 'left.lbi',
			path => './') or die $HTML::DWT::errmsg;
is(defined($l2), 1, 'PASSED: filename => relative path');

my $l3 = new HTML::LBI('tmp/left.lbi') or die $HTML::DWT::errmsg;
is(defined($l3), 1, 'PASSED: constructor w/ path');
