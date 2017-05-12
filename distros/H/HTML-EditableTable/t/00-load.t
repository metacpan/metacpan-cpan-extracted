#!perl -T
use lib "../lib/";

use Test::More tests => 4;

BEGIN {
  use_ok( 'HTML::EditableTable' );
  use_ok( 'HTML::EditableTable::Horizontal' );
  use_ok( 'HTML::EditableTable::Vertical' );
  use_ok( 'HTML::EditableTable::Javascript' );
  
}

diag( "Testing HTML::EditableTable $HTML::EditableTable::VERSION, Perl $], $^X" );
