#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Huawei::Healthchecker' ) || print "Bail out!\n";
}

diag( "Testing Huawei::Healthchecker $Huawei::Healthchecker::VERSION, Perl $], $^X" );
