#!perl -T

use Test::More tests => 1;
BEGIN { use_ok( 'Log::UDP::Client' ); }
diag( "Testing Log::UDP::Client $Log::UDP::Client::VERSION, Perl $], $^X" );
