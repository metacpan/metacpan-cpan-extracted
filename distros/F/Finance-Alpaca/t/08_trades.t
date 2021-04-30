use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my %trades = $alpaca->trades(
    symbol => 'MSFT',
    start  => '2021-04-20T16:20:00Z',
    end    => '2021-04-28T16:40:00Z'
);
isa_ok( $trades{MSFT}[0], 'Finance::Alpaca::Struct::Trade' );
#
is(
    $trades{MSFT}[0]->timestamp->to_string,
    '2021-04-20T16:20:00.053Z', 'Page 1 starts with 2021-04-20T16:20:00.053Z'
);

# Get next page of trades
%trades = $alpaca->trades(
    symbol     => 'MSFT',
    start      => '2021-04-20T16:20:00Z',
    end        => '2021-04-28T16:40:00Z',
    page_token => $trades{next_page_token}
);
isa_ok( $trades{MSFT}[0], 'Finance::Alpaca::Struct::Trade' );
is(
    $trades{MSFT}[0]->timestamp->to_string,
    '2021-04-20T16:21:10.092239240Z',
    'Page 2 starts with 2021-04-20T16:21:10.092239240Z'
);
done_testing;
1;
