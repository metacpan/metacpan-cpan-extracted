#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Drupal::Admin' );
}

diag( "Testing Drupal::Admin $Drupal::Admin::VERSION, Perl $], $^X" );
