## Please see file perltidy.ERR
use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new(
    base_url         => URI->new('http://foobar.com'),
    content_type     => "application/x-www-form-urlencoded",
    pre_defined_data => {
        a => 1,
        b => sub { 2 },
        c => [ 3, 4, sub { 5 } ],
        e => bless( [ 6, 7, sub { 8 }, [ 13, 14 ], 15 ], 'CSV' ),
        f => sub { [ 9, bless( [ 10, 11 ], 'CSV' ) ] },
        h => [ 16, 17, bless( [ 18, 19 ], 'CSV' ), 20 ],
    },
);

my $req = $api->get( '/test', { g => [ sub { 12 } ] },
    {}, { test_request_object => 1 } );

my $expected =
'a=1&b=2&c=3&c=4&c=5&e=6,7,8,15&&e=13&e=14&f=9&f=10,11&g=12&h=16&h=17&h=18,19&h=20';

is $req->uri, $api->base_url . "/test?$expected";

$req = $api->post( '/test', { g => [ sub { 12 } ] },
    {}, { test_request_object => 1 } );

is $req->content, $expected;

done_testing;
