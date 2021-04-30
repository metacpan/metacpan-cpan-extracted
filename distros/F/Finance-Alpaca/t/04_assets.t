use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my $msft = $alpaca->asset('MSFT');
isa_ok( $msft, 'Finance::Alpaca::Struct::Asset' );
is( 'MSFT', $msft->symbol, 'asset("MSFT") == $MSFT' );
my $spy = $alpaca->asset('b28f4066-5c6d-479b-a2af-85dc1a8f16fb');
isa_ok( $spy, 'Finance::Alpaca::Struct::Asset' );
is( 'SPY', $spy->symbol, 'asset("b28f4066-5c6d-479b-a2af-85dc1a8f16fb") == $SPY' );
done_testing;
1;
