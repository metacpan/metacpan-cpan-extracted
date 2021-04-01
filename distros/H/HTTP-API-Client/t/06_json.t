## Please see file perltidy.ERR
use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new(
    base_url         => URI->new('http://foobar.com'),
    content_type     => 'application/json', ## by default
    pre_defined_data => {
        a => 1,
        b => sub { 2 },
        c => [ 3, 4, sub { 5 } ],
        e => bless( [ 6, 7, sub { 8 }, [ 13, 14 ], 15 ], 'CSV' ),
        f => sub { [ 9, bless( [ 10, 11 ], 'CSV' ) ] },
        h => [ 16, 17, bless( [ 18, 19 ], 'CSV' ), 20 ],
        i => { j => sub { 21 }, k => { l => sub { [23, 24] }, m => 25 }, n => xTRUE, o => xFALSE },
        n => xTRUE,
        o => xFALSE,
    },
);

{
    my $expected = '{"a":1,"b":2,"c":[3,4,5],"e":[6,7,8,[13,14],15],"f":[9,[10,11]],"g":[12],"h":[16,17,[18,19],20],"i":{"j":21,"k":{"l":[23,24],"m":25},"n":true,"o":false},"n":true,"o":false}';

    my $req = $api->post( '/test', { g => [ sub { 12 } ] },
        {}, { test_request_object => 1 } );

    is $req->content, $expected;
}

{
    my $expected = '{"a":1,"n":true,"o":false}';

    my $req = $api->post( '/test', { g => [ sub { 12 } ] },
        {}, { test_request_object => 1, keys => sub { qw(a n o) }} );

    is $req->content, $expected;
}

done_testing;
