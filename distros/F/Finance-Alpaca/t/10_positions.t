use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my @positions = $alpaca->positions();
isa_ok( $positions[0], 'Finance::Alpaca::Struct::Position' );
my $msft_pos = $alpaca->position('MSFT');
isa_ok( $msft_pos,                                'Finance::Alpaca::Struct::Position' );
isa_ok( $alpaca->position( $msft_pos->asset_id ), 'Finance::Alpaca::Struct::Position' );
done_testing;
1;
