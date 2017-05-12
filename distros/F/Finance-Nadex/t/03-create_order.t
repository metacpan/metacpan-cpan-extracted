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
    qr{v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], ''));

$gooduseragent->map_response(
    qr{iDeal/dma/workingorders}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "dealReference" : "1" }'));

$gooduseragent->map_response(
    qr{iDeal/markets/details/NB},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "marketSnapshot" : { "displayBid": "34.00", "displayOffer": "44.00" }, "instrument" : { "underlyingIndicativePrice": "1.5160", "instrumentType": "binary", "marketName": "GBP/USD >1.5000 (3PM)", "displayPrompt": "20-JAN-15" } }'));

$gooduseragent->map_response(
    qr{iDeal/markets/details/NN},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "marketSnapshot" : { "displayBid": "1.5010", "displayOffer": "1.5015" }, "instrument" : { "underlyingIndicativePrice": "1.5160", "instrumentType": "spread", "marketName": "GBP/USD 1.5020-1.5120 (3PM)", "displayPrompt": "20-JAN-15" } }'));

my $baduseragent = Test::LWP::UserAgent->new;

$baduseragent->cookie_jar( { autosave => 1, ignore_discard => 1 } );
$baduseragent->map_response(
    qr{v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8'], ''));

BAD_LOGIN: {
   my $client = Finance::Nadex->new();
   $client->{user_agent} = $baduseragent;
   dies_ok { $client->create_order() } 'must be logged in to send an order to the exchange';
}

my $client = Finance::Nadex->new();
$client->{user_agent} = $gooduseragent;

$client->login( username => 'someusername', password => 'somepassword');

dies_ok {  $client->create_order() } 'fails if no order details are supplied';	 
dies_ok { $client->create_order( direction => '-', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2 ) } 'fails if price not supplied';
dies_ok { $client->create_order( direction => '-', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', price => '2.00' ) } 'fails if size not supplied';
dies_ok { $client->create_order( direction => '-', size => 2, price => '1.00' ) } 'fails if epic not supplied';
dies_ok { $client->create_order( epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '2.00' ) } 'fails if direction not supplied';
dies_ok { $client->create_order( direction => 'foo', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '2.00' ) } 'fails if direction is not valid';
dies_ok { $client->create_order( direction => '-', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => -1, price => '2.00' ) } 'fails if size is not valid';
dies_ok { $client->create_order( direction => '-', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '-2.00' ) } 'fails if price is not valid';

ok( $client->create_order( direction => 'sell', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '2.00' ), 'accepts the word "sell" as a direction as an alias for "-"');
ok( $client->create_order( direction => 'buy', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '2.00' ), 'accepts "buy" as a direction as an alias for "+"');
ok( $client->create_order( direction => 'buy', epic => 'NN.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '1.5010' ), 'valid price accepted for spreads');

my $orderid;
ok( $orderid = $client->create_order( direction => '-', epic => 'NB.OPT.GBP-USD-213-1-2Jan2', size => 2, price => '2.00' ), 'succeeds when all parameters are valid');

ok( $orderid, "creating an order returns an id for the order");
done_testing();
