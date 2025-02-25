#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Basic::XS' ) || print "Bail out!\n";
}

diag( "Testing Math::Basic::XS $Math::Basic::XS::VERSION, Perl $], $^X" );
