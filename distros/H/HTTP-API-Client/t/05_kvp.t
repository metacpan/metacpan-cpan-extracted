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
        e => xCSV(6, 7, sub { 8 }, [ 13, 14 ], 15),
        f => sub { [ 9, xCSV(10, 11) ] },
        h => [ 16, 17, xCSV(18, 19), 20 ],
        b1 => xTRUE,
        b2 => xFALSE,
        b3 => xTrue,
        b4 => xFalse,
        b5 => xtrue,
        b6 => xfalse,
        b7 => xt__e,
        b8 => xf___e,
    },
);

{
    my $expected = 'a=1&b=2&b1=1&b2=0&b3=True&b4=False&b5=true&b6=false&b7=t&b8=f&c=3&c=4&c=5&e=6,7,8,15&&e=13&e=14&f=9&f=10,11&g=12&h=16&h=17&h=18,19&h=20';

    my $req = $api->get( '/test', { g => [ sub { 12 } ] },
        {}, { test_request_object => 1 } );

    is $req->uri, $api->base_url . "/test?$expected";

    $req = $api->post( '/test', { g => [ sub { 12 } ] },
        {}, { test_request_object => 1 } );

    is $req->content, $expected;
}

{
    my $expected = 'a=1&b3=True';

    my $req = $api->get( '/test', { g => [ sub { 12 } ] },
        {}, { test_request_object => 1, keys => sub { qw(a b3) } } );

    is $req->uri, $api->base_url . "/test?$expected";

    $req = $api->post( '/test', { g => [ sub { 12 } ] },
        {}, { test_request_object => 1, keys => sub { qw(a b3) } } );

    is $req->content, $expected;
}

done_testing;
