#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mac::OSA::Dialog::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Mac::OSA::Dialog::Tiny $Mac::OSA::Dialog::Tiny::VERSION, Perl $], $^X" );
