#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Apps::Script::Type::Slides' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Apps::Script::Type::Slides $Google::Cloud::Apps::Script::Type::Slides::VERSION, Perl $], $^X" );
