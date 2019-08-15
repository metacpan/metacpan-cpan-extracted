#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geoffrey::Converter::Pg' ) || print "Bail out!\n";
}

diag( "Testing Geoffrey::Converter::Pg $Geoffrey::Converter::Pg::VERSION, Perl $], $^X" );
