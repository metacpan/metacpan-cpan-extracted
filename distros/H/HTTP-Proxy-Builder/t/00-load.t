#!perl -T

use Test::More tests => 1;

use_ok( 'HTTP::Proxy::Builder', 'no_start' );

diag( "Testing HTTP::Proxy::Builder $HTTP::Proxy::Builder::VERSION, Perl $], $^X");
diag("HTTP::Proxy $HTTP::Proxy::VERSION");
