#!perl -T
use 5.8.3;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ExtUtils::MakeMaker::Extensions' ) || print "Bail out!\n";
}

diag( "Testing ExtUtils::MakeMaker::Extensions $ExtUtils::MakeMaker::Extensions::VERSION, Perl $], $^X" );
