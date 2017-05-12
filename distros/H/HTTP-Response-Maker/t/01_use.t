use strict;
use Test::More tests => 5;

use_ok 'HTTP::Response::Maker', 'PSGI';
can_ok __PACKAGE__, 'OK';
can_ok __PACKAGE__, 'INTERNAL_SERVER_ERROR';

is_deeply OK('hello'), [ 200, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ 'hello' ] ];

local @HTTP::Response::Maker::DefaultHeaders = ( 'Content-Type' => 'text/plain' );

is_deeply OK('hello'), [ 200, [ 'Content-Type' => 'text/plain' ], [ 'hello' ] ];
