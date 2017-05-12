use strict;
use warnings;
use HTTP::Request;
use HTTP::API::Client;
use Test::More tests => 2;

my $data = qq|{"options":{"prefetch":{"product_keywords":"keyword","product_places":"place","product_images":"image"}},"query":{"permalink":"Two-night Scenic Kent escape for two - St Crispin Inn \x{2013} Cardiff"},"sql_dump":1}|;

my $req = HTTP::Request->new( POST => "http://testing.com" );

eval {
    $req->content( $data );
};

like $@, qr/content must be bytes/, "Encoding Error";

is $data, HTTP::API::Client::_tune_utf8( $data ), "Encoding Fixed";
