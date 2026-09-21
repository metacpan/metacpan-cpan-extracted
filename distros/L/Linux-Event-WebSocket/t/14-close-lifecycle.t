use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;
use Linux::Event::WebSocket::Client;
use Linux::Event::WebSocket::Server;

sub guard_timer ($loop, $message) {
    return Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) {
            die "$message\n";
        },
    );
}

subtest 'abrupt peer loss does not start graceful close' => sub {
    my $loop = Linux::Event::Loop->new;
    my %state = (
        server_close => 0,
        client_close => 0,
        errors       => [],
    );
    my ($server_ws, $client_ws);

    my $guard = guard_timer($loop, 'abrupt peer loss test timed out');

    my $maybe_abort = sub {
        return if $state{triggered} || !$server_ws || !$client_ws;
        $state{triggered} = 1;
        $server_ws->abort;
    };

    my $server = Linux::Event::WebSocket::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,

        on_open => sub ($ws) {
            $server_ws = $ws;
            $maybe_abort->();
        },

        on_close => sub ($ws, $code, $reason) {
            ++$state{server_close};
            $state{server_code} = $code;
            $state{server_reason} = $reason;
        },

        on_error => sub ($ws, $error) {
            push @{$state{errors}}, "server: $error";
        },
    );

    my $client = Linux::Event::WebSocket::Client->new(
        loop => $loop,

        on_open => sub ($ws) {
            $client_ws = $ws;
            $maybe_abort->();
        },

        on_close => sub ($ws, $code, $reason) {
            ++$state{client_close};
            $state{client_code} = $code;
            $state{client_reason} = $reason;
            $guard->cancel;
            $server->close;
            $loop->stop;
        },

        on_error => sub ($ws, $error) {
            push @{$state{errors}}, "client: $error";
        },
    );

    $client->connect('ws://127.0.0.1:' . $server->port . '/abrupt');
    $loop->run;

    is($state{server_close}, 1,
        'hard-aborted peer observes one local close notification');
    is($state{client_close}, 1,
        'surviving peer observes exactly one close notification');
    ok(!defined($state{client_code}),
        'abrupt transport loss has no WebSocket close code');
    like($state{client_reason} // '', qr/\Atransport (?:EOF|closed)\z/,
        'abrupt transport loss reports transport closure');
    is($client_ws->_websocket_state->{engine}{sent_close}, 0,
        'abrupt transport loss sends no WebSocket close frame');
    is($client_ws->_websocket_state->{engine}{received_close}, 0,
        'abrupt transport loss receives no WebSocket close frame');
    ok(!defined($client_ws->_websocket_state->{close_timer}),
        'abrupt transport loss leaves no close timer');
};

subtest 'simultaneous close preserves peer close values exactly once' => sub {
    my $loop = Linux::Event::Loop->new;
    my %state = (
        server_close => 0,
        client_close => 0,
        errors       => [],
    );
    my ($server_ws, $client_ws);
    my $server;

    my $guard = guard_timer($loop, 'simultaneous close test timed out');

    my $finish = sub {
        return if $state{server_close} != 1 || $state{client_close} != 1;
        $guard->cancel;
        $server_ws->abort if !$server_ws->is_closed;
        $client_ws->abort if !$client_ws->is_closed;
        $server->close;
        $loop->stop;
    };

    my $start = sub {
        return if $state{started} || !$server_ws || !$client_ws;
        $state{started} = 1;
        $server_ws->close(code => 1000, reason => 'server done');
        $client_ws->close(code => 1000, reason => 'client done');
    };

    $server = Linux::Event::WebSocket::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,

        on_open => sub ($ws) {
            $server_ws = $ws;
            $start->();
        },

        on_close => sub ($ws, $code, $reason) {
            ++$state{server_close};
            $state{server_code} = $code;
            $state{server_reason} = $reason;
            $finish->();
        },

        on_error => sub ($ws, $error) {
            push @{$state{errors}}, "server: $error";
        },
    );

    my $client = Linux::Event::WebSocket::Client->new(
        loop => $loop,

        on_open => sub ($ws) {
            $client_ws = $ws;
            $start->();
        },

        on_close => sub ($ws, $code, $reason) {
            ++$state{client_close};
            $state{client_code} = $code;
            $state{client_reason} = $reason;
            $finish->();
        },

        on_error => sub ($ws, $error) {
            push @{$state{errors}}, "client: $error";
        },
    );

    $client->connect('ws://127.0.0.1:' . $server->port . '/simultaneous');
    $loop->run;

    is_deeply($state{errors}, [], 'simultaneous close reports no errors');
    is($state{server_close}, 1, 'server close callback fires exactly once');
    is($state{client_close}, 1, 'client close callback fires exactly once');
    is($state{server_code}, 1000, 'server sees client close code');
    is($state{server_reason}, 'client done', 'server sees client close reason');
    is($state{client_code}, 1000, 'client sees server close code');
    is($state{client_reason}, 'server done', 'client sees server close reason');
    is($server_ws->_websocket_state->{engine}{sent_close}, 1,
        'server sent one close handshake frame');
    is($server_ws->_websocket_state->{engine}{received_close}, 1,
        'server received peer close frame');
    is($client_ws->_websocket_state->{engine}{sent_close}, 1,
        'client sent one close handshake frame');
    is($client_ws->_websocket_state->{engine}{received_close}, 1,
        'client received peer close frame');
};

subtest 'peer loss during local close cancels timeout without duplicate close' => sub {
    my $loop = Linux::Event::Loop->new;
    my %state = (
        server_close => 0,
        client_close => 0,
        errors       => [],
    );
    my ($server_ws, $client_ws);

    my $guard = guard_timer($loop, 'peer loss during close test timed out');

    my $start = sub {
        return if $state{started} || !$server_ws || !$client_ws;
        $state{started} = 1;
        $client_ws->close(code => 1000, reason => 'local close');
        $server_ws->abort;
    };

    my $server = Linux::Event::WebSocket::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,

        on_open => sub ($ws) {
            $server_ws = $ws;
            $start->();
        },

        on_close => sub ($ws, $code, $reason) {
            ++$state{server_close};
        },

        on_error => sub ($ws, $error) {
            push @{$state{errors}}, "server: $error";
        },
    );

    my $client = Linux::Event::WebSocket::Client->new(
        loop => $loop,
        close_timeout => 2,

        on_open => sub ($ws) {
            $client_ws = $ws;
            $start->();
        },

        on_close => sub ($ws, $code, $reason) {
            ++$state{client_close};
            $state{client_code} = $code;
            $state{client_reason} = $reason;
            $guard->cancel;
            $server->close;
            $loop->stop;
        },

        on_error => sub ($ws, $error) {
            push @{$state{errors}}, "client: $error";
        },
    );

    $client->connect('ws://127.0.0.1:' . $server->port . '/vanish');
    $loop->run;

    is($state{client_close}, 1,
        'local closer receives exactly one close notification after peer loss');
    ok(!defined($state{client_code}),
        'peer loss before close response has no peer close code');
    like($state{client_reason} // '', qr/\Atransport (?:EOF|closed)\z/,
        'peer loss during close reports transport closure');
    is($client_ws->_websocket_state->{engine}{sent_close}, 1,
        'local close frame was sent before peer disappeared');
    is($client_ws->_websocket_state->{engine}{received_close}, 0,
        'no peer close frame was received');
    ok(!defined($client_ws->_websocket_state->{close_timer}),
        'transport loss cancels the graceful-close timeout');
};

done_testing;
