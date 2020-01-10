#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Huawei::Info::Ipaddr' ) || print "Bail out!\n";
}

diag( "Testing Huawei::Info::Ipaddr $Huawei::Info::Ipaddr::VERSION, Perl $], $^X" );
