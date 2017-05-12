#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'HTML::Calendar::Monthly' );
}

diag( "Testing HTML::Calendar::Monthly $HTML::Calendar::Monthly::VERSION, Perl $], $^X" );
