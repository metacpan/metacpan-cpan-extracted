#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::NumberBase::XS' ) || print "Bail out!\n";
}

diag( "Testing Math::NumberBase::XS $Math::NumberBase::XS::VERSION, Perl $], $^X" );
