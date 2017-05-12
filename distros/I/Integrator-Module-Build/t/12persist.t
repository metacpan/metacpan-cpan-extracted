#!/usr/bin/perl

#######################################################################################################################
use Test::More tests => 1;
#######################################################################################################################
# This is the third persistence test file.
# So in here we just re-use a variable set in the first persistence file.

use Integrator::Module::Build;
my $build = Integrator::Module::Build->current;


SKIP: {
	skip 'not in development mode' , 1;


isnt ( $build->config_data( 'complex' ), undef,				'complex data structure is still visible' );

}
