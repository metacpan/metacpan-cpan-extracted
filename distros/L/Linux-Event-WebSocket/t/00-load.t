use v5.36;
use strict;
use warnings;

use Test::More;

use_ok('Linux::Event::WebSocket');
use_ok('Linux::Event::WebSocket::Connection');
use_ok('Linux::Event::WebSocket::Server');
use_ok('Linux::Event::WebSocket::Server::Connection');
use_ok('Linux::Event::WebSocket::Client');
use_ok('Linux::Event::WebSocket::Client::Connection');

ok(
    Linux::Event::WebSocket::Server::Connection->isa(
        'Linux::Event::WebSocket::Connection'
    ),
    'server connection has one WebSocket parent',
);
ok(
    Linux::Event::WebSocket::Client::Connection->isa(
        'Linux::Event::WebSocket::Connection'
    ),
    'client connection has one WebSocket parent',
);
ok(
    Linux::Event::WebSocket::Connection->isa(
        'Linux::Event::IO::Sock::Stream'
    ),
    'common WebSocket connection is a Linux::Event Stream',
);

done_testing;
