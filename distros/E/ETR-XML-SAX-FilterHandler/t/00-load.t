#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ETR::XML::SAX::FilterHandler' ) || print "Bail out!\n";
}

diag( "Testing ETR::XML::SAX::FilterHandler $ETR::XML::SAX::FilterHandler::VERSION, Perl $], $^X" );
