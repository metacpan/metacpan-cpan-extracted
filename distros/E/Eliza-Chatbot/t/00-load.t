#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Eliza::Chatbot' ) || print "Bail out!\n";
}

diag( "Testing Eliza::Chatbot $Eliza::Chatbot::VERSION, Perl $], $^X" );
