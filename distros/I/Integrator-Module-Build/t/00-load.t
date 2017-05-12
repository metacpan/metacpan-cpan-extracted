#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Integrator::Module::Build' );
}

diag( "Testing Integrator::Module::Build $Integrator::Module::Build::VERSION, Perl $], $^X" );
