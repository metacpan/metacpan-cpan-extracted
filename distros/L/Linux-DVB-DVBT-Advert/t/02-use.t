#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 4;

## Check module loads ok
our $module ;
BEGIN { 
	$module = 'Linux::DVB::DVBT::Advert' ;
	use_ok($module) 
};
BEGIN { 
	use_ok('Linux::DVB::DVBT::Advert::Config') 
};
BEGIN { 
	use_ok('Linux::DVB::DVBT::Advert::Constants') 
};

my @exported = qw/
	ad_config
	ad_debug
	detect
	detect_from_file
	analyse
	ad_cut
	ad_split
	ok_to_detect
/ ;

	can_ok($module, @exported) ;
	

