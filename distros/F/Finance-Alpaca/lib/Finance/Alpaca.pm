package Finance::Alpaca 0.9904 {
    use strictures 2;
    use Moo;
    use feature 'signatures';
    no warnings 'experimental::signatures';
    use Mojo::UserAgent;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str Int];
    use Types::UUID;
    #
    use lib '../../lib/';
    use Finance::Alpaca::DataStream;
    use Finance::Alpaca::Struct::Account qw[to_Account];
    use Finance::Alpaca::Struct::Activity qw[to_Activity Activity];
    use Finance::Alpaca::Struct::Asset qw[to_Asset Asset];
    use Finance::Alpaca::Struct::Bar qw[to_Bar Bar];
    use Finance::Alpaca::Struct::Calendar qw[to_Calendar Calendar];
    use Finance::Alpaca::Struct::Configuration qw[to_Configuration Configuration];
    use Finance::Alpaca::Struct::Clock qw[to_Clock];
    use Finance::Alpaca::Struct::Order qw[to_Order Order];
    use Finance::Alpaca::Struct::Position qw[to_Position Position];
    use Finance::Alpaca::Struct::Quote qw[to_Quote Quote];
    use Finance::Alpaca::Struct::Trade qw[to_Trade Trade];
    use Finance::Alpaca::Struct::TradeActivity qw[to_TradeActivity TradeActivity];
    use Finance::Alpaca::Struct::Watchlist qw[to_Watchlist Watchlist];
    use Finance::Alpaca::TradeStream;
    use Finance::Alpaca::Types;
    #
    has ua => ( is => 'lazy', isa => InstanceOf ['Mojo::UserAgent'] );

    sub _build_ua ($s) {
        my $ua = Mojo::UserAgent->new;
        $ua->transactor->name(
            sprintf 'Finance::Alpaca %f (Perl %s)',
            $Finance::Alpaca::VERSION, $^V
        );
        $ua->on(
            start => sub ( $ua, $tx ) {
                $tx->req->headers->header( 'APCA-API-KEY-ID'     => $s->keys->[0] ) if $s->has_keys;
                $tx->req->headers->header( 'APCA-API-SECRET-KEY' => $s->keys->[1] ) if $s->has_keys;
            }
        );
        return $ua;
    }
    has api_version => ( is => 'ro', isa => Enum [ 1, 2 ], required => 1, default => 2 );
    has paper => ( is => 'rw', isa => Bool, required => 1, default => 0, coerce => 1 );

    sub endpoint ($s) {
        $s->paper ? 'https://paper-api.alpaca.markets' : '';
    }
    has keys => ( is => 'rwp', isa => ArrayRef [ Str, 2 ], predicate => 1 );
    #
    sub account ($s) {
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/account' );
        $tx = $s->ua->start($tx);
        return to_Account( $tx->result->json );
    }

    sub clock ($s) {
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/clock' );
        $tx = $s->ua->start($tx);
        return to_Clock( $tx->result->json );
    }

    sub calendar ( $s, %params ) {
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        my $tx = $s->ua->build_tx( GET => $s->endpoint . '/v2/calendar' . $params );
        $tx = $s->ua->start($tx);
        return @{ ( ArrayRef [Calendar] )->assert_coerce( $tx->result->json ) };
    }

    sub assets ( $s, %params ) {
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        return @{
            ( ArrayRef [Asset] )->assert_coerce(
                $s->ua->get( $s->endpoint . '/v2/assets' . $params )->result->json
            )
        };

    }

    sub asset ( $s, $symbol_or_asset_id ) {
        my $res = $s->ua->get( $s->endpoint . '/v2/assets/' . $symbol_or_asset_id )->result;
        return $res->is_error ? () : to_Asset( $res->json );
    }

    sub bars ( $s, %params ) {
        my $symbol = delete $params{symbol};
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . (
                ref $params{$_} eq 'Time::Moment'
                ? $params{$_}->strftime('%Y-%m-%dT%H:%M:%S%Z')
                : $params{$_}
                )
        } keys %params if keys %params;
        my $res = $s->ua->get(
            sprintf 'https://data.alpaca.markets/v%d/stocks/%s/bars%s',
            $s->api_version, $symbol, $params
        )->result;
        return $res->is_error ? $res->json : (
            ( next_page_token => $res->json->{next_page_token} ),
            map { delete $_->{symbol} => delete $_->{bars} }
                ( Dict [ bars => ArrayRef [Bar], symbol => Str, next_page_token => Maybe [Str] ] )
                ->assert_coerce( $res->json )
        );
    }

    sub quotes ( $s, %params ) {
        my $symbol = delete $params{symbol};
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . ( ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string() : $params{$_} )
        } keys %params if keys %params;
        my $res = $s->ua->get(
            sprintf 'https://data.alpaca.markets/v%d/stocks/%s/quotes%s',
            $s->api_version, $symbol, $params
        )->result;
        return $res->is_error ? $res->json : (
            ( next_page_token => $res->json->{next_page_token} ),
            map { delete $_->{symbol} => delete $_->{quotes} } (
                Dict [ quotes => ArrayRef [Quote], symbol => Str, next_page_token => Maybe [Str] ]
            )->assert_coerce( $res->json )
        );
    }

    sub trades ( $s, %params ) {
        my $symbol = delete $params{symbol};
        for ( keys %params ) {
            $params{$_} = $params{$_}->to_string() if ref $params{$_} eq 'Time::Moment';
        }
        my $res = $s->ua->get(
            sprintf(
                'https://data.alpaca.markets/v%d/stocks/%s/trades',
                $s->api_version, $symbol
            ) => form => {%params}
        )->result;
        return $res->is_error ? $res->json : (
            ( next_page_token => $res->json->{next_page_token} ),
            map { delete $_->{symbol} => delete $_->{trades} } (
                Dict [ trades => ArrayRef [Trade], symbol => Str, next_page_token => Maybe [Str] ]
            )->assert_coerce( $res->json )
        );
    }

    sub trade_stream ( $s, $cb, %params ) {
        my $stream = Finance::Alpaca::TradeStream->new( cb => $cb );
        $stream->authorize( $s->ua, $s->keys, $s->paper )->catch(
            sub ($err) {
                $stream = ();
                warn "WebSocket error: $err";
            }
        )->wait;
        $stream;
    }

    sub data_stream ( $s, $cb, %params ) {
        my $stream = Finance::Alpaca::DataStream->new(
            cb     => $cb,
            source => delete $params{source} // 'iex'    # iex or sip
        );
        $stream->authorize( $s->ua, $s->keys )->catch(
            sub ($err) {
                $stream = ();
                warn "WebSocket error: $err";
            }
        )->wait;
        $stream;
    }

    sub orders ( $s, %params ) {
        for ( keys %params ) {
            $params{$_} = $params{$_}->to_string() if ref $params{$_} eq 'Time::Moment';
        }
        return @{
            ( ArrayRef [Order] )->assert_coerce(
                $s->ua->get( $s->endpoint . '/v2/orders' => form => {%params} )->result->json
            )
        };
    }

    sub order_by_id ( $s, $order_id, $nested = 0 ) {
        my $res
            = $s->ua->get(
            $s->endpoint . '/v2/orders/' . $order_id => form => ( $nested ? { nested => 1 } : () ) )
            ->result;
        return $res->is_error ? () : to_Order( $res->json );
    }

    sub order_by_client_id ( $s, $order_id ) {
        my $res
            = $s->ua->get( $s->endpoint
                . '/v2/orders:by_client_order_id' => form => { client_order_id => $order_id } )
            ->result;
        return $res->is_error ? () : to_Order( $res->json );
    }

    sub create_order ( $s, %params ) {
        $params{extended_hours} = ( !!$params{extended_hours} ) ? 'true' : 'false'
            if defined $params{extended_hours};
        my $res = $s->ua->post( $s->endpoint . '/v2/orders' => json => \%params )->result;
        return $res->is_error ? $res->json : to_Order( $res->json );
    }

    sub replace_order ( $s, $order_id, %params ) {
        $params{extended_hours} = ( !!$params{extended_hours} ) ? 'true' : 'false'
            if defined $params{extended_hours};
        my $res
            = $s->ua->patch( $s->endpoint . '/v2/orders/' . $order_id => json => \%params )->result;
        return $res->is_error ? $res->json : to_Order( $res->json );
    }

    sub cancel_orders ($s) {
        my $res = $s->ua->delete( $s->endpoint . '/v2/orders' )->result;
        return $res->is_error
            ? $res->json
            : ( ArrayRef [ Dict [ body => Order, id => Uuid, status => Int ] ] )
            ->assert_coerce( $res->json );
    }

    sub cancel_order ( $s, $order_id ) {
        my $res = $s->ua->delete( $s->endpoint . '/v2/orders/' . $order_id )->result;
        return !$res->is_error;
    }

    sub positions ($s) {
        return
            @{ ( ArrayRef [Position] )
                ->assert_coerce( $s->ua->get( $s->endpoint . '/v2/positions' )->result->json ) };
    }

    sub position ( $s, $symbol_or_asset_id ) {
        my $res = $s->ua->get( $s->endpoint . '/v2/positions/' . $symbol_or_asset_id )->result;
        return $res->is_error ? () : to_Position( $res->json );
    }

    sub close_all_positions ( $s, $cancel_orders = !1 ) {
        my $res
            = $s->ua->delete(
            $s->endpoint . '/v2/positions' . ( $cancel_orders ? '?cancel_orders=true' : '' ) )
            ->result;
        return $res->is_error
            ? $res->json
            : ( ArrayRef [ Dict [ body => Order, id => Uuid, status => Int ] ] )
            ->assert_coerce( $res->json );
    }

    sub close_position ( $s, $symbol_or_asset_id, $qty = () ) {
        my $res
            = $s->ua->get(
            $s->endpoint . '/v2/positions/' . $symbol_or_asset_id . ( $qty ? '?qty=' . $qty : '' ) )
            ->result;
        return $res->is_error ? () : to_Order( $res->json );
    }

    sub portfolio_history ( $s, %params ) {
        $params{extended_hours} = ( !!$params{extended_hours} ) ? 'true' : 'false'
            if defined $params{extended_hours};
        $params{date_end}
            = ref $params{date_end} eq 'Time::Moment'
            ? $params{date_end}->strftime('%F')
            : $params{date_end}
            if defined $params{date_end};
        my $res = $s->ua->get( $s->endpoint . '/v2/account/portfolio/history' => json => \%params )
            ->result;
        return $res->is_error ? $res->json : (
            Dict [
                base_value      => Num,
                equity          => ArrayRef [Num],
                profit_loss     => ArrayRef [Num],
                profit_loss_pct => ArrayRef [Num],
                timeframe       => Str,
                timestamp       => ArrayRef [Timestamp]
            ]
        )->assert_coerce( $res->json );
    }

    sub watchlists ($s) {
        return
            @{ ( ArrayRef [Watchlist] )
                ->assert_coerce( $s->ua->get( $s->endpoint . '/v2/watchlists' )->result->json ) };
    }

    sub create_watchlist ( $s, $name, @symbols ) {
        my $res
            = $s->ua->post( $s->endpoint
                . '/v2/watchlists' => json =>
                { name => $name, ( @symbols ? ( symbols => \@symbols ) : () ) } )->result;
        return $res->is_error ? ( $res->json ) : to_Watchlist( $res->json );
    }

    sub delete_watchlist ( $s, $watchlist_id ) {
        my $res = $s->ua->delete( $s->endpoint . '/v2/watchlists/' . $watchlist_id )->result;
        return $res->is_error ? $res->json : 1;
    }

    sub watchlist ( $s, $watchlist_id ) {
        my $res = $s->ua->get( $s->endpoint . '/v2/watchlists/' . $watchlist_id )->result;
        return $res->is_error ? ( $res->json ) : to_Watchlist( $res->json );
    }

    sub update_watchlist ( $s, $watchlist_id, %params ) {
        my $res
            = $s->ua->put( $s->endpoint . '/v2/watchlists/' . $watchlist_id => json => {%params} )
            ->result;
        return $res->is_error ? ( $res->json ) : to_Watchlist( $res->json );
    }

    sub add_to_watchlist ( $s, $watchlist_id, $symbol ) {
        my $res
            = $s->ua->post(
            $s->endpoint . '/v2/watchlists/' . $watchlist_id => json => { symbol => $symbol } )
            ->result;
        return $res->is_error ? ( $res->json ) : to_Watchlist( $res->json );
    }

    sub remove_from_watchlist ( $s, $watchlist_id, $symbol ) {
        my $res = $s->ua->delete( $s->endpoint . '/v2/watchlists/' . $watchlist_id . '/' . $symbol )
            ->result;
        return $res->is_error ? ( $res->json ) : to_Watchlist( $res->json );
    }

    sub configuration ($s) {
        my $res = $s->ua->get( $s->endpoint . '/v2/account/configurations' )->result;
        return $res->is_error ? ( $res->json ) : to_Configuration( $res->json );
    }

    sub modify_configuration ( $s, %params ) {
        my $res = $s->ua->patch( $s->endpoint . '/v2/account/configurations' => json => {%params} )
            ->result;
        return $res->is_error ? ( $res->json ) : to_Configuration( $res->json );
    }

    sub activities ( $s, %params ) {
        $params{activity_types} = join ',', @{ $params{activity_types} } if $params{activity_types};
        my $params = '';
        $params .= '?' . join '&', map {
            $_ . '='
                . (
                  ref $params{$_} eq 'Time::Moment' ? $params{$_}->to_string()
                : ref $params{$_} eq 'ARRAY'        ? @{ $params{$_} }
                :                                     $params{$_}
                )
        } keys %params if keys %params;
        my $res = $s->ua->get(
            sprintf $s->endpoint . '/v2/account/activities%s',
            $params ? $params : ''
        )->result;
        return $res->is_error
            ? $res->json
            : map { $_->{activity_type} eq 'FILL' ? to_TradeActivity($_) : to_Activity($_) }
            @{ $res->json };
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

Finance::Alpaca - Perl Wrapper for Alpaca's Commission-free Stock Trading API

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Finance::Alpaca allows you to buy, sell, and short U.S. stocks with zero
commissions with Alpaca, an API first, algo-friendly brokerage.

=head1 METHODS

=head2 C<new( ... )>

    my $camelid = Finance::Alpaca->new(
        keys => [ 'MDJOHHAE5BDE2FAYAEQT',
                  'Xq9p6ovxaa5XKihaEDRgpMapjeWYd5gIM63iq5BL'
                ] );

Creates a new Finance::Alpaca object.

This constructor accepts the following parameters:

=over

=item C<keys> - C<[ $APCA_API_KEY_ID, $APCA_API_SECRET_KEY ]>

Every API call requires authentication. You must provide these keys which may
be acquired in the developer web console and are only visible on creation.

=item C<paper> - Boolean value

If you're attempting to use Alpaca's paper trading system, this B<must> be a
true value. Otherwise, you will be making live trades with real assets!

B<Note>: This is a false value by default.

=back

=head2 C<account( )>

    my $acct = $camelid->account( );
    CORE::say sprintf 'I can%s short!', $acct->shorting_enabled ? '' : 'not';

Returns a L<Finance::Alpaca::Struct::Account> object.

The account endpoint serves important information related to an account,
including account status, funds available for trade, funds available for
withdrawal, and various flags relevant to an account’s ability to trade.

=head2 C<clock( )>

    my $clock = $camelid->clock();
    say sprintf
        $clock->timestamp->strftime('It is %l:%M:%S %p on a %A and the market is %%sopen!'),
        $clock->is_open ? '' : 'not ';

Returns a L<Finance::Alpaca::Struct::Clock> object.

The clock endpoint serves the current market timestamp, whether or not the
market is currently open, as well as the times of the next market open and
close.

=head2 C<calendar( [...] )>

        my @days = $camelid->calendar(
            start => Time::Moment->now,
            end   => Time::Moment->now->plus_days(14)
        );
        for my $day (@days) {
            say sprintf '%s the market opens at %s Eastern',
                $day->date, $day->open;
        }

Returns a list of L<Finance::Alpaca::Struct::Calendar> objects.

The calendar endpoint serves the full list of market days from 1970 to 2029.

The following parameters are accepted:

=over

=item C<start> - The first date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

=item C<end> - The last date to retrieve data for (inclusive); Time::Moment object or RFC3339 string

=back

Both listed parameters are optional. If neither is provided, the calendar will
begin on January 1st, 1970.

=head2 C<assets( [...] )>

    say $_->symbol
        for sort { $a->symbol cmp $b->symbol } @{ $camelid->assets( status => 'active' ) };

Returns a list of L<Finance::Alpaca::Struct::Asset> objects.

The assets endpoint serves as the master list of assets available for trade and
data consumption from Alpaca.

The following parameters are accepted:

=over

=item C<status> - e.g. C<active> or C<inactive>. By default, all statuses are included

=item C<asset_class> - Defaults to C<us_equity>

=back

=head2 C<asset( ... )>

    my $msft = $camelid->asset('MSFT');
    my $spy  = $camelid->asset('b28f4066-5c6d-479b-a2af-85dc1a8f16fb');

Returns a L<Finance::Alpaca::Struct::Asset> object.

You may use either the asset's C<id> (UUID) or C<symbol>. If the asset is not
found, an empty list is returned.

=head2 C<bars( ... )>

  my %bars = $camelid->bars(
        symbol    => 'MSFT',
        timeframe => '1Min',
        start     => Time::Moment->now->with_hour(10),
        end       => Time::Moment->now->minus_minutes(20)
    );

Returns a list of L<Finance::Alpaca::Struct::Bar> objects along with other
data.

The bar endpoint serves aggregate historical data for the requested securities.

The following parameters are accepted:

=over

=item C<symbol> - The symbol to query for; this is required

=item C<start> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<end> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<limit> - Number of data points to return. Must be in range C<1-10000>, defaults to C<1000>

=item C<page_token> - Pagination token to continue from

=item C<timeframe> - Timeframe for the aggregation. Available values are: C<1Min>, C<1Hour>, and C<1Day>; this is required

=back

The method returns a hash reference with bar data included as a list under the
symbol as well as a C<next_page_token> for pagination if applicable.

=head2 C<quotes( ... )>

    my %quotes = $camelid->quotes(
        symbol => 'MSFT',
        start  => Time::Moment->now->with_hour(10),
        end    => Time::Moment->now->minus_minutes(20)
    );

Returns a list of L<Finance::Alpaca::Struct::Quote> objects along with other
data.

The bar endpoint serves quote (NBBO) historical data for the requested
security.

The following parameters are accepted:

=over

=item C<symbol> - The symbol to query for; this is required

=item C<start> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<end> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<limit> - Number of data points to return. Must be in range C<1-10000>, defaults to C<1000>

=item C<page_token> - Pagination token to continue from

=back

The method returns a hash reference with quote data included as a list under
the symbol as well as a C<next_page_token> for pagination if applicable.

=head2 C<trades( ... )>

    my %trades = $camelid->trades(
        symbol => 'MSFT',
        start  => Time::Moment->now->with_hour(10),
        end    => Time::Moment->now->minus_minutes(20)
    );

Returns a list of L<Finance::Alpaca::Struct::Trade> objects along with other
data.

The bar endpoint serves historical trade data for a given ticker symbol on a
specified date.

The following parameters are accepted:

=over

=item C<symbol> - The symbol to query for; this is required

=item C<start> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<end> - Filter data equal to or before this time in RFC-3339 format or a Time::Moment object. Fractions of a second are not accepted; this is required

=item C<limit> - Number of data points to return. Must be in range C<1-10000>, defaults to C<1000>

=item C<page_token> - Pagination token to continue from

=back

The method returns a hash reference with trade data included as a list under
the symbol as well as a C<next_page_token> for pagination if applicable.


=head2 C<trade_stream( ... )>

    my $stream = $camelid->trade_stream( sub ($packet) {  ... } );

Returns a new L<Finance::Alpaca::TradeStream> object.

You are ready to receive real-time account and order data!

This method expects a code reference. This callback will receive all incoming
data.

=head2 C<data_stream( ... )>

    my $stream = $camelid->data_stream( sub ($packet) {  ... } );
    $stream->subscribe(
        trades => ['MSFT']
    );

Returns a new L<Finance::Alpaca::DataStream> object.

You are ready to receive real-time market data!

You can send one or more subscription messages (described in
L<Finance::Alpaca::DataStream>) and after confirmation you will receive the
corresponding market data.

This method expects a code reference. This callback will receive all incoming
data.

=head2 C<orders( [...] )>

    my @orders = $camelid->orders( status => 'open' );

Returns a list of L<Finance::Alpaca::Struct::Order> objects.

The orders endpoint returns a list of orders for the account, filtered by the
supplied parameters.

The following parameters are accepted:

=over

=item C<status> - Order status to be queried. C<open>, C<closed>, or C<all>. Defaults to C<open>.

=item C<limit> - The maximum number of orders in response. Defaults to C<50> and max is C<500>.

=item C<after> - The response will include only ones submitted after this timestamp (exclusive.)

=item C<until> - The response will include only ones submitted until this timestamp (exclusive.)

=item C<direction> - The chronological order of response based on the submission time. C<asc> or C<desc>. Defaults to C<desc>.

=item C<nested> - Boolean value indicating whether the result will roll up multi-leg orders under the C<legs( )> field of the primary order.

=item C<symbols> - A comma-separated list of symbols to filter by (ex. C<AAPL,TSLA,MSFT>).

=back

=head2 C<order_by_id( ..., [...] )>

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4');

Returns a L<Finance::Alpaca::Struct::Order> object.

You must provide the order's C<id> (UUID). If the order is not found, an empty
list is returned.

You may also provide a boolean value; if true, the result will roll up
multi-leg orders under the C<legs( )> field in primary order.

    my $order = $camelid->order_by_id('0f43d12c-8f13-4bff-8597-c665b66bace4', 1);

=head2 C<order_by_client_id( ... )>

    my $order = $camelid->order_by_client_id('17ff6b86-d330-4ac1-808b-846555b75b6e');

Returns a L<Finance::Alpaca::Struct::Order> object.

You must provide the order's C<client_order_id> (UUID). If the order is not
found, an empty list is returned.

=head2 C<create_order( ... )>

    my $order = $camelid->create_order(
        symbol => 'MSFT',
        qty    => .1,
        side   => 'buy',
        type   => 'market',
        time_in_force => 'day'
    );

If the order is placed successfully, this method returns a
L<Finance::Alpaca::Struct::Order> object. Failures result in hash references
with data from the API.

An order request may be rejected if the account is not authorized for trading,
or if the tradable balance is insufficient to fill the order.

The following parameters are accepted:

=over

=item C<symbol> - symbol or asset ID to identify the asset to trade (Required)

=item C<qty> - number of shares to trade. Can be fractionable for only C<market> and C<day> order types (Required)

=item C<notional> -dollar amount to trade. Cannot work with qty. Can only work for C<market> order types and C<day> for time in force (Required)

=item C<side> - C<buy> or C<sell> (Required)

=item C<type> - C<market>, C<limit>, C<stop>, C<stop_limit>, or C<trailing_stop> (Required)

=item C<time_in_force> - C<day>, C<gtc>, C<opg>, C<cls>, C<ioc>, C<fok>. Please see L<Understand Orders|https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force> for more info (Required)

=item C<limit_price> - Required if C<type> is C<limit> or C<stop_limit>

=item C<stop_price> - Required if C<type> is C<stop> or C<stop_limit>

=item C<trail_price> - This or C<trail_percent> is required if C<type> is C<trailing_stop>

=item C<trail_percent> - This or C<trail_price> is required if C<type> is C<trailing_stop>

=item C<extended_hours> - If a C<true> value, order will be eligible to execute in premarket/afterhours. Only works with C<type> is C<limit> and C<time_in_force> is C<day>

=item C<client_order_id> - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.

=item C<order_class> - C<simple>, C<bracket>, C<oco> or C<oto>. For details of non-simple order classes, please see L<Bracket Order Overview|https://alpaca.markets/docs/trading-on-alpaca/orders#bracket-orders>

=item C<take_profit> - Additional parameters for C<take_profit> leg of advanced orders

=over

=item C<limit_price> - Required for bracket orders

=back

=item C<stop_loss> - Additional parameters for stop-loss leg of advanced orders

=over

=item C<stop_price> - Required for bracket orders

=item C<limit_price> - The stop-loss order becomes a stop-limit order if specified

=back

=back

=head2 C<replace_order( ..., ... )>

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
rejected, and these events are sent in the trade_updates stream channel.

While an order is being replaced, buying power is reduced by the larger of the
two orders that have been placed (the old order being replaced, and the newly
placed order to replace it). If you are replacing a buy entry order with a
higher limit price than the original order, the buying power is calculated
based on the newly placed order. If you are replacing it with a lower limit
price, the buying power is calculated based on the old order.

In addition to the original order's ID, this method expects the following
parameters:

=over

=item C<qty> - number of shares to trade

=item C<time_in_force> - C<day>, C<gtc>, C<opg>, C<cls>, C<ioc>, C<fok>. Please see L<Understand Orders|https://alpaca.markets/docs/trading-on-alpaca/orders/#time-in-force> for more info

=item C<limit_price> - required if C<type> is C<limit> or C<stop_limit>

=item C<stop_price> - required if C<type> is C<stop> or C<stop_limit>

=item C<trail> - the new value of the C<trail_price> or C<trail_percent> value (works only where C<type> is C<trailing_stop>)

=item C<client_order_id> - A unique identifier (UUID v4) for the order. Automatically generated by Alpaca if not sent.

=back

=head2 C<cancel_orders( )>

    $camelid->cancel_orders( );

Attempts to cancel all open orders.

On success, an array of hashes will be returned each with the following
elements:

=over

=item C<body> - Finance::Alpaca::Struct::Order object

=item C<id> - the order ID (UUID)

=item C<status> - HTTP status code for the request

=back

A response will be provided for each order that is attempted to be cancelled.
If an order is no longer cancelable, the server will reject the request and and
empty list will be returned.

=head2 C<cancel_order( ... )>

    $camelid->cancel_order( 'be07eebc-13f0-4072-aa4c-f67046081276' );

Attempts to cancel an open order. If the order is no longer cancelable
(example: C<status> is C<filled>), the server will respond with status 422,
reject the request, and an empty list will be returned. Upon acceptance of the
cancel request, it returns status 204 and a true value.

=head2 C<positions( )>

    $camelid->positions( );

Retrieves a list of the account’s open positions and returns a list of
L<Finance::Alpaca::Struct::Position> objects.

=head2 C<position( ... )>

    my $elon = $camelid->position( 'TSLA' );
    my $msft = $camelid->position( 'b6d1aa75-5c9c-4353-a305-9e2caa1925ab' );

Retreves the account's open position for the given symbol or asset ID and
returns a L<Finance::Alpaca::Struct::Position> object if found.

If not found, and empty list is returned.

=head2 C<close_all_positions( [...] )>

    my $panic = $camelid->close_all_positions( );

Closes (liquidates) all of the account’s open long and short positions.

    $panic = $camelid->close_all_positions( 1 );

This method accepts one optional parameter which, if true, will cancel all open
orders before liquidating all positions.

On success, an array of hashes will be returned each with the following
elements:

=over

=item C<body> - L<Finance::Alpaca::Struct::Order> object

=item C<id> - the order ID (UUID)

=item C<status> - HTTP status code for the request

=back

A response will be provided for each position that is attempted to be closed.

=head2 C<close_position( ..., [...] )>

    my $order = $camelid->close_position('MSFT');
    $order    = $camelid->close_position( 'b6d1aa75-5c9c-4353-a305-9e2caa1925ab' );

Closes (liquidates) the account’s open position for the given symbol or asset
ID and returns a L<Finance::Alpaca::Struct::Order> object. Works for both long
and short positions.

    my $order = $camelid->close_position('MSFT', 0.5);

This method accepts a second, optional parameter which is the number of shares
to liquidate.

=head2 C<portfolio_history( [...] )>

    $camelid->portfolio_history( );

The portfolio history API returns the timeseries data for equity and profit
loss information of the account.

    $camelid->portfolio_history( period => '2W' );

This method accepts the following optional parameters:

=over

=item C<period> - The duration of the data in C<E<lt>numberE<gt> + E<lt>unitE<gt>>, such as 1D, where <unit> can be D for day, C<W> for week, C<M> for month and C<A> for year. Defaults to C<1M>

=item C<timeframe> - The resolution of time window. C<1Min>, C<5Min>, C<15Min>, C<1H>, or C<1D>. If omitted, C<1Min> for less than 7 days period, C<15Min> for less than 30 days, or otherwise C<1D>

=item C<date_end> - The date the data is returned up to, in C<YYYY-MM-DD> format or as a Time::Moment object. Defaults to the current market date (rolls over at the market open if C<extended_hours> is false, otherwise at 7am ET)

=item C<extended_hours> Boolean value; if true, include extended hours in the result. This is effective only for timeframe less than C<1D>.

=back

The returned data is in a hash ref with the following keys:

=over

=item C<timestamp> - List of Time::Moment objects; the time of each data element, left-labeled (the beginning of the window)

=item C<equity> - List of numbers; equity values of the account in dollar amounts as of the end of each time window

=item C<profit_loss> - List of numbers; profit/loss in dollar from the base value

=item C<profit_loss_pct> - List of numbers; profit/loss in percentage from the base value

=item C<base_value> - basis in dollar of the profit loss calculation

=item C<timeframe> - time window size of each data element

=back

=head2 C<watchlists( )>

    my @watchlists = $camelid->watchlists;

Returns the list of watchlists registered under the account as
L<Finance::Alpaca::Struct::Watchlist> objects.

=head2 C<create_watchlist( ..., [...] )>

    my $new_watchlist = $camelid->create_watchlist( 'Leveraged ETFs' );
    my $tech_watchlist = $camelid->create_watchlist( 'FAANG', qw[FB AMZN AAPL NFLX GOOG] );

Create a new watchlist potentially with an initial set of assets. Only the
first parameter is required and is the name of the user-defined new watchlist.
This name must be a maximum of C<64> characters. To add assets to the watchlist
on create, include a list of ticker symbols.

On success, the related L<Finance::Alpaca::Struct::Watchlist> object is
returned.

=head2 C<delete_watchlist( ... )>

    $camelid->delete_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678' );

Delete a watchlist identified by the ID. This is a permanent deletion.

=head2 C<watchlist( ... )>

    $camelid->watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678' );

Returns a watchlist identified by the ID.

=head2 C<update_watchlist( ... )>

    $camelid->update_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678', name => 'Low priority' );
    $camelid->update_watchlist( '29d85812-b4a2-45da-ac6c-dcc0ad9c1cd3', symbols => [qw[MA V]] );

Update the name and/or content of watchlist. On success, a
L<Finance::Alpaca::Struct::Watchlist> object is returned.

=head2 C<add_to_watchlist( ... )>

    $camelid->add_to_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678', 'TSLA');

Append an asset for the symbol to the end of watchlist asset list. On success,
a L<Finance::Alpaca::Struct::Watchlist> object is returned.

=head2 C<remove_from_watchlist( ... )>

    $camelid->remove_from_watchlist( '88f0c1e1-58d4-42c5-b85b-864839045678', 'F');

Delete one entry for an asset by symbol name. On success, a
L<Finance::Alpaca::Struct::Watchlist> object is returned.

=head2 C<configuration( )>

    my $confs = $camelid->configuration( );

Returns the current account configuration values.

=head2 C<modify_configuration( )>

    $confs = $camelid->modify_configuration(
        trade_confirm_email=> 'all'
    );

Updates the account configuration values. On success, the modified
configuration is returned.

=head2 C<activities( [...] )>

    my @activities = $camelid->activities();

Returns account activity entries for many types of activities.

    @activities = $camelid->activities(activity_types => [qw[ACATC ACATS]]);

Returns account activity entries for a set of specific types of activity. See
L<Finance::Alpaca::Struct::Activity> for a list of activity types.

This method expects a combination of the following optional parameters:

=over

=item C<activity_types> - A list of the activity types to include in the response. If unspecified, activities of all types will be returned.

=item C<date> - The date for which you want to see activities as string or Time::Moment object

=item C<until> - The response will contain only activities submitted before this date. (Cannot be used with C<date>.)

=item C<after> - The response will contain only activities submitted after this date. (Cannot be used with C<date>.)

=item C<direction> - C<asc> or C<desc> (default is C<desc> if unspecified.)

=item C<page_size> - The maximum number of entries to return in the response

=item C<page_token> - The ID of the end of your current page of results

=back

=head1 Paging of Results

When required, pagination is handled using the C<page_token> and C<page_size>
parameters. C<page_token> represents the ID of the end of your current page of
results. If specified with a direction of C<desc>, for example, the results
will end before the activity with the specified ID. If specified with a
direction of C<asc>, results will begin with the activity immediately after the
one specified. C<page_size> is the maximum number of entries to return in the
response. If C<date> is not specified, the default and maximum value is C<100>.
If C<date> is specified, the default behavior is to return all results, and
there is no maximum page size.

=head1 See Also

L<https://alpaca.markets/docs/api-documentation/api-v2/>

=head1 Note

I do not have a live trading account with Alpaca but this package has worked
well with paper trading. YMMV.

=head1 LEGAL

This is a simple wrapper around the API as described in documentation. The
author provides no investment, legal, or tax advice and is not responsible for
any damages incurred while using this software. This software is not affiliated
with Alpaca Securities LLC in any way.

For Alpaca's terms and disclosures, please see their website at
https://alpaca.markets/disclosures

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords algo-friendly fractionable watchlist watchlists timeframe timeseries qty website

=cut
