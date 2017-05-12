use strict;
use Test::More tests => 8;

use_ok 'HTTP::Response::Maker::PSGI';

is_deeply OK(),                       [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ '200 OK' ] ];
is_deeply OK('Hello'),                [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ 'Hello' ] ];
is_deeply FOUND([ Location => '/' ]), [ 302, [ 'Location' => '/' ], [ '302 Found' ] ];
is_deeply NO_CONTENT(),               [ 204, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ '' ] ];
is_deeply NOT_MODIFIED(),             [ 304, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ '' ] ];

use_ok 'HTTP::Response::Maker::PSGI', (
    default_headers => [ 'Content-Type' => 'application/json' ],
    prefix => 'JSON_',
);

is_deeply JSON_OK('{}'), [ 200, [ 'Content-Type' => 'application/json' ], [ '{}' ] ];
