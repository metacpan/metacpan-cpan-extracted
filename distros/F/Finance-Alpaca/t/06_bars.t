use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my %bars = $alpaca->bars(
    symbol    => 'MSFT',
    timeframe => '1Min',
    start     => '2021-04-20T16:20:00Z',
    end       => '2021-04-28T16:40:00Z'
);
isa_ok( $bars{MSFT}[0], 'Finance::Alpaca::Struct::Bar' );
#
is(
    $bars{MSFT}[0]->timestamp->to_string, '2021-04-20T16:20:00Z',
    'Page 1 starts with 2021-04-20T16:20:00Z'
);

# Get next page of bars
%bars = $alpaca->bars(
    symbol     => 'MSFT',
    timeframe  => '1Min',
    start      => '2021-04-20T16:20:00Z',
    end        => '2021-04-28T16:40:00Z',
    page_token => $bars{next_page_token}
);

isa_ok( $bars{MSFT}[0], 'Finance::Alpaca::Struct::Bar' );
is(
    $bars{MSFT}[0]->timestamp->to_string, '2021-04-22T15:05:00Z',
    'Page 2 starts with 2021-04-22T15:05:00Z'
);

done_testing;
1;
