#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 2;

## Check module loads ok
our $module ;
BEGIN { 
	$module = 'Linux::DVB::DVBT::Apps::QuartzPVR' ;
	use_ok($module) 
};

my @exported = qw/
	new
	show_info
	process
	update
/ ;

	can_ok($module, @exported) ;
	

