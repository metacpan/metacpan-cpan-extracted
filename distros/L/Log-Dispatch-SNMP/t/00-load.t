#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Log::Dispatch::SNMP' );
}

diag( "Testing Log::Dispatch::SNMP $Log::Dispatch::SNMP::VERSION, Perl $], $^X" );
