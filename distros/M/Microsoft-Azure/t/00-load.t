#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Microsoft::Azure::AccessToken' ) || print "Bail out!\n";
}

diag( "Testing Microsoft::Azure::AccessToken $Microsoft::Azure::AccessToken::VERSION, Perl $], $^X" );
