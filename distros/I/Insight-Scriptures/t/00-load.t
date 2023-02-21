#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Insight::Scriptures' ) || print "Bail out!\n";
}

diag( "Testing Insight::Scriptures $Insight::Scriptures::VERSION, Perl $], $^X" );
