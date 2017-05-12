#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Finance::IBrokers::MooseCallback' ) || print "Bail out!\n";
    use_ok( 'Finance::IBrokers::Types' ) || print "Bail out!\n";
}

diag( "Testing Finance::IBrokers::MooseCallback $Finance::IBrokers::MooseCallback::VERSION, Perl $], $^X" );
