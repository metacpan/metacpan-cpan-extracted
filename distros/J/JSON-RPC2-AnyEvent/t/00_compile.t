use strict;
use Test::More;

use_ok $_ for qw(
    JSON::RPC2::AnyEvent
    JSON::RPC2::AnyEvent::Server
    JSON::RPC2::AnyEvent::Server::Handle
);

done_testing;

