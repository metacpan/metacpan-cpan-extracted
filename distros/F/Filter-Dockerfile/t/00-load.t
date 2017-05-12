#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Filter::Dockerfile' ) || print "Bail out!\n";
}

diag( "Testing Filter::Dockerfile $Filter::Dockerfile::VERSION, Perl $], $^X" );
