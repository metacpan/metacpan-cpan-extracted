use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my @activities = $alpaca->activities( activity_types => ['FILL'] );
isa_ok( $activities[0], 'Finance::Alpaca::Struct::TradeActivity' );
done_testing;
1;
