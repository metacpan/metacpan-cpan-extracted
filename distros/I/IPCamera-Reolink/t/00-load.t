#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IPCamera::Reolink' ) || print "Bail out!\n";
}

diag( "Testing IPCamera::Reolink $IPCamera::Reolink::VERSION, Perl $], $^X" );
