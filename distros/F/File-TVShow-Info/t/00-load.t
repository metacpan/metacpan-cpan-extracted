#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::TVShow::Info' ) || print "Bail out!\n";
}

diag( "Testing File::TVShow::Info $File::TVShow::Info::VERSION, Perl $], $^X" );
