#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('HTML::TableParser');
}

diag( "Testing HTML::TableParser $HTML::TableParser::VERSION, Perl $], $^X" );
