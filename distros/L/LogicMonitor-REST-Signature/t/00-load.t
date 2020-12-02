#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LogicMonitor::REST::Signature' ) || print "Bail out!\n";
}

diag( "Testing LogicMonitor::REST::Signature $LogicMonitor::REST::Signature::VERSION, Perl $], $^X" );
