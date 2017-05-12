#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::MultilineGrep' ) || print "Bail out!\n";
}

diag( "Testing File::MultilineGrep $File::MultilineGrep::VERSION, Perl $], $^X" );
