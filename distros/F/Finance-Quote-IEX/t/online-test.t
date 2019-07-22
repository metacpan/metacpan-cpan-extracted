use strict;
use Test::More;
use Finance::Quote;

if ( not $ENV{ONLINE_TEST} ) {
    plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}

plan skip_all => 'The IEX API removed all non-IEX data in June 2019.';

my $q = Finance::Quote->new('IEX');

# Stocks from NYSE, NASDAQ and AMEX.
my @stocks = ( 'BAC', 'AAPL', 'IMO' );

my %quotes = $q->fetch( 'iex', @stocks );
ok( %quotes, 'Data returned' );

foreach my $stock (@stocks) {
    ok( $quotes{ $stock, 'success' }, 'Success' );
    ok( $quotes{ $stock, 'last' } > 0,   'last > 0' );
    ok( defined $quotes{ $stock, 'name' }, 'name is defined' );
    like( $quotes{ $stock, 'date' }, qr#^\d\d/\d\d/\d\d$#, 'date is formatted correctly' );
    like( $quotes{ $stock, 'isodate' }, qr#^\d{4}-\d\d-\d\d$#, 'isodate is formatted correctly' );
    like( $quotes{ $stock, 'time' }, qr#^\d\d:\d\d:\d\d$#, 'time is formatted correctly' );
    is( $quotes{ $stock, 'method' }, 'iex', 'method is iex' );
    is( $quotes{ $stock, 'currency' }, 'USD', 'currency is USD' );
    ok( $quotes{ $stock, 'volume' } >= 0, 'volume >= 0' );
}

# Check that a bogus stock returns no-success.
%quotes = $q->fetch( 'iex', 'BOGUS' );
ok( !$quotes{ 'BOGUS', 'success' }, 'BOGUS failed' );

done_testing();
