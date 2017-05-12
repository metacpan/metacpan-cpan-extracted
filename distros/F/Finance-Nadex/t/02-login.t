#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LWP::UserAgent;
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

my $baduseragent = Test::LWP::UserAgent->new;

$baduseragent->cookie_jar( { autosave => 1, ignore_discard => 1 } );
$baduseragent->map_response(
    qr{iDeal/v2/security/authenticate}, 
    HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json;charset=UTF-8'], ''));


GOOD_LOGIN: {
   my $client = Finance::Nadex->new();
   $client->{user_agent} = $gooduseragent;
   ok($client->login( username => 'someuser', password => 'somepassword') == 1, 'login succeeds on good username/password');
}

BAD_LOGIN: {
   my $client = Finance::Nadex->new();
   $client->{user_agent} = $baduseragent;
   ok($client->login( username => 'someuser', password => 'badpassword') == 0, 'login fails on bad username/password');
}
done_testing();
