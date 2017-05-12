#!/usr/bin/perl

use Test::More tests => 2;
use vars qw/$pkg/;

BEGIN { 
	$pkg = 'Filter::Include';
	# no. 1
	use_ok($pkg);
}

use strict;

# no. 2
ok($pkg->VERSION > 0,	'version number set');
