#!/usr/bin/env perl
#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Data::Dump qw(dump);
use List::Util qw(min max);

use Finance::GDAX::API;
use Finance::GDAX::API::Account;
use Finance::GDAX::API::Quote;
use Finance::GDAX::API::Order;
use Finance::GDAX::API::Product;
use Finance::GDAX::API::Position;
use Finance::GDAX::API::Fill;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Finance::CoinbasePro::API::CLI::Util::DateUtil qw(getdatetime);
use Finance::CoinbasePro::API::CLI::Util::CurrencyUtil
  qw(get_product_currencies  format_usd  );
use Finance::CoinbasePro::API::CLI::Util::Config
  qw(get_config_filename get_config);

use Finance::CoinbasePro::API::CLI::Converter;
use Finance::CoinbasePro::API::CLI::Value;
use Finance::CoinbasePro::API::CLI::Fill;
use Finance::CoinbasePro::API::CLI::Account;
use Finance::CoinbasePro::API::CLI::Trade;

my $prog = basename($0);
my $verbose;
my $dryrun;
my @all_products = ( "BTC-USD", "BCH-USD" );    #"ETH-USD", "BTC-ETH");
my $product      = "BTC-USD";                   # default product
my $side         = "";                          # buy or sell
my $price        = 0;
my $order;
my $size = 0;
my $id   = 0;                                   # id to act upon for cancel
my @allowed_actions =
  qw( top buy sell products accounts orders quotes trades fills cancel cancelall );
my $sleep   = 1;
my $top_max = 1;

# Usage() : returns usage information
sub Usage {
    "$prog ("
      . join( "|", @allowed_actions ) . ") \n"
      . "   [--verbose] [--dryrun] [--product=BTC-USD] [--price=N] [--size=N] [--cancel]:\n"
      . "   shows data from GDAX/Coinbase Pro\n"
      . "    for example: $prog quotes --product=BTC-USD  or  $prog products\n";
}

sub ddump {
    my $data = shift;
    dump($data);
}

# call main()
main();

# main()
sub main {
    GetOptions(
        "verbose!"  => \$verbose,
        "dryrun!"   => \$dryrun,
        "product=s" => \$product,
        "order=s"   => \$order,     # order id
        "side=s"    => \$side,      # buy or sell
        "price=f"   => \$price,
        "size=s"    => \$size,
        "id=s"      => \$id,
    ) or die Usage();

    my $action = shift @ARGV;
    if ( !$action ) {
        die Usage()
          . "$prog: allowed actions: ("
          . join( "|", @allowed_actions ) . ")\n"
          . "$prog: first param is action to perform\n";
    }

    if ( $action =~ /^(buy|sell)$/ ) {
        die "$prog: price must be non-zero, not '$price'\n" unless $price;
        die "$prog: size must be non-zero, not '$size'\n"   unless $size;
    }

    $SIG{__DIE__}  = \&Carp::confess;
    $SIG{__WARN__} = \&Carp::confess;

    my $config_filename = get_config_filename();
    my $config          = $config_filename ? get_config($config_filename) : {};
    my @creds           = (
        key    => $config->{coinbasepro}{api_key}    || $ENV{GDAX_API_KEY},
        secret => $config->{coinbasepro}{api_secret} || $ENV{GDAX_API_SECRET},
        passphrase => $config->{coinbasepro}{api_passphrase}
          || $ENV{GDAX_API_PASSPHRASE},
        debug => 0
    );

    ## ACCOUNTS
    if ( $action eq "accounts" ) {
        my $gaccount     = Finance::GDAX::API::Account->new(@creds);
        my $account_list = $gaccount->get_all;

        #print "$prog: $action: " . ddump($account_list) . "\n";
        if ( $gaccount->error ) {
            die "$prog: There was an error " . $gaccount->error;
        }
        my @jaccounts = map { Finance::CoinbasePro::API::CLI::Account->new($_) }
          @$account_list;

        #print "$prog: $action: " . ddump(\@jaccounts) . "\n";
        for my $a (@jaccounts) {
            print "$prog: account: " . $a->to_str() . "\n";
        }
    }

    # PRODUCTS
    elsif ( $action eq "products" ) {
        my $gproduct = Finance::GDAX::API::Product->new;
        my $products = $gproduct->list;

        #print "$prog: $action: " . ddump($products) . "\n";
        my @product_ids = map { $_->{id} } @$products;
        print "$prog: products: @product_ids\n";
    }

# POSITIONS
#elsif ($action eq "positions") {
#    my $position = Finance::GDAX::API::Position->new( @creds );
#    print "$prog: $action: " . ddump($position) . "\n";
#    my $positions = $position->get;
#    print "$prog: $action: " . ddump($positions) . "\n";
#    #print "$prog: $action: " . join(" ", map { $_->{id} } @$positions ) . "\n";
#}
# ORDERS
    elsif ( $action eq "orders" ) {
        my @open_orders = get_open_orders(@creds);
        print "$prog: $action:\n";
        for my $o (@open_orders) {
            printf(
"%s: %s Action: %s %0.3f @ \$%4.2f (value \$%4.2f) [order id: %s]\n",
                $prog, $o->{product_id}, $o->{side}, $o->{size}, $o->{price},
                $o->{size} * $o->{price},
                $o->{id}
            );
        }

    #print "$prog: $action: " . join(" ", map { $_->{id} } @$positions ) . "\n";
    }

    # CANCEL and CANCEL-ALL
    elsif ( $action eq "cancel" ) {
        die
"$prog: cancel action needs id like: 74d59372-9719-4b36-a641-217d7c9e7fb0\n"
          unless length($id);
        if (
            ask(
                "Are you sure you want to cancel order id $id? (Yes/No)",
                '[Yy][Ee][Ss]'
            )
          )
        {
            my $order  = Finance::GDAX::API::Order->new(@creds);
            my $orders = $order->cancel($id);
            if ( $order->error ) { die "Error: " . $order->error }
        }
        else {
            die "$prog: Not cancelling\n";
        }
    }
    elsif ( $action eq "cancelall" ) {
        my $order = Finance::GDAX::API::Order->new(@creds);
        if (
            ask(
                "Are you sure you want to cancel all orders for all products?",
                '[Yy][Ee][Ss]'
            )
          )
        {
            my $orders = $order->cancel_all;
            if ( $order->error ) { die "Error: " . $order->error }
        }
        else {
            die "$prog: Not cancelling all orders\n";
        }
    }

    # QUOTES
    elsif ( $action eq "quotes" ) {
        my $quote = Finance::GDAX::API::Quote->new( product => $product )->get;
        print "$prog: $action: " . ddump($quote) . "\n";
    }

    # TRADES
    elsif ( $action eq "trades" ) {
        my $gproduct = Finance::GDAX::API::Product->new;
        my @products = $product ? ($product) : (@all_products);
        for my $a_product (@products) {
            my $trades = $gproduct->trades($a_product);
            my @jtrades =
              map { Finance::CoinbasePro::API::CLI::Trade->new($_) } @$trades;
            for my $j (@jtrades) {
                print "$prog: trade: " . $j->to_str() . "\n";
            }

            #print "$prog: $action: $a_product: " . ddump($trades) . "\n";
        }
    }

    # FILLS
    elsif ( $action eq "fills" ) {
        my $gdax_fills =
          Finance::GDAX::API::Fill->new( product_id => $product );
        my $fills = $gdax_fills->get;
        print "$prog: $action: " . ddump($fills) . "\n";
    }

    # TICKER (not same as 'quotes')
    elsif ( $action eq "ticker" ) {
        my $gproduct = Finance::GDAX::API::Product->new(@creds);
        for my $a_product (@all_products) {
            my $ticker = $gproduct->ticker($a_product);
            print "$prog: $action: " . ddump($ticker) . "\n";
        }
    }

    # BUY / SELL
    elsif ( $action eq "sell" || $action eq "buy" ) {
        print
"$prog: $action: initiating limit $action of $size $product at $price\n";
        my $order = Finance::GDAX::API::Order->new(@creds);
        $order->side($action);    # buy or sell
        $order->type('limit');
        $order->product_id($product);
        $order->price($price);
        $order->size($size);
        if (
            ask(
"Are you sure you want to $action $size of $product at $price? (Yes/No)",
                '[Yy][Ee][Ss]'
            )
          )
        {
            my $response = $order->initiate;
            if ( $order->error ) { die "Error: " . $order->error }
            else {
                print "$prog: $action: response is " . ddump($response) . "\n";
            }
        }
        else {
            die "$prog: Not selling\n";
        }
    }
    elsif ( $action eq "top" ) {
        top(@creds);
    }

    # UNKNOWN
    else {
        die "$prog: Unknown action '$action'\n" . Usage();
    }
}

sub top {
    my @creds       = @_;
    my $top_counter = 0;
    my @products    = $product ? ($product) : (@all_products);
    while ( !$top_max || $top_counter++ < $top_max ) {
        for my $a_product (@products) {
            my $gaccount     = Finance::GDAX::API::Account->new(@creds);
            my $account_list = $gaccount->get_all;

            my $gproduct = Finance::GDAX::API::Product->new(@creds);
            my $ticker   = $gproduct->ticker($a_product);

            my ( $from_currency, $to_currency ) =
              get_product_currencies($a_product);

            my $gdax_fills = Finance::GDAX::API::Fill->new(@creds);
            $gdax_fills->product_id($a_product);
            my $fills = $gdax_fills->get();

            #print "prog: debug: fills: " . dump($fills) . "\n";
            my $counter = 1;

            # LOOK AT FILLS AND COMPUTE OVERALL TRADING RESULTS
            my $from_trading_offset =
              Finance::CoinbasePro::API::CLI::Value->new(
                currency => $from_currency,
                num      => 0
              );
            my $to_trading_offset = Finance::CoinbasePro::API::CLI::Value->new(
                currency => $to_currency,
                num      => 0
            );
            my $num_fills = scalar(@$fills) - 1;
            my $show_max = min( 9, $num_fills );
          FILL_LOOP:
            for my $i ( 0 .. $show_max ) {
                my $fill =
                  Finance::CoinbasePro::API::CLI::Fill->new( $fills->[$i] );
                printf( "%s: fill: %2d: %s\n",
                    $prog, $counter++, $fill->to_str );
                $from_trading_offset->add( $fill->source_offset() );
                $to_trading_offset->add( $fill->destination_offset() );
            }
            printf(
                "%s: trading offset: %s, %s\n",
                $prog,
                $to_trading_offset->to_str(),
                $from_trading_offset->to_str()
            );

            # SHOW HOLDINGS
            my $holdings_value = Finance::CoinbasePro::API::CLI::Value->new(
                currency => $from_currency,
                num      => 0
            );
            for my $account (@$account_list) {
                my $a = Finance::CoinbasePro::API::CLI::Account->new($account);
                if ( $a->{balance} > 0 ) {
                    printf( "%s: Current Holding: %s\n", $prog, $a->to_str() );
                }
            }

            # SHOW PRICES
            printf(
"%s: Ticker  : $a_product: NOW: %s: (bid %s, ask %s), VOLUME % 7d\n",
                $prog,
                format_usd( $ticker->{price} ),
                format_usd( $ticker->{bid} ),
                format_usd( $ticker->{ask} ),
                $ticker->{volume}
            );
        }

        print "$prog: sleeping $sleep\n";
        sleep($sleep);
    }
}

sub get_open_orders {
    my @creds  = @_;
    my $order  = Finance::GDAX::API::Order->new(@creds);
    my $orders = $order->list;
    print "$prog: orders " . ddump($orders) . "\n";
    my @open_orders = grep { $_->{status} eq "open" } @$orders;
    return @open_orders;
}

############################################
# ask( $question, $regex )
# ask the user $question and get a line in response
# return if the users answer matches $regex
sub ask {
    my ( $question, $regex ) = @_;
    print "$question";
    my $answer = <STDIN>;
    return ( $answer =~ /$regex/ );
}

