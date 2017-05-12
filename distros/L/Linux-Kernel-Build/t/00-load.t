#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Linux::Kernel::Build' ) || print "Bail out!\n";
}

diag( "Testing Linux::Kernel::Build $Linux::Kernel::Build::VERSION, Perl $], $^X" );
