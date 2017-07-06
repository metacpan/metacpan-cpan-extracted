package Finance::GDAX::API::Product;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API;
use Finance::GDAX::API::TypeConstraints;
use namespace::autoclean;

extends 'Finance::GDAX::API';

has 'id' => (is  => 'rw',
	     isa => 'Str',
    );

# for order_book
has 'level' => (is  => 'rw',
		isa => 'ProductLevel',
		default => 1,
    );

# for historic_rates
has 'start' => (is  => 'rw',
		isa => 'Str',
    );
has 'end' => (is  => 'rw',
	      isa => 'Str',
    );
has 'granularity' => (is  => 'rw',
		      isa => 'PositiveInt',
    );

sub list {
    my $self = shift;
    $self->method('GET');
    $self->path('/products');
    return $self->send;
}

sub order_book {
    my ($self, $product_id) = @_;
    $product_id = $product_id || $self->id;
    die 'order_book requires a product id' unless $product_id;
    $self->id($product_id);
    my $path = "/products/$product_id?level=" . $self->level;
    $self->method('GET');
    $self->path($path);
    return $self->send;
}

sub ticker {
    my ($self, $product_id) = @_;
    $product_id = $product_id || $self->id;
    die 'ticker requires a product id' unless $product_id;
    $self->id($product_id);
    my $path = "/products/$product_id/ticker";
    $self->method('GET');
    $self->path($path);
    return $self->send;
}

sub trades {
    my ($self, $product_id) = @_;
    $product_id = $product_id || $self->id;
    die 'trades requires a product id' unless $product_id;
    $self->id($product_id);
    my $path = "/products/$product_id/trades";
    $self->method('GET');
    $self->path($path);
    return $self->send;
}

sub historic_rates {
    my ($self, $product_id) = @_;
    $product_id = $product_id || $self->id;
    die 'historic rates requires a product id' unless $product_id;
    $self->id($product_id);
    die 'historic rates requires start time'  unless $self->start;
    die 'historic rates requires end time'    unless $self->end;
    die 'historic rates requires granularity' unless $self->granularity;
  
    my $path = "/products/$product_id/candles";
    $path .= '?start='       . $self->start;
    $path .= '&end='         . $self->end;
    $path .= '&granularity=' . $self->granularity;
    $self->method('GET');
    $self->path($path);
    return $self->send;
}

sub day_stats {
    my ($self, $product_id) = @_;
    $product_id = $product_id || $self->id;
    die 'day_stats requires a product id' unless $product_id;
    $self->id($product_id);
    my $path = "/products/$product_id/stats";
    $self->method('GET');
    $self->path($path);
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::UserAccount - Product Information

=head1 SYNOPSIS

  use Finance::GDAX::API::Product;

  $product = Finance::GDAX::API::Product->new;

  # List of all products
  $products = $product->list;

=head2 DESCRIPTION

Returns various information about GDAX products.

=head1 ATTRIBUTES

=head2 C<id> $string

The GDAX product id. Necessary for order_book, get_trades,
historic_rates (or passed as parameter to method).

=head2 C<level> $integer (default: 1)

The detail level in the return hash of the method order_book:

  Level Description
  1 	Only the best bid and ask
  2 	Top 50 bids and asks (aggregated)
  3 	Full order book (non aggregated)

Levels 1 and 2 are aggregated and return the number of orders at each
level. Level 3 is non-aggregated and returns the entire order book.

=head2 C<start> $datetime_string (ISO8601)

Start time for the historic_rates method.

=head2 C<end> $datetime_string (ISO8601)

End time for the historic_rates method.

=head2 C<granularity> $seconds

Granularity in seconds for the historic_rates method.

=head1 METHODS

=head2 C<list>

Returns a list of available currency pairs for trading.

  [
    {
        "id": "BTC-USD",
        "base_currency": "BTC",
        "quote_currency": "USD",
        "base_min_size": "0.01",
        "base_max_size": "10000.00",
        "quote_increment": "0.01"
    }
  ]

The base_min_size and base_max_size fields define the min and max
order size. The quote_increment field specifies the min order price as
well as the price increment.

The order price must be a multiple of this increment (i.e. if the
increment is 0.01, order prices of 0.001 or 0.021 would be rejected).

=head2 C<order_book> [$product_id]

Returns a hash of open orders for a product. The $product_id can be
passed in as a parameter to the method, or the attribute "id" can be
set. The parameter takes precidence.

The amount of detail returned is customized with the "level" attribute.

By default, only the inside (i.e. best) bid and ask are returned. This
is equivalent to a book depth of 1 level. If you would like to see a
larger order book, specify the level query parameter.

If a level is not aggregated, then all of the orders at each price
will be returned. Aggregated levels return only one size for each
active price (as if there was only a single order for that size at the
level).

Level 1:

  {
    "sequence": "3",
    "bids": [
        [ price, size, num-orders ],
    ],
    "asks": [
        [ price, size, num-orders ],
    ]
  }

Level 2:

  {
    "sequence": "3",
    "bids": [
        [ price, size, num-orders ],
        [ "295.96", "4.39088265", 2 ],
        ...
    ],
    "asks": [
        [ price, size, num-orders ],
        [ "295.97", "25.23542881", 12 ],
        ...
    ]
  }

Level 3:

  {
    "sequence": "3",
    "bids": [
        [ price, size, order_id ],
        [ "295.96","0.05088265","3b0f1225-7f84-490b-a29f-0faef9de823a" ],
        ...
    ],
    "asks": [
        [ price, size, order_id ],
        [ "295.97","5.72036512","da863862-25f4-4868-ac41-005d11ab0a5f" ],
        ...
    ]
  }

The GDAX API warns you that abuse of level 3 polling with cause your
access to be limited or blocked -- to use websocket streams instead.

=head2 C<ticker> [$product_id]

Returns snapshot information about the last trade (tick), best bid/ask
and 24h volume.

Takes parameter product_id or uses "id" attribute.

Real-time updates

Polling is discouraged in favor of connecting via the websocket stream
and listening for match messages.

  {
  "trade_id": 4729088,
  "price": "333.99",
  "size": "0.193",
  "bid": "333.98",
  "ask": "333.99",
  "volume": "5957.11914015",
  "time": "2015-11-14T20:46:03.511254Z"
  }

=head2 C<trades> [$product_id]

Return an array of hashes of the latest trades for a given product_id,
which can be a parameter to the method or the attribute "id".

  [{
    "time": "2014-11-07T22:19:28.578544Z",
    "trade_id": 74,
    "price": "10.00000000",
    "size": "0.01000000",
    "side": "buy"
  }, {
    "time": "2014-11-07T01:08:43.642366Z",
    "trade_id": 73,
    "price": "100.00000000",
    "size": "0.01000000",
    "side": "sell"
  }]

Side

The trade side indicates the maker order side. The maker order is the
order that was open on the order book. buy side indicates a down-tick
because the maker was a buy order and their order was
removed. Conversely, sell side indicates an up-tick.

=head2 C<historic_rates> [$product_id]

Returns an array of arrays of historic rates for a product. The array
buckets are ordered as follows:

  [
    [ time, low, high, open, close, volume ],
    [ 1415398768, 0.32, 4.2, 0.35, 4.2, 12.3 ],
    ...
  ]

This method requires that the attributes "start", "end" and
"granularity" are set.

Each bucket is an array of the following information:

    time   bucket start time
    low    lowest price during the bucket interval
    high   highest price during the bucket interval
    open   opening price (first trade) in the bucket interval
    close  closing price (last trade) in the bucket interval
    volume volume of trading activity during the bucket interval

=head2 C<day_stats> [$product_id]

Returns a hash of the stats for the given $product_id (or "id"
attribute) accumulated for the last 24 hours.

API:

Get 24 hr stats for the product. volume is in base currency
units. open, high, low are in quote currency units.

  {
    "open": "34.19000000",
    "high": "95.70000000",
    "low": "7.06000000",
    "volume": "2.41000000"
  }

(however actual dump of data shows more):

  $VAR1 = {
          'open' => 0,
          'low' => 0,
          'high' => 0,
          'last' => '9999999999.00000000',
          'volume_30day' => '2295.91760955',
          'volume' => 0
        };


=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

