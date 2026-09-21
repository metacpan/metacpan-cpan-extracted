package Linux::Event::WebSocket::_BQ;
use v5.36;
use strict;
use warnings;

use Linux::Event::WebSocket ();
use XSLoader ();

XSLoader::load(
    'Linux::Event::WebSocket',
    $Linux::Event::WebSocket::VERSION,
);

sub raw_consumer_definition ($class) {
    return {
        provider           => \&_raw_consumer_operations_address,
        abi_version        => 1,
        operations_address => _raw_consumer_operations_address(),
    };
}

sub http_bridge_consumer_definition ($class) {
    return {
        provider           => \&_http_bridge_consumer_operations_address,
        abi_version        => 1,
        operations_address => _http_bridge_consumer_operations_address(),
    };
}

sub CLONE_SKIP { 1 }

1;
