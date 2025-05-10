#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Keyword::Anonymous::Object' ) || print "Bail out!\n";
}

diag( "Testing Keyword::Anonymous::Object $Keyword::Anonymous::Object::VERSION, Perl $], $^X" );
