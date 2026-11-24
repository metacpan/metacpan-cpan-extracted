#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Logging::Type' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Logging::Type $Google::Cloud::Logging::Type::VERSION, Perl $], $^X" );
