package Finance::Nadex;

use strict;
use warnings;
our $VERSION = '0.07';

use LWP::UserAgent;
use JSON;
use Carp;
use Finance::Nadex::Order;
use Finance::Nadex::Position;
use Finance::Nadex::Contract;

use constant LOGIN_URL              => '/iDeal/v2/security/authenticate';
use constant SEND_ORDER_URL         => '/iDeal/dma/workingorders';
use constant RETRIEVE_ORDERS_URL    => '/iDeal/orders/workingorders';
use constant RETRIEVE_ORDER_URL     => '/iDeal/markets/details/workingorders';
use constant CANCEL_ORDER_URL       => '/iDeal/orders/workingorders/dma';
use constant RETRIEVE_POSITIONS_URL => '/iDeal/orders/positions';
use constant RETRIEVE_POSITION_URL  => '/iDeal/markets/details/position';
use constant EPIC_URL               => '/iDeal/markets/details';
use constant MARKET_LIST_URL        => '/iDeal/markets/navigation';

my $session_id;

# allows caller to use aliases for the market names in addition to those used by the exchange
my %index_name = (
    'FTSE100', 'FTSE 100',  'G30',     'Germany 30',
    'J225',    'Japan 225', 'TECH100', 'US Tech 100',
    'US500',   'US 500',    'WALL30',  'Wall St 30',
    'SC2000',  'US SmallCap 2000'
);

sub balance {

    my $self = shift;

    croak "ERROR: Finance::Nadex::balance(): must be logged in\n"
      unless $self->logged_in;

    # it appears the only way to force a
    # balance refresh is to login again
    $self->login();

    return $self->{'balance'} || undef;

}

sub cancel_all_orders {

    my $self = shift;

    croak "ERROR: Finance::Nadex::cancel_all_orders(): must be logged in\n"
      unless $self->logged_in;
    my @orders = $self->retrieve_orders();

    return if !scalar @orders;

    foreach my $order_entry (@orders) {
        $self->cancel_order( id => $order_entry->id );
    }

}

sub cancel_order {

    my $self = shift;
    my %args = @_;

    croak "ERROR: Finance::Nadex::cancel_order(): must be logged in\n"
      unless $self->logged_in;
    croak
"ERROR: Finance::Nadex::cancel_order(): must specify a named argument 'id'\n"
      unless exists $args{id};
    croak "ERROR: Finance::Nadex::cancel_order(): invalid id\n"
      unless $args{id};

    my $deal_id = $args{id};

    my $cancel_order_url = $self->{base_url}.CANCEL_ORDER_URL . '/' . $deal_id;

    my $cancel_time    = time;
    my $cancel_content = qq~
                           {
                            "lsServerName": "https://mdp.nadex.com:443",
                            "timeStamp": "$cancel_time"
                           }~;

    my $cancelled_response =
      $self->_delete( $cancel_order_url, $cancel_content );

    return undef unless $cancelled_response;

    return $cancelled_response->{'dealReference'};
}

sub create_order {

    my $self = shift;
    my %args = @_;

    my $order_time = time;

    croak "ERROR: Finance::Nadex::create_order(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::create_order(): must specify a named argument 'price'\n"
      unless exists $args{price};
    croak
"ERROR: Finance::Nadex::create_order(): must specify a named argument 'direction'\n"
      unless exists $args{direction};
    croak
"ERROR: Finance::Nadex::create_order(): must specify a named argument 'epic'\n"
      unless exists $args{epic};
    croak
"ERROR: Finance::Nadex::create_order(): must specify a named argument 'size'\n"
      unless exists $args{size};

    $args{direction} = lc( $args{direction} );

    croak "ERROR: Finance::Nadex::create_order(): invalid epic\n"
      unless $args{epic};

    my $contract = $self->get_contract( epic => $args{epic} );

    croak
"ERROR: Finance::Nadex::create_order(): named argument 'price' (->$args{price}<-) is not valid\n"
      unless $self->_is_valid_price( $args{price}, $contract->type );
    croak
"ERROR: Finance::Nadex::create_order(): named argument 'direction' (->$args{direction}<-) is not valid\n"
      unless $self->_is_valid_direction( $args{direction} );
    croak
"ERROR: Finance::Nadex::create_order(): named argument 'epic' (->$args{epic}<-) is not valid\n"
      unless $contract;
    croak
"ERROR: Finance::Nadex::create_order(): named argument 'size' (->$args{size}<-) is not valid\n"
      unless $self->_is_valid_size( $args{size} );

# the market accepts only + or - for the direction; this enables the aliases 'buy' and 'sell'
    $args{direction} = '+' if $args{direction} eq 'buy';
    $args{direction} = '-' if $args{direction} eq 'sell';

# the price is dollars and cents for binaries and some instrument level
# for spreads; only format the price to a currency if the order type is 'binary'
    $args{price} = sprintf( "%.2f", $args{price} )
      if $contract->type eq 'binary';

    my $order_content = qq~
    {
        "direction": "$args{direction}",
        "epic": "$args{epic}",
        "limitLevel": null,
        "lsServerName": "https://mdp.nadex.com:443",
        "orderLevel": "$args{price}",
        "orderSize": "$args{size}",
        "orderType": "Limit",
        "sizeForPandLCalculation": $args{size},
        "stopLevel": null,
        "timeInForce": "GoodTillCancelled",
        "timeStamp": "$order_time"

    }~;

    my $order = $self->_post( $self->{base_url}.SEND_ORDER_URL, $order_content );

    my $deal_reference_id = $order->{dealReference} if defined $order;

    return $deal_reference_id;
}

sub get_contract {

    my $self = shift;
    my %args = @_;

    croak "ERROR: Finance::Nadex::get_contracts(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::get_contract(): must specify a named argument 'epic'\n"
      unless exists $args{epic};
    croak
"ERROR: Finance::Nadex::get_contract(): specified 'epic' (->$args{epic}<-) is not valid\n"
      unless $args{epic};

    my $epic_url = $self->{base_url}.EPIC_URL . '/' . $args{epic};
    my $epic_ref = $self->_get($epic_url);

    return unless $epic_ref;

    return
      unless exists $epic_ref->{instrument}
      && exists $epic_ref->{marketSnapshot};
    return
         unless $epic_ref->{instrument}{instrumentType}
      && $epic_ref->{instrument}{marketName}
      && $epic_ref->{instrument}{displayPrompt};

    return Finance::Nadex::Contract::_new(
        {
            instrumentType   => $epic_ref->{instrument}{instrumentType},
            epic             => $args{epic},
            displayOffer     => $epic_ref->{marketSnapshot}{displayOffer},
            displayBid       => $epic_ref->{marketSnapshot}{displayBid},
            displayBidSize   => $epic_ref->{marketSnapshot}{displayBidSize},
            displayOfferSize => $epic_ref->{marketSnapshot}{displayOfferSize},
            instrumentName   => $epic_ref->{instrument}{marketName},
            displayPeriod    => $epic_ref->{instrument}{displayPrompt}
        }
    );

}

sub get_contracts {

    my $self = shift;
    my %args = @_;
    my $found;

    croak "ERROR: Finance::Nadex::get_contracts(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::get_contracts(): must specify a named argument 'market'\n"
      unless exists $args{market};
    croak
"ERROR: Finance::Nadex::get_contracts(): must specify a named argument 'instrument'\n"
      unless exists $args{instrument};
    croak
"ERROR: Finance::Nadex::get_conttracts(): must specify a named argument 'series'\n"
      unless exists $args{series};

    croak "ERROR: Finance::Nadex::get_contracts(): invalid market\n"
      unless $args{market};
    croak "ERROR: Finance::Nadex::get_contracts(): invalid instrument\n"
      unless $args{instrument};
    croak "ERROR: Finance::Nadex::get_conttracts(): invalid series\n"
      unless $args{series};

    $args{instrument} = $index_name{ $args{instrument} }
      if exists $index_name{ $args{instrument} };

    my $market_list_ref = $self->_get($self->{base_url}.MARKET_LIST_URL);

    die
"ERROR: Finance::Nadex::get_contracts(): failed to retrieve the market list from the exchange\n"
      if !$market_list_ref;

    my $market_id = $self->_get_market_id(
        name            => $args{market},
        market_list_ref => $market_list_ref
    );

    return unless $market_id;

    my $instruments_list_ref =
      $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $market_id );

    die
"ERROR: Finance::Nadex::get_contracts(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$instruments_list_ref;

    my $instrument_id;
    foreach my $instrument ( @{ $instruments_list_ref->{'hierarchy'} } ) {
        $instrument_id = $instrument->{id}
          if $instrument->{name} eq $args{instrument};
    }

    return unless $instrument_id;

    my $instrument_list_ref =
      $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $instrument_id );

    die
"ERROR: Finance::Nadex::get_contracts(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$instrument_list_ref;

    my $time_series_id;
    foreach my $series ( @{ $instrument_list_ref->{'hierarchy'} } ) {
        $time_series_id = $series->{id} if $series->{name} eq $args{series};
    }

    return unless $time_series_id;

    my @contracts;
    my $series_list_ref =
      $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $time_series_id );

    die
"ERROR: Finance::Nadex::get_contracts(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$series_list_ref;

    foreach my $contract ( @{ $series_list_ref->{'markets'} } ) {
        push( @contracts, Finance::Nadex::Contract::_new($contract) );
    }

    return @contracts;
}

sub get_epic {

    my $self = shift;
    my %args = @_;

    my $market_id;
    my $instrument;

    croak "ERROR: Finance::Nadex::get_epic(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::get_epic(): must specify a named argument 'period'\n"
      unless exists $args{period};
    croak
"ERROR: Finance::Nadex::get_epic(): must specify a named argument 'market'\n"
      unless exists $args{market};
    croak
"ERROR: Finance::Nadex::get_epic(): must specify a named argument 'time'\n"
      unless exists $args{time}
      || ( exists $args{period}
        && $args{period} =~ /^event$/i );
    croak
"ERROR: Finance::Nadex::get_epic(): must specify a named argument 'instrument'\n"
      unless exists $args{instrument};
    croak
"ERROR: Finance::Nadex::get_epic(): must specify a named argument 'strike'\n"
      unless exists $args{strike};

    croak "ERROR: Finance::Nadex::get_epic(): invalid period\n"
      unless $args{period};
    croak "ERROR: Finance::Nadex::get_epic(): invalid market\n"
      unless $args{market};
    croak "ERROR: Finance::Nadex::get_epic(): invalid time\n"
      unless $args{time}
      || ( exists $args{period}
        && $args{period} =~ /^event$/i );
    croak "ERROR: Finance::Nadex::get_epic(): invalid instrument\n"
      unless $args{instrument};
    croak "ERROR: Finance::Nadex::get_epic(): invalid strike\n"
      unless $args{strike};

    $args{period} = ucfirst( lc( $args{period} ) ) if exists $args{period};

    $args{time} = lc( $args{time} ) if exists $args{time};

    my $market_list_ref = $self->_get($self->{base_url}.MARKET_LIST_URL);

    die
"ERROR: Finance::Nadex::get_epic(): failed to retrieve the market list from the exchange\n"
      if !$market_list_ref;

    $market_id = $self->_get_market_id(
        name            => $args{market},
        market_list_ref => $market_list_ref
    );

    return undef unless $market_id;

    $market_list_ref = $self->_get( $self->{base_url}.MARKET_LIST_URL . "/$market_id" );

    die
"ERROR: Finance::Nadex::get_epic(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$market_list_ref;

    $market_id = $self->_get_market_id(
        name            => $args{instrument},
        market_list_ref => $market_list_ref
    );

    return undef unless $market_id;

    $market_list_ref = $self->_get( $self->{base_url}.MARKET_LIST_URL . "/$market_id" );

    die
"ERROR: Finance::Nadex::get_epic(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$market_list_ref;

    my $target_period_time;

    $target_period_time = "$args{period} ($args{time})"
      if $args{period} eq 'Daily';
    $target_period_time = "-$args{time}"  if $args{period} eq 'Intraday';
    $target_period_time = "$args{period}" if $args{period} eq 'Weekly';
    $target_period_time = "Open"          if $args{period} eq 'Event';

    croak
"ERROR: Finance::Nadex::get_epic(): invalid period; must be one of: daily, weekly, intraday, event\n"
      if !$target_period_time;

    $market_id = $self->_get_market_id(
        name            => $target_period_time,
        market_list_ref => $market_list_ref,
        accept_match    => 1
    );

    return undef unless $market_id;

    $market_list_ref = $self->_get( $self->{base_url}.MARKET_LIST_URL . "/$market_id" );

    die
"ERROR: Finance::Nadex::get_epic(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$market_list_ref;

    my $epic;
    foreach my $market ( @{ $market_list_ref->{'markets'} } ) {
        $args{time} = uc( $args{time} ) if exists $args{time};
        $args{time} = "" if !exists $args{time};
        if ( $market->{instrumentName} =~ /$args{strike}( \($args{time}\))?$/ )
        {
            $epic = $market->{epic};
            last;
        }
    }

    return $epic;

}

sub get_market_instruments {

    my $self = shift;
    my %args = @_;

    croak "ERROR: Finance::Nadex::get_market_instruments(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::get_market_instruments(): must provide market as named argument 'name'\n"
      unless exists $args{name};
    croak
      "ERROR: Finance::Nadex::get_market_instruments(): invalid market name\n"
      unless $args{name};

    my $market_list_ref = $self->_get($self->{base_url}.MARKET_LIST_URL);

    die
"ERROR: Finance::Nadex::get_market_instruments(): failed to retrieve the market list from the exchange\n"
      if !$market_list_ref;

    my $market_id = $self->_get_market_id(
        name            => $args{name},
        market_list_ref => $market_list_ref
    );

    return unless $market_id;

    $market_list_ref = $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $market_id );

    die
"ERROR: Finance::Nadex::get_market_instruments(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$market_list_ref;

    my @instruments;
    foreach my $market ( @{ $market_list_ref->{'hierarchy'} } ) {
        push( @instruments, $market->{name} );
    }
    return @instruments;
}

sub get_markets {

    my $self = shift;

    croak "ERROR: Finance::Nadex::get_markets(): must be logged in\n"
      unless $self->logged_in;

    my $market_list_ref = $self->_get($self->{base_url}.MARKET_LIST_URL);

    die
"ERROR: Finance::Nadex::get_markets(): failed to retrieve the market list from the exchange\n"
      if !$market_list_ref;

    my @markets;
    foreach my $market ( @{ $market_list_ref->{'hierarchy'} } ) {
        push( @markets, $market->{name} );
    }

    return @markets;
}

sub get_quote {

    my $self = shift;
    my %args = @_;

    croak "ERROR: Finance::Nadex::get_quote(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::get_quote(): must specify a named argument 'instrument'\n"
      unless exists $args{instrument};
    croak "ERROR: Finance::Nadex::get_quote(): invalid instrument\n"
      unless $args{instrument};

    $args{instrument} = $index_name{ $args{instrument} }
      if exists $index_name{ $args{instrument} };

    my @markets = $self->get_markets();
    foreach my $market (@markets) {
        my @instruments = $self->get_market_instruments( name => $market );
        foreach my $instrument (@instruments) {
            if ( $instrument eq $args{instrument} ) {
                my ($series) = $self->get_time_series(
                    market     => $market,
                    instrument => $instrument
                );
                my ($contract) = $self->get_contracts(
                    market     => $market,
                    instrument => $instrument,
                    series     => $series
                );
                my $epic_url = $self->{base_url}.EPIC_URL . '/' . $contract->epic;
                my $epic_ref = $self->_get($epic_url);

                return undef unless $epic_ref;

                die
"ERROR: Finance::Nadex::get_quote(): failed to retrieve the market list from the exchange for epic $args{epic}\n"
                  if !$epic_ref;
                return $epic_ref->{instrument}->{underlyingIndicativePrice};
            }
        }
    }
}

sub get_time_series {

    my $self = shift;
    my %args = @_;
    my $found;

    croak "ERROR: Finance::Nadex::get_time_series(): must be logged in\n"
      unless $self->logged_in;

    $args{instrument} = $index_name{ $args{instrument} }
      if exists $args{instrument} && $index_name{ $args{instrument} };

    croak
"ERROR: Finance::Nadex::get_time_series(): must specify a named argument 'market'\n"
      unless exists $args{market};
    croak
"ERROR: Finance::Nadex::get_time_series(): must specify a named argument 'instrument'\n"
      unless exists $args{instrument};

    my $market_list_ref = $self->_get($self->{base_url}.MARKET_LIST_URL);

    die
"ERROR: Finance::Nadex::get_time_series(): failed to retrieve the market list from the exchange\n"
      if !$market_list_ref;

    my $market_id = $self->_get_market_id(
        name            => $args{market},
        market_list_ref => $market_list_ref
    );

    return unless $market_id;

    my $instruments_list_ref =
      $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $market_id );

    die
"ERROR: Finance::Nadex::get_time_series(): failed to retrieve the market list from the exchange for market $market_id\n"
      if !$market_list_ref;

    my $instrument_id;
    foreach my $instrument ( @{ $instruments_list_ref->{'hierarchy'} } ) {
        $instrument_id = $instrument->{id}
          if $instrument->{name} eq $args{instrument};
        $instrument_id = $instrument->{id}
          if $instrument->{name} eq 'Forex'
          && $args{market} eq '5 Minute Binaries';
        $instrument_id = $instrument->{id}
          if $instrument->{name} eq 'Indices'
          && $args{market} eq '20 Minute Binaries';
    }

    return unless $instrument_id;

    my $instrument_list_ref =
      $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $instrument_id );

    die
"ERROR: Finance::Nadex::get_time_series(): failed to retrieve the market list from the exchange for market $instrument_id\n"
      if !$market_list_ref;

    if (   $args{market} eq '5 Minute Binaries'
        || $args{market} eq '20 Minute Binaries' )
    {
        my @instruments;
        foreach my $instrument ( @{ $instrument_list_ref->{'hierarchy'} } ) {
            $instrument_id = $instrument->{id}
              if $instrument->{name} eq $args{instrument};
        }

        return unless $instrument_id;

        $instrument_list_ref =
          $self->_get( $self->{base_url}.MARKET_LIST_URL . '/' . $instrument_id );

        die
"ERROR: Finance::Nadex::get_time_series(): failed to retrieve the market list from the exchange for market $instrument_id\n"
          if !$market_list_ref;

        my @contracts;
        foreach my $contract ( @{ $instrument_list_ref->{'markets'} } ) {
            push( @contracts, Finance::Nadex::Contract::_new($contract) );
        }
        return @contracts;

    }

    my @time_series;
    foreach my $series ( @{ $instrument_list_ref->{'hierarchy'} } ) {
        push( @time_series, $series->{name} );
    }

    return @time_series;

}

sub logged_in {

    my $self = shift;

    return 0 unless $self->{security_token};

    return 0 unless $self->{session_id};

    return 1;

}

sub login {

    my $self = shift;
    my %args = @_;

    croak
"ERROR: Finance::Nadex::login(): must specify a named argument 'username'\n"
      unless exists $args{username} || exists $self->{username};
    croak
"ERROR: Finance::Nadex::login(): must specify a named argument 'password'\n"
      unless exists $args{password} || exists $self->{password};

    $self->{username} = $args{username} if exists $args{username};
    $self->{password} = $args{password} if exists $args{password};

    my $login_url = $self->{base_url}.LOGIN_URL;

    my $login_content = qq~
     { 
        "advertisingId" : "",
        "password": "$self->{password}",
        "username": "$self->{username}"
     }~;

    my $json_obj = $self->_post( $login_url, $login_content );

    $self->{user_agent}->cookie_jar->scan( \&_get_session_id );

    $self->{session_id} = $session_id;

    $self->{balance} = $json_obj->{accountInfo}->{available};

    return $self->logged_in();

}

sub new {

    my $class = shift;
    my %args  = @_;

    if (exists $args{platform} && $args{platform} eq 'demo') {
        $args{base_url} = 'https://demo-trade.nadex.com'; 
    } else {
        $args{base_url} = 'https://trade.nadex.com';
    }

    my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

    push @{ $ua->requests_redirectable }, 'POST', 'DELETE';
    $ua->agent(
"vendor=IG Group | applicationType=dxd | platform=Android | deviceType=generic | version=1.13.2"
    );
    $ua->cookie_jar( { autosave => 1, ignore_discard => 1 } );

    $args{user_agent} = $ua;

    bless \%args, __PACKAGE__;

}

sub retrieve_order {

    my $self = shift;
    my %args = @_;

    croak "ERROR: Finance::Nadex::retrieve_order(): must be logged in\n"
      unless $self->logged_in;

    croak "ERROR: retrieve_order(): must specify a named argument 'id'\n"
      unless exists $args{id};
    croak "ERROR: retrieve_order(): invalid id\n" unless $args{id};

    my $order_id = $args{id};

    my $retrieve_order_url = $self->{base_url}.RETRIEVE_ORDER_URL . '/' . $order_id;

    my $order_ref = $self->_get($retrieve_order_url);

    return undef unless $order_ref;

    return Finance::Nadex::Order::_new($order_ref);

}

sub retrieve_orders {

    my $self = shift;

    croak "ERROR: Finance::Nadex::retrieve_orders(): must be logged in\n"
      unless $self->logged_in();

    my $retrieve_orders_url = $self->{base_url}.RETRIEVE_ORDERS_URL;

    my $order_list_ref = $self->_get($retrieve_orders_url);

    die
"ERROR: Finance::Nadex::retrieve_orders(): failed to retrieve the order list from the exchange \n"
      if !$order_list_ref;

    my $order_obj_list_ref = [];
    foreach my $order (@$order_list_ref) {
        push( @$order_obj_list_ref, Finance::Nadex::Order::_new($order) );
    }

    return @$order_obj_list_ref;
}

sub retrieve_position {

    my $self = shift;
    my %args = @_;

    croak "ERROR: Finance::Nadex::retrieve_position(): must be logged in\n"
      unless $self->logged_in;

    croak
"ERROR: Finance::Nadex::retrieve_position(): must specify a named argument 'id'\n"
      unless exists $args{id};
    croak "ERROR: Finance::Nadex::retrieve_position(): invalid id\n"
      unless $args{id};

    my $position_id = $args{id};

    my $retrieve_positions_url = $self->{base_url}.RETRIEVE_POSITION_URL . '/' . $position_id;

    my $position_ref = $self->_get($retrieve_positions_url);

    return undef unless $position_ref;

    return Finance::Nadex::Position::_new($position_ref);

}

sub retrieve_positions {

    my $self = shift;

    croak "ERROR: Finance::Nadex::retrieve_positions(): must be logged in\n"
      unless $self->logged_in;

    my $retrieve_positions_url = $self->{base_url}.RETRIEVE_POSITIONS_URL;

    my $position_list_ref = $self->_get($retrieve_positions_url);

    die
"ERROR: Finance::Nadex::retrieve_positions(): failed to retrieve the position list from the exchange\n"
      if !$position_list_ref;

    my $position_obj_list_ref = [];
    foreach my $position (@$position_list_ref) {
        push( @$position_obj_list_ref,
            Finance::Nadex::Position::_new($position) );
    }

    return @$position_obj_list_ref;

}

sub _delete {

    my $self           = shift;
    my $url            = shift;
    my $delete_content = shift;

    my $response = $self->{user_agent}->delete(
        $url,
        clientApplication  => 'dxd',
        clientPlatform     => 'ANDROID_PHONE',
        clientVersion      => '1.13.2',
        Accept             => 'application/json; charset=UTF-8',
        'Content-Type'     => 'application/json; charset=UTF-8',
        'Accept-Encoding'  => 'text/html',
        Host               => 'www.nadex.com',
        Connection         => 'Keep-Alive',
        'X-SECURITY-TOKEN' => $self->{security_token},
        Content            => $delete_content
    );

    $self->{security_token} = $response->header('X-SECURITY-TOKEN')
      if $response->header('X-SECURITY-TOKEN');
    $self->{code}    = $response->code;
    $self->{content} = $response->content;

    my $delete_response =
      eval { JSON->new->utf8->decode( $response->content ); };

    return $delete_response;
}

sub _get {

    my $self = shift;
    my $url  = shift;

    my $response = $self->{user_agent}->get(
        $url,
        clientApplication  => 'dxd',
        clientPlatform     => 'ANDROID_PHONE',
        clientVersion      => '1.13.2',
        Accept             => 'application/json; charset=UTF-8',
        'Content-Type'     => 'application/json; charset=UTF-8',
        'Accept-Encoding'  => 'text/html',
        Host               => 'www.nadex.com',
        Connection         => 'Keep-Alive',
        'X-SECURITY-TOKEN' => $self->{security_token},
        Content            => ""
    );

    $self->{security_token} = $response->header('X-SECURITY-TOKEN')
      if $response->header('X-SECURITY-TOKEN');
    $self->{code}    = $response->code;
    $self->{content} = $response->content;

    my $json = eval { JSON->new->utf8->decode( $response->content ); };

    return $json;
}

sub _post {

    my $self         = shift;
    my $url          = shift;
    my $post_content = shift;

    my $response = $self->{user_agent}->post(
        $url,
        clientApplication          => 'dxd',
        clientPlatform             => 'APPLE_TABLET',
        version                    => '1',
        Accept                     => 'application/json; charset=UTF-8',
        'Content-Type'             => 'application/json; charset=UTF-8',
        'Accept-Encoding'          => 'text/html',
        'X-IG-DEVICE_MANUFACTURER' => 'LGE',
        'X-IG-DEVICE_MODEL'        => 'Nexus 4',
        'X-IG-DEVICE_OS_NAME'      => 'Android',
        'X-IG-DEVICE_OS_VERSION'   => '5.0.1',
        'X-IG-DEVICE_LOCALE'       => 'en_US',
        'X-IG-DEVICE_CARRIER'      => 'AT&T',
        'X-DEVICE-USER-AGENT' =>
'vendor=Minsk | applicationType=NADEX_PROMO | platform=Android | deviceType=phone | version=5.0.5',
        Host               => 'www.nadex.com',
        Connection         => 'Keep-Alive',
        'X-SECURITY-TOKEN' => $self->{security_token},
        Content            => $post_content
    );

    $self->{security_token} = $response->header('X-SECURITY-TOKEN')
      if $response->header('X-SECURITY-TOKEN');
    $self->{code} = $response->code;
    $self->{content} = $response->content || undef;

    my $json_obj = eval { JSON->new->utf8->decode( $response->content ); };

    return $json_obj;

}

sub _get_market_id {

    my $self = shift;
    my %args = @_;
    my $market_id;

    foreach my $market ( @{ $args{market_list_ref}->{'hierarchy'} } ) {
        if ( !exists $args{accept_match} || $args{accept_match} == 0 ) {
            if ( $market->{name} eq $args{name} ) {
                $market_id = $market->{id};
            }
        }
        else {
            if (   $market->{name} =~ /$args{name}/
                || $market->{name} eq $args{name} )
            {
                $market_id = $market->{id};
            }
        }
    }

    return $market_id || undef;
}

sub _get_session_id {

    my $key = $_[1];
    my $val = $_[2];

    $session_id = $val if $key =~ /JSESSIONID/;

}

sub _is_valid_price {

    my $self  = shift;
    my $price = shift;
    my $type  = shift;

    return 0 if $price =~ /-|\+/;

    if ( $type eq 'binary' ) {
        return 0 if $price !~ /^(\d+\.\d{1,2}|\.\d{1,2}|\d+)$/;

        if ( $price =~ /\.(\d+)/ ) {
            return 0 if $1 != 0 && $1 != 25 && $1 != 50 && $1 != 75;
        }
    }

    if ( $type eq 'spread' ) {
        return 0 if $price !~ /^(\d+|\d+\.\d{1,4})$/;
    }

    return 1;
}

sub _is_valid_direction {

    my $self      = shift;
    my $direction = shift;

    my %valid = qw( - 1 + 1 buy 1 sell 1);

    return exists $valid{$direction} ? 1 : 0;
}

sub _is_valid_size {

    my $self = shift;
    my $size = shift;

    return 0 if $size !~ /^\d+$/;

    return 0 if $size == 0;

    return 1;

}

=head1 NAME

Finance::Nadex - Interact with the North American Derivatives Exchange

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

Easily create orders, cancel orders, retrieve orders and retrieve positions on the North American Derivatives Exchange


    use Finance::Nadex;

    # connects to the live platform when called as Finance::Nadex->new(); as an alternative
    # it is possible to connect to the demo platform with Finance::Nadex->new(platform => 'demo')
    my $client = Finance::Nadex->new();

    # must login to perform any actions, including simply querying market info
    $client->login(username => 'yourusername', password => 'yourpassword');
    
    # get the available balance in the account
    my $balance = $client->balance();
    
    # get a quote for GBP/USD
    my $quote = $client->get_quote('instrument' => 'GBP/USD');

    # $quote may now be (for example), 1.5010
    
    # retrieve the epic (Nadex-assigned contract unique identifier) for the
    # Daily, 3pm, GBP/USD > 1.5120 contract
    my $epic = $client->get_epic( period => 'Daily', market => 'Forex (Binaries)', time => '3pm', instrument => 'GBP/USD', strike => '1.5120');
    
    # suppose $epic now contains 'NB.D.GBP-USD.OPT-23-17-23Jan15.IP';
    # create an order to buy 3 of those contracts for $34.50 each
    my $order_id = $client->create_order( price => '34.50', direction => 'buy', epic => $epic, size => 3 );
    
    # check the status of the order using the order id returned by the exchange;
    # this call will return undef if the order doesn't exist; the order may not exist
    # because the order was rejected by the exchange or because it was filled immediately
    # and therefore is no longer a working order
    my $order = $client->retrieve_order( id => $order_id );
    
    # let's assume the order was created and is still a working (or pending) order;
    # get the details of the order using the accessor methods provided by Finance::Nadex::Order
    print join(" ", $order->direction, $order->size, $order->contract, $order->price), "\n";

    # suppose the order has now been filled; this means we have one open position;
    # get the open positions
    my @positions = $client->retrieve_positions();
    
    # @positions now has 1 element which is a Finance::Nadex::Position; get its details
    print join(" ", $positions[0]->id, $positions[0]->direction(), $positions[0]->size(), $positions[0]->contract(), $positions[0]->price), "\n";
    
    # get the current best bid (the price at which we could sell the contract back immediately)
    my $bid = $positions[0]->bid();
    
    # suppose $bid is now $64.50 (we bought at $34.50, so we have a profit of $30);
    # sell to close the position at $64.50
    my $sell_to_close_order_id = $client->create_order( price => $bid, direction => 'sell', epic => $positions[0]->epic, size => $positions[0]->size() );

    # get all the time series (trading periods for contracts) currently
    # available for GBP/USD binaries; the list of currently available markets
    # can be obtained via a call to get_markets()
    my @series = $client->get_time_series( market => 'Forex (Binaries)', instrument => 'GBP/USD' );
    
    # elements of @series are simply strings, such as '2pm-4pm' or 'Daily (3pm)';
    # suppose one of the elements of series is '8pm-10pm'; get a list of
    # contracts available for trading within that market
    my @contracts = $client->get_contracts( market => 'Forex (Binaries)', instrument => 'GBP/USD', series => 'Daily (3pm)' );
    
    # @contracts now has a list in which each element is a Finance::Nadex::Contract; get
    # the details of the available contracts using the accessors of Finance::Nadex::Contract
    # including the current best bid and offer available on the exchange
    foreach my $contract (@contracts) {
    	  print join(" ", $contract->epic(), $contract->contract(), $contract->expirydate(), $contract->bid(), $contract->offer());
    }
    

    # cancel any remaining open orders
    $client->cancel_all_orders();

    
=head1 SUBROUTINES/METHODS

=head2 balance

Retrieves the available account balance

balance()

Returns a number representing the available account balance

=head2 cancel_all_orders

Cancels all pending orders

cancel_all_orders()

Returns nothing

=head2 cancel_order

Cancels the order with the specified order id

cancel_order( id => 'NZ1234FGQ4AFFOPA12Z' )

Returns the reference id created by the exchange for the cancelled order

=head2 create_order

Creates an order on the exchange with the specified parameters

  create_order( price => '34.50', direction => 'buy', epic => 'NB.D.GBP-USD.OPT-23-17-23Jan15.IP', size => 2 )

	price : the amount at which to buy or sell; the decimal portion of the number, if provided, must be .50 or .00 for binaries

	direction : one of 'buy', 'sell', '+', '-'
	
	size : the number of contracts to buy or sell

	epic : the unique identifier for the contract to be bought or sold

Returns: the order id created by the exchange to identify the order

Note: '+' is an alias for 'buy'; '-' is an alias for 'sell'; the get_epic() method can be used to get the identifier for the contract of interest

=head2 get_contract

Retrieves the contract specified by an epic

get_contract( epic => 'NB.D.GBP-USD.OPT-23-17-23Jan15.IP' )

   epic : the unique identifier created by the exchange for the contract

Returns a L<Finance::Nadex::Contract> instance for the specified epic

=head2 get_contracts

Retrieves all the contracts available for trading within the given time series for the specified market and instrument

get_contracts( market => 'Forex (Binaries)', instrument => 'GBP/USD', series => 'Daily (3pm)' )

	market : the name of the market for which the contracts are to be retrieved
   
	instrument : the name of the instrument within the market for which contracts are to be retrieved; the 
                instrument specified must be one of the instruments currently available for trading on the exchange
                for the provided market; the list of valid instruments can be obtained via get_market_instruments()
                
Returns a list in which each element is a L<Finance::Nadex::Contract> instance for each contract in the specified
time series                        

=head2 get_epic

Retrieves the epic(unique identifier) for a contract with the specified parameters
   
  get_epic(period => 'daily', strike => '1.5080', time => '3pm', instrument => 'GBP/USD', market => 'Forex (Binaries)')

	retrieves the epic with the specified parameters
	
	period : specifies the frequency or period of the contract being searched for; one of 'daily', 'intraday', 'weekly', or 'event'
   
	time : specifies the time at which the contract being searched for expires (not required when retrieving an event epic)
   
	instrument : the asset type from which the contract being searched for derives value; an index, currency, or commodity
	
	market : the market in which the specified contract exists (e.g. 'Forex (Binaries)', 'Indices (Binaries)'); must be one of markets returned by get_markets()
	
	strike : the level of the underlying asset for the desired contract (e.g. 1.5010)
   
Returns the unique identifier of the contract

=head2 get_market_instruments

Retrieves the list of instruments associated with the specified market

get_market_instruments( name => 'Forex (Binaries)' )

	name : the name of the market for which instruments are to be retrieved; this must match one of the names returned by get_markets()
   
Returns a list in which each element is a string containing the name of an instrument available for trading in the markets


=head2 get_markets

Retrieves the list of available markets on the exchange; the list of market names returned can be used in a call to get_market_instruments() to get further
information about the market
   
get_markets()

Returns a list in which each element is a string containing the name of a market in which instruments are traded   

=head2 get_quote

Retrieves the current price level of the instrument specified as reported by the exchange (the Indicative Price)

get_quote( instrument => 'GBP/USD' );

	instrument : the name of the instrument within the market for which a quote is to be retrieved; the 
                instrument specified must be one of the instruments currently available for trading 
                on the exchange for the provided market; the list of valid instruments can be obtained 
                via get_market_instruments()
                
Returns the current price level or undef if it cannot be obtained

=head2 get_time_series

Retrieves the contract periods available for trading in the specified market for the given instrument

get_time_series( market => 'Forex (Binaries)', instrument => 'AUD/USD' )

	market : the name of the market for which a time series is to be retrieved
   
	instrument : the name of the instrument within the market for which a time series is to be retrieved; the 
                instrument specified must be one of the instruments currently available for trading on the exchange
                for the provided market; the list of valid instruments can be obtained via get_market_instruments()

In the case of the '5 Minute Binaries' and '20 Minute Binaries' markets, returns a list in which each element is
a L<Finance::Nadex::Contract> representing each contract available in the series; for all other markets, returns
a string containing the name of a time series for the given market and instrument;
a time series designates the period during which the contract is available for trading including the expiration time

=head2 login

Submits the specified username and password to the exchange for authorization

login( username => 'someusername', password => 'somepassword' );

	username : the username of the account
   
	password : the password of the account

Returns a true value on successful login; otherwise returns a false value

=head2 logged_in

Reports whether login was previously attempted and succeeded

logged_in()

Returns true if login was previously attempted and succeded; otherwise returns false

=head2 new

Creates an instance of a Finance::Nadex object

   new()
   
Returns a reference to a Finance::Nadex instance

=head2 retrieve_order

Gets the details of the pending order with the specified order id

retrieve_order( id => 'NZ1234FGQ4AFFOPA12Z' )

Returns an instance of L<Finance::Nadex::Order>

=head2 retrieve_orders

Gets the details of all pending orders

retrieve_orders()

Returns a list in which each element is a L<Finance::Nadex::Order>

=head2 retrieve_position

Retrieves the details of an individual open position

retrieve_position ( id => 'NA12DZ45BNVA12A9BQZ' )

Returns a L<Finance::Nadex::Position> object corresponding to the specified position id

=head2 retrieve_positions

Retrieves the details of all the open positions

retrieve_positions()

Returns a list in which each element is a L<Finance::Nadex::Position>

=head1 AUTHOR

mhandisi, C<< <mhandisi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nadex-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nadex-API>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 TODO

Add support for watchlists.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Nadex


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nadex-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nadex-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nadex-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Nadex-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 mhandisi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

42;    # End of Finance::Nadex
