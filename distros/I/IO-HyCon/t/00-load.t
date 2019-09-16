#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IO::HyCon' ) || print "Bail out!\n";
}

diag( "Testing IO::HyCon $IO::HyCon::VERSION, Perl $], $^X" );
