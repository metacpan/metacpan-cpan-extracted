#!/usr/bin/perl

use lib './lib';
use Furl::HTTP::OAuth;
use URI;
use Encode;
use JSON::XS;

my $client = Furl::HTTP::OAuth->new(
    consumer_key => "vgyYVbu7yljXXd2MZTfDmw",
    consumer_secret => "QnS5arFmnmeQQ-iB_Zbi9MuocY0",
    signature_method => "HMAC-SHA1",
    token => "9AkV-RywDkMD5JTZUUYeCltl2rbhCR2p",
    token_secret => "PRMLwzaY17Zb8fsPR9aMx7LQzbI"
);

my ($version, $code, $msg, $headers, $body) = $client->get('https://api.yelp.com/v2/search?term=Food&location=San+Francisco');

use Data::Dumper;
warn Dumper({
    version => $version,
    code => $code,
    message => $msg,
    headers => $headers,
    body => decode_json($body)
});
