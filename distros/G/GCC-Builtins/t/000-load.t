#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

our $VERSION = '0.06'; 

plan tests => 1;

BEGIN {
    use_ok( 'GCC::Builtins' , ':all') || print "Bail out!\n";
}

diag( "Testing GCC::Builtins $GCC::Builtins::VERSION, Perl $], $^X" );
