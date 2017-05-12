#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Lexical::Types' );
}

diag( "Testing Lexical::Types $Lexical::Types::VERSION, Perl $], $^X" );
