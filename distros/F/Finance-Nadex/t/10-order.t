#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LWP::UserAgent;
use Test::Exception;
use HTTP::Response;
use Finance::Nadex;
use Finance::Nadex::Contract;
use Finance::Nadex::Order;
use Finance::Nadex::Position;

my $gooduseragent = Test::LWP::UserAgent->new;

$gooduseragent->cookie_jar( { autosave => 1, ignore_discard => 1 } );
$gooduseragent->map_response(
    qr{iDeal/v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], ''));

     
$gooduseragent->map_response(
    qr{iDeal/markets/details/workingorders}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "market" : { "instrumentName": "GBP/USD >1.5160 (3PM)", "displayOffer": "85.00", "displayBid": "75.00" }, "workingOrder" : { "direction": "buy", "level": "45.00", "dealId": "NZ123DF56GFSZA2ZX", "epic": "NT.D.GBP-USD-12-100-1-12Jan15", "size": "2"  } }'));
 
my $baduseragent = Test::LWP::UserAgent->new;

$baduseragent->cookie_jar( { autosave => 1, ignore_discard => 1 } );
$baduseragent->map_response(
    qr{iDeal/v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8'], ''));

BAD_LOGIN: {
   my $client = Finance::Nadex->new();
   $client->{user_agent} = $baduseragent;
   dies_ok { $client->retrieve_order( order_id => "NZ123DEX9DZ0ZZA"  ) } 'must be logged in to retrieve an order';
}

my $client = Finance::Nadex->new();
$client->{user_agent} = $gooduseragent;

$client->login( username => 'someusername', password => 'somepassword');

dies_ok { $client->retrieve_order() } 'must supply all required arguments to retrieve an order';

my $order;

ok ( $order = $client->retrieve_order( id => 'NZA12ASZ0ZZ234SAZ' ), 'order retrieved when all arguments provided');
ok ( $order->id(), "retrieved order contains an id" );
ok ( $order->direction(), "retrieved order contains a direction" );
ok ( $order->bid(), "retrieved order contains a bid" );
ok ( $order->offer(), "retrieved order contains an offer");
ok ( $order->size(), "retrieved order contains a size");
ok ( $order->price(), "retrieved order contains a price");
ok ( $order->epic(), "retrieved order contains an epic");
ok ( $order->contract(), "retrieved order contains a contract");

done_testing();
