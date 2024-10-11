#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

our $VERSION = '1.01';

plan tests => 1;

BEGIN {
    use_ok( 'LaTeX::Easy::Templates' ) || print "Bail out!\n";
}

diag( "Testing LaTeX::Easy::Templates $LaTeX::Easy::Templates::VERSION, Perl $], $^X" );
