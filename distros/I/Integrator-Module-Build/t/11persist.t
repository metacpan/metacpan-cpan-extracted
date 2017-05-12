#!/usr/bin/perl

#######################################################################################################################
use Test::More tests => 1;
#######################################################################################################################
# This is the second persistence test file.
# So in here we just add one variable and test for presence.
# In a third file, we will look for persistence

use Integrator::Module::Build;
my $build = Integrator::Module::Build->current;

SKIP: {
	skip 'not in development mode' , 1;

$build->config_data( 'cafe' => 'take another one' );
is ( $build->config_data( 'cafe' ), 'take another one',				'read-back proper intermediate value' );

}
