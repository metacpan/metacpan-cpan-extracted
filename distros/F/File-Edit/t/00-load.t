#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Edit' ) || print "Bail out!\n";
}

diag( "Testing File::Edit $File::Edit::VERSION, Perl $], $^X" );
