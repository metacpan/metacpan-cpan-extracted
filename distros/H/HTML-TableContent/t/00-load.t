#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'HTML::TableContent' ) || print "Bail out!\n";
}

diag( "Testing HTML::TableContent $HTML::TableContent::VERSION, Perl $], $^X" );
