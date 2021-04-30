use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my %quotes = $alpaca->quotes(
    symbol => 'MSFT',
    start  => '2021-04-20T16:20:00Z',
    end    => '2021-04-28T16:40:00Z'
);
isa_ok( $quotes{MSFT}[0], 'Finance::Alpaca::Struct::Quote' );
#
is(
    $quotes{MSFT}[0]->timestamp->to_string,
    '2021-04-20T16:20:00.058210560Z',
    'Page 1 starts with 2021-04-20T16:20:00.058210560Z'
);

# Get next page of quotes
%quotes = $alpaca->quotes(
    symbol     => 'MSFT',
    start      => '2021-04-20T16:20:00Z',
    end        => '2021-04-28T16:40:00Z',
    page_token => $quotes{next_page_token}
);
isa_ok( $quotes{MSFT}[0], 'Finance::Alpaca::Struct::Quote' );
is(
    $quotes{MSFT}[0]->timestamp->to_string,
    '2021-04-20T16:20:29.068889Z', 'Page 2 starts with 2021-04-20T16:20:29.068889Z'
);
done_testing;
1;
