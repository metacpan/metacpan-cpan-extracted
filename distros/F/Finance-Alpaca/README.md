[![Build Status](https://travis-ci.com/sanko/Finance-Alpaca.svg?branch=master)](https://travis-ci.com/sanko/Finance-Alpaca) [![MetaCPAN Release](https://badge.fury.io/pl/Finance-Alpaca.svg)](https://metacpan.org/release/Finance-Alpaca)
# NAME

Finance::Alpaca - Perl Wrapper for Alpaca's Commission-free Stock Trading API

# SYNOPSIS

    use Finance::Alpaca;
    my $alpaca = Finance::Alpaca->new(
        paper => 1,
        keys  => [ ... ]
    );
    my $order = $alpaca->create_order(
        symbol => 'MSFT',
        qty    => .1,
        side   => 'buy',
        type   => 'market',
        time_in_force => 'day'
    );

# DESCRIPTION

Finance::Alpaca allows you to buy, sell, and short U.S. stocks with zero
commissions with Alpaca, an API first, algo-friendly brokerage.

# METHODS

## `new( ... )`

    my $camelid = Finance::Alpaca->new(
        keys => [ 'MDJOHHAE5BDE2FAYAEQT',
                  'Xq9p6ovxaa5XKihaEDRgpMapjeWYd5gIM63iq5BL'
                ] );

Creates a new Finance::Alpaca object.

This constructor accepts the following parameters:

- `keys` - `[ $APCA_API_KEY_ID, $APCA_API_SECRET_KEY ]`

    Every API call requires authentication. You must provide these keys which may
    be acquired in the developer web console and are only visible on creation.

- `paper` - Boolean value

    If you're attempting to use Alpaca's paper trading system, this **must** be a
    true value. Otherwise, you will be making live trades with real assets!

    **Note**: This is a false value by default.

## `account( )`

    my $acct = $camelid->account( );
    CORE::say sprintf 'I can%s short!', $acct->shorting_enabled ? '' : 'not';

Returns a [Finance::Alpaca::Struct::Account](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AAccount) object.

The account endpoint serves important information related to an account,
including account status, funds available for trade, funds available for
withdrawal, and various flags relevant to an account’s ability to trade.

## `clock( )`

    my $clock = $camelid->clock();
    say sprintf
        $clock->timestamp->strftime('It is %l:%M:%S %p on a %A and the market is %%sopen!'),
        $clock->is_open ? '' : 'not ';

Returns a [Finance::Alpaca::Struct::Clock](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AClock) object.

The clock endpoint serves the current market timestamp, whether or not the
market is currently open, as well as the times of the next market open and
close.

## `calendar( [...] )`

        my @days = $camelid->calendar(
            start => Time::Moment->now,
            end   => Time::Moment->now->plus_days(14)
        );
        for my $day (@days) {
            say sprintf '%s the market opens at %s Eastern',
                $day->date, $day->open;
        }

Returns a list of [Finance::Alpaca::Struct::Calendar](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3ACalendar) objects.

The calendar endpoint serves the full list of market days from 1970 to 2029.

The following parameters are accepted:

- `start` - The first date to retrieve data for (inclusive); Time::Moment object or RFC3339 string
- `end` - The last date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

Both listed parameters are optional. If neither is provided, the calendar will
begin on January 1st, 1970.

## `assets( [...] )`

    say $_->symbol
        for sort { $a->symbol cmp $b->symbol } @{ $camelid->assets( status => 'active' ) };

Returns a list of [Finance::Alpaca::Struct::Asset](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AAsset) objects.

The assets endpoint serves as the master list of assets available for trade and
data consumption from Alpaca.

The following parameters are accepted:

- `status` - e.g. `active` or `inactive`. By default, all statuses are included
- `asset_class` - Defaults to `us_equity`

## `asset( ... )`

    my $msft = $camelid->asset('MSFT');
    my $spy  = $camelid->asset('b28f4066-5c6d-479b-a2af-85dc1a8f16fb');

Returns a [Finance::Alpaca::Struct::Asset](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AAsset) object.

You may use either the asset's `id` (UUID) or `symbol`. If the asset is not
found, an empty list is returned.

## `bars( ... )`

    my %bars = $camelid->bars(
          symbol    => 'MSFT',
          timeframe => '1Min',
          start     => Time::Moment->now->with_hour(10),
          end       => Time::Moment->now->minus_minutes(20)
      );

Returns a list of [Finance::Alpaca::Struct::Bar](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3ABar) objects along with other
data.

The bar endpoint serves aggregate historical data for the requested securities.

The following parameters are accepted:

- `symbol` - The symbol to query for; this is required
- `start` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `end` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `limit` - Number of data points to return. Must be in range `1-10000`, defaults to `1000`
- `page_token` - Pagination token to continue from
- `timeframe` - Timeframe for the aggregation. Available values are: `1Min`, `1Hour`, and `1Day`; this is required

The method returns a hash reference with bar data included as a list under the
symbol as well as a `next_page_token` for pagination if applicable.

## `quotes( ... )`

    my %quotes = $camelid->quotes(
        symbol => 'MSFT',
        start  => Time::Moment->now->with_hour(10),
        end    => Time::Moment->now->minus_minutes(20)
    );

Returns a list of [Finance::Alpaca::Struct::Quote](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AQuote) objects along with other
data.

The bar endpoint serves quote (NBBO) historical data for the requested
security.

The following parameters are accepted:

- `symbol` - The symbol to query for; this is required
- `start` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `end` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `limit` - Number of data points to return. Must be in range `1-10000`, defaults to `1000`
- `page_token` - Pagination token to continue from

The method returns a hash reference with quote data included as a list under
the symbol as well as a `next_page_token` for pagination if applicable.

## `trades( ... )`

    my %trades = $camelid->trades(
        symbol => 'MSFT',
        start  => Time::Moment->now->with_hour(10),
        end    => Time::Moment->now->minus_minutes(20)
    );

Returns a list of [Finance::Alpaca::Struct::Trade](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3ATrade) objects along with other
data.

The bar endpoint serves historical trade data for a given ticker symbol on a
specified date.

The following parameters are accepted:

- `symbol` - The symbol to query for; this is required
- `start` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `end` - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required
- `limit` - Number of data points to return. Must be in range `1-10000`, defaults to `1000`
- `page_token` - Pagination token to continue from

The method returns a hash reference with trade data included as a list under
the symbol as well as a `next_page_token` for pagination if applicable.

## `trade_stream( ... )`

    my $stream = $camelid->trade_stream( sub ($packet) {  ... } );

Returns a new [Finance::Alpaca::TradeStream](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3ATradeStream) object.

You are ready to receive real-time account and order data!

This method expects a code reference. This callback will receive all incoming
data.

## `data_stream( ... )`

    my $stream = $camelid->data_stream( sub ($packet) {  ... } );
    $stream->subscribe(
        trades => ['MSFT']
    );

Returns a new [Finance::Alpaca::DataStream](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3ADataStream) object.

You are ready to receive real-time market data!

You can send one or more subscription messages (described in
[Finance::Alpaca::DataStream](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3ADataStream)) and after confirmation you will receive the
corresponding market data.

This method expects a code reference. This callback will receive all incoming
data.

## `orders( [...] )`

    my @orders = $camelid->orders( status => 'open' );

Returns a list of [Finance::Alpaca::Struct::Order](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AOrder) objects.

The orders endpoint returns a list of orders for the account, filtered by the
supplied parameters.

The following parameters are accepted:

- `status` - Order status to be queried. `open`, `closed`, or `all`. Defaults to `open`.
- `limit` - The maximum number of orders in response. Defaults to `50` and max is `500`.
- `after` - The response will include only ones submitted after this timestamp (exclusive.)
- `until` - The response will include only ones submitted until this timestamp (exclusive.)
- `direction` - The chronological order of response based on the submission time. `asc` or `desc`. Defaults to `desc`.
- `nested` - Boolean value indicating whether the result will roll up multi-leg orders under the `legs( )` field of the primary order.
- `symbols` - A comma-separated list of symbols to filter by (ex. `AAPL,TSLA,MSFT`).

## `order_by_id( ..., [...] )`

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4');

Returns a [Finance::Alpaca::Struct::Order](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AOrder) object.

You must provide the order's `id` (UUID). If the order is not found, an empty
list is returned.

You may also provide a boolean value; if true, the result will roll up
multi-leg orders under the `legs( )` field in primary order.

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4', 1);

## `order_by_client_id( ... )`

    my $order = $camelid->order_by_client_id('17ff6b86-d330-4ac1-808b-846555b75b6e');

Returns a [Finance::Alpaca::Struct::Order](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AOrder) object.

You must provide the order's `client_order_id` (UUID). If the order is not
found, an empty list is returned.

## `create_order( ... )`

    my $order = $camelid->create_order(
        symbol => 'MSFT',
        qty    => .1,
        side   => 'buy',
        type   => 'market',
        time_in_force => 'day'
    );

If the order is placed successfully, this method returns a
[Finance::Alpaca::Struct::Order](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AOrder) object. Failures result in hash references
with data from the API.

An order request may be rejected if the account is not authorized for trading,
or if the tradable balance is insufficient to fill the order.

The following parameters are accepted:

- `symbol` - symbol or asset ID to identify the asset to trade (Required)
- `qty` - number of shares to trade. Can be fractionable for only `market` and `day` order types (Required)
- `notional` -dollar amount to trade. Cannot work with qty. Can only work for `market` order types and `day` for time in force (Required)
- `side` - `buy` or `sell` (Required)
- `type` - `market`, `limit`, `stop`, `stop_limit`, or `trailing_stop` (Required)
- `time_in_force` - `day`, `gtc`, `opg`, `cls`, `ioc`, `fok`. Please see [Understand Orders](https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force) for more info (Required)
- `limit_price` - Required if `type` is `limit` or `stop_limit`
- `stop_price` - Required if `type` is `stop` or `stop_limit`
- `trail_price` - This or `trail_percent` is required if `type` is `trailing_stop`
- `trail_percent` - This or `trail_price` is required if `type` is `trailing_stop`
- `extended_hours` - If a `true` value, order will be eligible to execute in premarket/afterhours. Only works with `type` is `limit` and `time_in_force` is `day`
- `client_order_id` - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.
- `order_class` - `simple`, `bracket`, `oco` or `oto`. For details of non-simple order classes, please see [Bracket Order Overview](https://alpaca.markets/docs/trading-on-alpaca/orders#bracket-orders)
- `take_profit` - Additional parameters for `take_profit` leg of advanced orders
    - `limit_price` - Required for bracket orders
- `stop_loss` - Additional parameters for stop-loss leg of advanced orders
    - `stop_price` - Required for bracket orders
    - `limit_price` - The stop-loss order becomes a stop-limit order if specified

## `replace_order( ..., ... )`

    my $new_order = $camelid->replace_order(
        $order->id,
        qty           => 1,
        time_in_force => 'fok',
        limit_price   => 120
    );

Replaces a single order with updated parameters. Each parameter overrides the
corresponding attribute of the existing order. The other attributes remain the
same as the existing order.

A success return code from a replaced order does NOT guarantee the existing
open order has been replaced. If the existing open order is filled before the
replacing (new) order reaches the execution venue, the replacing (new) order is
rejected, and these events are sent in the trade\_updates stream channel.

While an order is being replaced, buying power is reduced by the larger of the
two orders that have been placed (the old order being replaced, and the newly
placed order to replace it). If you are replacing a buy entry order with a
higher limit price than the original order, the buying power is calculated
based on the newly placed order. If you are replacing it with a lower limit
price, the buying power is calculated based on the old order.

In addition to the original order's ID, this method expects the following
parameters:

- `qty` - number of shares to trade
- `time_in_force` - `day`, `gtc`, `opg`, `cls`, `ioc`, `fok`. Please see [Understand Orders](https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force) for more info
- `limit_price` - required if `type` is `limit` or `stop_limit`
- `stop_price` - required if `type` is `stop` or `stop_limit`
- `trail` - the new value of the `trail_price` or `trail_percent` value (works only where `type` is `trailing_stop`)
- `client_order_id` - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.

## `cancel_orders( )`

    $camelid->cancel_orders( );

Attempts to cancel all open orders.

On success, an array of hashes will be returned each with the following
elements:

- `body` - Finance::Alpaca::Struct::Order object
- `id` - the order ID (UUID)
- `status` - HTTP status code for the request

A response will be provided for each order that is attempted to be cancelled.
If an order is no longer cancelable, the server will reject the request and and
empty list will be returned.

## `cancel_order( ... )`

    $camelid->cancel_order( 'be07eebc-13f0-4072-aa4c-f67046081276' );

Attempts to cancel an open order. If the order is no longer cancelable
(example: `status` is `filled`), the server will respond with status 422,
reject the request, and an empty list will be returned. Upon acceptance of the
cancel request, it returns status 204 and a true value.

## `positions( )`

    $camelid->positions( );

Retrieves a list of the account’s open positions and returns a list of
[Finance::Alpaca::Struct::Position](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3APosition) objects.

## `position( ... )`

    my $elon = $camelid->position( 'TSLA' );
    my $msft = $camelid->position( 'b6d1aa75-5c9c-4353-a305-9e2caa1925ab' );

Retreves the account's open position for the given symbol or asset ID and
returns a [Finance::Alpaca::Struct::Position](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3APosition) object if found.

If not found, and empty list is returned.

## `close_all_positions( [...] )`

    my $panic = $camelid->close_all_positions( );

Closes (liquidates) all of the account’s open long and short positions.

    $panic = $camelid->close_all_positions( 1 );

This method accepts one optional parameter which, if true, will cancel all open
orders before liquidating all positions.

On success, an array of hashes will be returned each with the following
elements:

- `body` - [Finance::Alpaca::Struct::Order](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AOrder) object
- `id` - the order ID (UUID)
- `status` - HTTP status code for the request

A response will be provided for each position that is attempted to be closed.

## `close_position( ..., [...] )`

    my $order = $camelid->close_position('MSFT');
    $order    = $camelid->close_position( 'b6d1aa75-5c9c-4353-a305-9e2caa1925ab' );

Closes (liquidates) the account’s open position for the given symbol or asset
ID and returns a [Finance::Alpaca::Struct::Order](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AOrder) object. Works for both long
and short positions.

    my $order = $camelid->close_position('MSFT', 0.5);

This method accepts a second, optional parameter which is the number of shares
to liquidate.

## `portfolio_history( [...] )`

    $camelid->portfolio_history( );

The portfolio history API returns the timeseries data for equity and profit
loss information of the account.

    $camelid->portfolio_history( period => '2W' );

This method accepts the following optional parameters:

- `period` - The duration of the data in `<number> + <unit>`, such as 1D, where &lt;unit> can be D for day, `W` for week, `M` for month and `A` for year. Defaults to `1M`
- `timeframe` - The resolution of time window. `1Min`, `5Min`, `15Min`, `1H`, or `1D`. If omitted, `1Min` for less than 7 days period, `15Min` for less than 30 days, or otherwise `1D`
- `date_end` - The date the data is returned up to, in `YYYY-MM-DD` format or as a Time::Moment object. Defaults to the current market date (rolls over at the market open if `extended_hours` is false, otherwise at 7am ET)
- `extended_hours` Boolean value; if true, include extended hours in the result. This is effective only for timeframe less than `1D`.

The returned data is in a hash ref with the following keys:

- `timestamp` - List of Time::Moment objects; the time of each data element, left-labeled (the beginning of the window)
- `equity` - List of numbers; equity values of the account in dollar amounts as of the end of each time window
- `profit_loss` - List of numbers; profit/loss in dollar from the base value
- `profit_loss_pct` - List of numbers; profit/loss in percentage from the base value
- `base_value` - basis in dollar of the profit loss calculation
- `timeframe` - time window size of each data element

## `watchlists( )`

    my @watchlists = $camelid->watchlists;

Returns the list of watchlists registered under the account as
[Finance::Alpaca::Struct::Watchlist](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AWatchlist) objects.

## `create_watchlist( ..., [...] )`

    my $new_watchlist = $camelid->create_watchlist( 'Leveraged ETFs' );
    my $tech_watchlist = $camelid->create_watchlist( 'FAANG', qw[FB AMZN AAPL NFLX GOOG] );

Create a new watchlist potentially with an initial set of assets. Only the
first parameter is required and is the name of the user-defined new watchlist.
This name must be a maximum of `64` characters. To add assets to the watchlist
on create, include a list of ticker symbols.

On success, the related [Finance::Alpaca::Struct::Watchlist](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AWatchlist) object is
returned.

## `delete_watchlist( ... )`

    $camelid->delete_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678' );

Delete a watchlist identified by the ID. This is a permanent deletion.

## `watchlist( ... )`

    $camelid->watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678' );

Returns a watchlist identified by the ID.

## `update_watchlist( ... )`

    $camelid->update_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678', name => 'Low priority' );
    $camelid->update_watchlist( '29d85812-b4a2-45da-ac6c-dcc0ad9c1cd3', symbols => [qw[MA V]] );

Update the name and/or content of watchlist. On success, a
[Finance::Alpaca::Struct::Watchlist](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AWatchlist) object is returned.

## `add_to_watchlist( ... )`

    $camelid->add_to_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678', 'TSLA');

Append an asset for the symbol to the end of watchlist asset list. On success,
a [Finance::Alpaca::Struct::Watchlist](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AWatchlist) object is returned.

## `remove_from_watchlist( ... )`

    $camelid->remove_from_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678', 'F');

Delete one entry for an asset by symbol name. On success, a
[Finance::Alpaca::Struct::Watchlist](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AWatchlist) object is returned.

## `configuration( )`

    my $confs = $camelid->configuration( );

Returns the current account configuration values.

## `modify_configuration( )`

    $confs = $camelid->modify_configuration(
        trade_confirm_email=> 'all'
    );

Updates the account configuration values. On success, the modified
configuration is returned.

## `activities( [...] )`

    my @activities = $camelid->activities();

Returns account activity entries for many types of activities.

    @activities = $camelid->activities(activity_types => [qw[ACATC ACATS]]);

Returns account activity entries for a set of specific types of activity. See
[Finance::Alpaca::Struct::Activity](https://metacpan.org/pod/Finance%3A%3AAlpaca%3A%3AStruct%3A%3AActivity) for a list of activity types.

This method expects a combination of the following optional parameters:

- `activity_types` - A list of the activity types to include in the response. If unspecified, activities of all types will be returned.
- `date` - The date for which you want to see activities as string or Time::Moment object
- `until` - The response will contain only activities submitted before this date. (Cannot be used with `date`.)
- `after` - The response will contain only activities submitted after this date. (Cannot be used with `date`.)
- `direction` - `asc` or `desc` (default is `desc` if unspecified.)
- `page_size` - The maximum number of entries to return in the response
- `page_token` - The ID of the end of your current page of results

# Paging of Results

When required, pagination is handled using the `page_token` and `page_size`
parameters. `page_token` represents the ID of the end of your current page of
results. If specified with a direction of `desc`, for example, the results
will end before the activity with the specified ID. If specified with a
direction of `asc`, results will begin with the activity immediately after the
one specified. `page_size` is the maximum number of entries to return in the
response. If `date` is not specified, the default and maximum value is `100`.
If `date` is specified, the default behavior is to return all results, and
there is no maximum page size.

# See Also

[https://alpaca.markets/docs/api-documentation/api-v2/](https://alpaca.markets/docs/api-documentation/api-v2/)

# Note

I do not have a live trading account with Alpaca but this package has worked
well with paper trading. YMMV.

# LEGAL

This is a simple wrapper around the API as described in documentation. The
author provides no investment, legal, or tax advice and is not responsible for
any damages incurred while using this software. This software is not affiliated
with Alpaca Securities LLC in any way.

For Alpaca's terms and disclosures, please see their website at
https://alpaca.markets/disclosures

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
