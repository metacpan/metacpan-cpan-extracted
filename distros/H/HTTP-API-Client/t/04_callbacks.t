use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

$api->get("https://google.com", {
    api_key    => '[1234]',
    api_secret => sub {'[4567]'},
}, {
    APIKEY => sub {
        my (undef, %o) = @_;
        return $o{data}{api_key};
    },
    Signature => sub {
        my (undef, %o) = @_;
        return "$o{data}{api_key}$o{data}{api_secret}";
    },
});

my $request = $api->last_response->request->as_string;

like $request, qr/APIKEY: \[1234\]/, "Adding api key to the request header";
like $request, qr/Signature: \[1234\]\[4567\]/, "Adding signature to the request header";

done_testing;
