#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Log::Syslog::Abstract' );
}

diag( "Testing Log::Syslog::Abstract $Log::Syslog::Abstract::VERSION, Perl $], $^X" );
