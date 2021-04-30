use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my @days = $alpaca->calendar(
    start => '2021-04-14T16:20:00Z',
    end   => '2021-04-28T16:40:00Z'
);
isa_ok( $days[0], 'Finance::Alpaca::Struct::Calendar' );
done_testing;
1;
