#!perl -T

use Test::More tests => 3;

use lib qw{ lib };

BEGIN {
	use_ok( 'LedgerSMB::API' );
	use_ok( 'LedgerSMB::API::OSCommerce' );
	use_ok( 'LedgerSMB::API::OSCommerce::HomeChip' );
}

diag( "Testing LedgerSMB::API $LedgerSMB::API::VERSION, Perl $], $^X" );
