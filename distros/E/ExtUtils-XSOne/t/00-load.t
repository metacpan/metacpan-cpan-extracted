#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ExtUtils::XSOne' ) || print "Bail out!\n";
}

diag( "Testing ExtUtils::XSOne $ExtUtils::XSOne::VERSION, Perl $], $^X" );
