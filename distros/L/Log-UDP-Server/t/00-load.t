#!perl -T

use Test::More tests => 1;
BEGIN { use_ok( 'Log::UDP::Server' ); }
diag( "Testing Log::UDP::Server $Log::UDP::Server::VERSION, Perl $], $^X" );
