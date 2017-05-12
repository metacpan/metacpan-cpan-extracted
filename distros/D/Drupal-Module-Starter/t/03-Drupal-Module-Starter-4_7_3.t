#!perl -w

BEGIN {
	use strict;
	use Test::More qw/no_plan/;
	use_ok('Drupal::Module::Starter::4_7_3');
}

ok( $stubs = $Drupal::Module::Starter::4_7_3::stubs );
is( ref($stubs), 'HASH' );
ok( scalar(keys(%$stubs)));
