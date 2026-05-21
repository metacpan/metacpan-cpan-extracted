#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Raw::Separated' ) || print "Bail out!\n";
}

diag( "Testing File::Raw::Separated $File::Raw::Separated::VERSION, Perl $], $^X" );
