#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Find::IncludesTimeRange' ) || print "Bail out!\n";
}

diag( "Testing File::Find::IncludesTimeRange $File::Find::IncludesTimeRange::VERSION, Perl $], $^X" );
