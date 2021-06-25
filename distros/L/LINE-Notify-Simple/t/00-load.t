#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LINE::Notify::Simple' ) || print "Bail out!\n";
}

diag( "Testing LINE::Notify::Simple $LINE::Notify::Simple::VERSION, Perl $], $^X" );
