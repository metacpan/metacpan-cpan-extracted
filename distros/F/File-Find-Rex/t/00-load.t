#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Find::Rex' ) || print "Bail out!\n";
}

diag( "Testing File::Find::Rex $File::Find::Rex::VERSION, Perl $], $^X" );
