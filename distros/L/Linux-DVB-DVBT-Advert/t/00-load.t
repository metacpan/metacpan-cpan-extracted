#!perl
use strict ;

use Test::More tests => 1;

my $mod ;

BEGIN {
	$mod = 'Linux::DVB::DVBT::Advert' ;
	use_ok( "$mod" );
}

no strict "refs";
my $ver ;
eval "\$ver = \$$mod"."::VERSION" ;
diag( "Testing $mod $ver, Perl $], $^X" );
