#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Finance::CoinbasePro::API::CLI' ) || print "Bail out!\n";
}

diag( "Testing Finance::CoinbasePro::API::CLI $Finance::CoinbasePro::API::CLI::VERSION, Perl $], $^X" );
