#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'File::Raw::Base64' ) || print "Bail out!\n";
}

diag( "Testing File::Raw::Base64 $File::Raw::Base64::VERSION, Perl $], $^X" );
