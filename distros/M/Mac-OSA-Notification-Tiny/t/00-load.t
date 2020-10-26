#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mac::OSA::Notification::Tiny' ) || print "Bail out!\n";
}

diag( "Testing Mac::OSA::Notification::Tiny $Mac::OSA::Notification::Tiny::VERSION, Perl $], $^X" );
