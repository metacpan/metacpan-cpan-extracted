use v5.36;
use strict;
use warnings;

use Test::More;

use_ok('Linux::Event::HTTP');
use_ok('Linux::Event::HTTP::Client');
use_ok('Linux::Event::HTTP::Client::Connection');
use_ok('Linux::Event::HTTP::Client::Operation');
use_ok('Linux::Event::HTTP::Server');
use_ok('Linux::Event::HTTP::Server::Connection');
use_ok('Linux::Event::HTTP::Request');
use_ok('Linux::Event::HTTP::Response');
use_ok('Linux::Event::HTTP::Transaction');
use_ok('Linux::Event::HTTP::Body::Stream');

ok(Linux::Event::HTTP::Request->can('new'),
    'Request exposes public message construction');
ok(Linux::Event::HTTP::Request->can('version'),
    'Request exposes protocol-neutral version accessor');
ok(Linux::Event::HTTP::Response->can('new'),
    'Response exposes public message construction');
ok(Linux::Event::HTTP::Response->can('body'),
    'Response exposes complete scalar body');
ok(!Linux::Event::HTTP::Response->can('stream_body'),
    'Response does not own streaming body production');
ok(!Linux::Event::HTTP::Response->can('write'),
    'Response does not expose streaming write');
ok(!Linux::Event::HTTP::Response->can('complete'),
    'Response does not expose body completion operation');
ok(!Linux::Event::HTTP::Response->can('connection'),
    'Response does not retain a Connection relationship');
ok(!Linux::Event::HTTP::Response->can('request'),
    'Response does not retain its peer Request');
ok(!Linux::Event::HTTP::Response->can('is_started'),
    'Response does not expose transport output state');
ok(!Linux::Event::HTTP::Response->can('is_upgrading'),
    'Response does not expose Upgrade lifecycle state');
ok(!Linux::Event::HTTP::Response->can('upgrade'),
    'Response does not perform protocol Upgrade');
ok(Linux::Event::HTTP::Response->can('is_complete'),
    'Response exposes message completion state');
ok(!Linux::Event::HTTP::Response->can('end'),
    'Response does not retain ambiguous end alias');
ok(!Linux::Event::HTTP::Response->can('is_ended'),
    'Response does not retain is_ended alias');
ok(Linux::Event::HTTP::Transaction->can('request'),
    'Transaction exposes its Request');
ok(Linux::Event::HTTP::Transaction->can('response'),
    'Transaction exposes its Response');
ok(Linux::Event::HTTP::Transaction->can('response_body'),
    'Transaction owns outgoing Response body production');
ok(Linux::Event::HTTP::Transaction->can('send_response'),
    'Transaction owns deferred scalar Response send');
ok(Linux::Event::HTTP::Transaction->can('upgrade'),
    'Transaction owns protocol Upgrade lifecycle');
ok(Linux::Event::HTTP::Transaction->can('is_response_started'),
    'Transaction exposes response output start state');
ok(Linux::Event::HTTP::Transaction->can('is_upgrading'),
    'Transaction exposes Upgrade lifecycle state');
ok(Linux::Event::HTTP::Transaction->can('cancel'),
    'Transaction exposes cancellation');
ok(Linux::Event::HTTP::Client::Operation->can('transaction'),
    'Client Operation exposes current/final Transaction');
ok(Linux::Event::HTTP::Client::Operation->can('transactions'),
    'Client Operation exposes Transaction history');
ok(Linux::Event::HTTP::Client::Operation->can('cancel'),
    'Client Operation owns high-level cancellation');
ok(Linux::Event::HTTP::Server::Connection->can('transaction'),
    'server Connection exposes its active Transaction');
ok(Linux::Event::HTTP::Client::Connection->can('request'),
    'client Connection starts HTTP Transactions');
ok(Linux::Event::HTTP::Client::Connection->can('transaction'),
    'client Connection exposes its active Transaction');
ok(Linux::Event::HTTP::Client->can('request'),
    'Client exposes generic request method');
for my $verb (qw(get head post put delete)) {
    ok(Linux::Event::HTTP::Client->can($verb),
        "Client exposes $verb convenience method");
}

done_testing;
