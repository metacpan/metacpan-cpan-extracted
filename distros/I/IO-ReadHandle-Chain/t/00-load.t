#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::ReadHandle::Chain' ) || print "Bail out!\n";
}

diag( "Testing IO::ReadHandle::Chain $IO::ReadHandle::Chain::VERSION, Perl $], $^X" );
