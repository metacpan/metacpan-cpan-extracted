#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 2;

## Check module loads ok
our $module ;
BEGIN { 
	$module = 'Linux::DVB::DVBT::TS' ;
	use_ok($module) 
};

my @exported = qw/
	error_str
	info
	parse
	parse_stop
	repair
	ts_cut
	ts_split
/ ;

	can_ok($module, @exported) ;
	

