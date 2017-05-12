#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JavaScript::V8::Handlebars' ) || print "Bail out!\n";
}

diag( "Testing JavaScript::V8::Handlebars $JavaScript::V8::Handlebars::VERSION, Perl $], $^X" );
