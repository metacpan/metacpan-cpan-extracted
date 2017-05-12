use strict;
use Test::More 0.98;
use JSON::XS;
use HTTP::Request;
use Test::Differences;

use lib '../lib';

use_ok('EveOnline::SSO::Client');

my $client = EveOnline::SSO::Client->new(
        token => '************', 
        x_user_agent => 'Test Client'
    );

is( $client->make_url(['incursions']), 'https://esi.tech.ccp.is/latest/incursions/?datasource=tranquility', 'make_url' );
is( $client->make_url(['characters', 90922771, 'contacts'], { page => 1 } ), 'https://esi.tech.ccp.is/latest/characters/90922771/contacts/?page=1&datasource=tranquility', 'make_url query param' );
is( $client->make_url('https://esi.tech.ccp.is/latest/characters/90922771/contacts/?datasource=tranquility&page=1'), 'https://esi.tech.ccp.is/latest/characters/90922771/contacts/?datasource=tranquility&page=1', 'make_url clean url' );

my $req = HTTP::Request->new( uc 'get' => $client->make_url(['incursions']) );

$client->prepare_request($req);

is( $req->header('content-type'), 'application/json; charset=UTF-8', 'prepare_request type');
is( $req->header('content-length'), 0, 'prepare_request zero length');
is( $req->header('X-User-Agent'), 'Test Client', 'prepare_request X-User-Agent' );
is( $req->header('authorization'), 'Bearer ************', 'prepare_request auth');

$client->prepare_request($req, { param1 => 'value1', param2 => 2});

my $content = JSON::XS::decode_json( '{"param2":2,"param1":"value1"}' );
is( $req->header('content-length'), 30, 'prepare_request length');
is_deeply( JSON::XS::decode_json( $req->content ) , $content , 'prepare_request body');

my $answer = '{"param2":2,"param1":"value1"}';
eq_or_diff($client->parse_response($answer), JSON::XS::decode_json($answer), 'parse_response');

done_testing;

