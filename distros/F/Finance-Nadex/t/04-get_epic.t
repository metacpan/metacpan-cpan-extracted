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
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "157259", "name": "Forex (Binaries)" }, { "id": "157247", "name": "Events Binaries" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157259$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "157280", "name": "GBP/USD" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157247$},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "157284", "name": "Nonfarm Payrolls" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157280$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "158963", "name": "Daily (3pm)" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157284$},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "hierarchy" : [ { "id": "157285", "name": "Open" } ] }'));

$gooduseragent->map_response(
    qr{iDeal/markets/navigation/158963$}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "markets" : [ { "epic": "NB.D.GBP-USD.OPT-17-21-14Jan15", "instrumentName": "GBP/USD >1.5040 (3PM)" } ] }'));
     
$gooduseragent->map_response(
    qr{iDeal/markets/navigation/157285$},
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8', 'X-SECURITY-TOKEN' => 123456, 'Set-Cookie' => 'JSESSIONID=12345'], '{ "markets" : [ { "epic": "NB.O.NP.OPT-17-21-14Jan15", "instrumentName": "Nonfarm Payrolls >=290000" } ] }'));


my $baduseragent = Test::LWP::UserAgent->new;

$baduseragent->cookie_jar( { autosave => 1, ignore_discard => 1 } );
$baduseragent->map_response(
    qr{iDeal/v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8'], ''));

BAD_LOGIN: {
   my $client = Finance::Nadex->new();
   $client->{user_agent} = $baduseragent;
   dies_ok { $client->create_order() } 'must be logged in to retrieve details about epics';
}

my $client = Finance::Nadex->new();
$client->{user_agent} = $gooduseragent;

$client->login( username => 'someusername', password => 'somepassword');

dies_ok {  $client->get_epic() } 'must supply all required arguments to retrieve an epic';
dies_ok {  $client->get_epic( strike => '1.5020', instrument => 'GBP/USD',  time => '3pm', market => 'Forex (Binaries)' ) } 'must specify a named argument "period"';
dies_ok {  $client->get_epic( strike => '1.5040', period => 'Daily', time => '3pm', market => 'Forex (Binaries)' ) } 'must specify a named argument "instrument"';
dies_ok {  $client->get_epic( strike => '1.5040', period => 'Daily', market => 'Forex (Binaries)', instrument => 'GBP/USD'  ) } 'must specify a named argument "time"';

my $epic;

ok (  $epic = $client->get_epic( strike => '290000', period => 'Event', market => 'Events Binaries', instrument => 'Nonfarm Payrolls'  ), 'a named argument "time" not needed when retrieving event epics');

ok (  $epic = $client->get_epic( strike => '1.5040', instrument => 'GBP/USD', period => 'Daily', time => '3pm', market => 'Forex (Binaries)' ), 'epic retrieved when all arguments provided');

done_testing();
