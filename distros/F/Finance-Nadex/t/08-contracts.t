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
    qr{iDeal/dma/workingorders}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "dealReference" : "1" }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "157259", "name": "Forex (Binaries)" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157259$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "157280", "name": "GBP/USD" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157280$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "158963", "name": "Daily (3pm)" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/158963$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "markets" : [ { "displayOffer": "93.00", "displayBid": "83.00", "instrumentName": "GBP/USD >1.5080 (3PM)", "epic": "NT.D.OPT-GBP-USD.1-21-1Jan15", "instrumentType": "Binary", "displayPeriod": "1-JAN-15" }] }'));
     
$gooduseragent->map_response(
    qr{iDeal/markets/details$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "instrument" : { "underlyingIndicativePrice": "1.5160" }'));
 
my $baduseragent = Test::LWP::UserAgent->new;

$baduseragent->cookie_jar( { autosave => 1, ignore_discard => 1 } );
$baduseragent->map_response(
    qr{iDeal/v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8'], ''));

BAD_LOGIN: {
   my $client = Finance::Nadex->new();
   $client->{user_agent} = $baduseragent;
   dies_ok { $client->create_order() } 'must be logged in to retrieve contracts';
}

my $client = Finance::Nadex->new();
$client->{user_agent} = $gooduseragent;

$client->login( username => 'someusername', password => 'somepassword');

dies_ok {  $client->get_contracts() } 'must supply all required arguments to retrieve contracts';
dies_ok {  $client->get_contracts(  instrument => 'GBP/USD', series => 'Daily (3pm)'  ) } 'must specify a named argument "market"';
dies_ok {  $client->get_contracts(  market => 'Forex (Binaries)', series => 'Daily (3pm)' ) } 'must specify a named argument "instrument"';
dies_ok {  $client->get_contracts(  market => 'Forex (Binaries)', instrument => 'GBP/USD' ) } 'must specify a named argument "series"';

my @contracts;

ok (  @contracts = $client->get_contracts( instrument => 'GBP/USD', market => 'Forex (Binaries)', series => 'Daily (3pm)' ), 'contracts retrieved when all arguments provided');
ok ( $contracts[0]->epic, "retrieved contracts contain epics" );
ok ( $contracts[0]->bid, "retrieved contracts contain bids" );
ok ( $contracts[0]->offer, "retrieved contracts contain offers" );
ok ( $contracts[0]->expirydate, "retrieved contracts contain expiry dates" );
ok ( $contracts[0]->type, "retrieved contracts contain types" );

done_testing();
