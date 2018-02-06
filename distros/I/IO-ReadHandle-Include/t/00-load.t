#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::ReadHandle::Include' ) || print "Bail out!\n";
}

diag( "Testing IO::ReadHandle::Include $IO::ReadHandle::Include::VERSION, Perl $], $^X" );
