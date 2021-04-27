use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new( content_type => "application/json" );

my $test1 = $api->post('/test1', {a => 1}, {}, {test_request_object => 1});

like $test1->as_string, qr/application\/json/;
like $test1->as_string, qr/{"a":1}/;

$api = HTTP::API::Client->new;

my $test2 = $api->get('/test1', {a => 1}, {}, {test_request_object => 1});

like $test2->as_string, qr/application\/x-www-form-urlencoded/;
like $test2->as_string, qr/GET \/test1\?a=1/;

done_testing;
