use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

my $available = eval {
    require Unblock::WebSocket::Handshake;
    require Unblock::HTTP2;
    Unblock::HTTP2->VERSION('0.13');
    require Unblock::HTTP3;
    Unblock::HTTP3->VERSION('0.14');
    require Net::QUIC;
    Net::QUIC->VERSION('0.06');
    1;
};
die "WebSocket/H2/H3 required: $@" if !$available && $ENV{REBUILD_REQUIRE_WEBSOCKET};
plan skip_all => 'optional WebSocket, HTTP2, HTTP3 and QUIC required'
    unless $available;
plan skip_all => 'openssl required' unless -x '/usr/bin/openssl';

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
    '-days', '1') == 0 or die 'certificate generation failed';

for my $version ('2', '3') {
    subtest "HTTP$version WebSocket and ordinary request share connection" => sub {
        my $loop = Linux::Event::Loop->new;
        my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
        my ($ws_open, $ws_message, $ws_finish, $normal, $http_finish, $http_body);
        my (@errors, @ws_transactions, $server_ws, $client_ws);
        my $policy = $version eq '2' ? 'http2' : 'http3';
        my $server = Linux::Event::HTTP::Server->new(
            loop => $loop, native_input => $native,
            host => '127.0.0.1', port => 0,
            http1 => $version eq '3' ? 1 : 0,
            $policy => { websocket => 1 },
            tls => { cert_file => $cert, key_file => $key },
            on_request => sub ($tx, $req) {
                ++$normal;
                $tx->respond(status => 200, body => 'ordinary-ok');
            },
            on_websocket => sub ($tx, $req) {
                push @ws_transactions, $tx;
                return {
                    backend => 'perl',
                    on_message => sub ($ws, $bytes, $type) {
                        $ws->send_text("echo:$bytes");
                    },
                };
            },
        );
        my $client = Linux::Event::HTTP::Client->new(
            loop => $loop, native_input => $native,
            http1 => 0,
            $policy => { websocket => 1 },
            tls => { ca_file => $cert },
            ($version eq '3' ? (quic => { ca_file => $cert }) : ()),
            max_connections_per_origin => 1,
        );
        my $host = $version eq '2' ? 'localhost' : '127.0.0.1';
        my $origin = "$host:" . $server->port;
        my $finish_if_done = sub {
            $loop->stop if $ws_finish && $http_finish;
        };
        my $ws_op = $client->connect_websocket(
            url => "wss://$origin/ws", http_version => $version,
            backend => 'perl', timeout => 5,
            on_open => sub ($ws, $tx) {
                ++$ws_open;
                $client_ws = $ws;
                $ws->send_text('hello');
            },
            on_message => sub ($ws, $bytes, $type) {
                $ws_message = [$bytes, $type];
                # Keep H2/H3 stream-close writes outside the QUIC receive
                # callback, as with Unblock's deferred body transport.
                $loop->defer(sub { $ws->close });
            },
            on_error => sub ($obj, $error) {
                push @errors, "WebSocket: $error";
                $loop->stop;
            },
            on_finish => sub {
                ++$ws_finish;
                $finish_if_done->();
            },
        );
        my $http_op = $client->get("https://$origin/ordinary",
            http_version => $version, timeout => 5,
            on_response => sub ($tx, $res) { $http_body = $res->body },
            on_error => sub ($obj, $error) {
                push @errors, "HTTP: $error";
                $loop->stop;
            },
            on_finish => sub {
                ++$http_finish;
                $finish_if_done->();
            },
        );
        my $snapshot = $version eq '3'
            ? Linux::Event::Kernel::Timer->new(
                loop => $loop, after => 1,
                on_timer => sub {
                    my $tx = $ws_op->transaction;
                    return diag('H3 snapshot: no transaction') unless $tx;
                    my $rd = $tx->_incoming_body_reader('response');
                    my $wr = $tx->_request_body_object;
                    diag("H3 snapshot: op=" . $ws_op->state
                        . " tx=" . $tx->state
                        . " callback_depth=" . ($tx->{callback_depth} // 'undef')
                        . " response=" . ($tx->response ? $tx->response->is_complete : 'absent')
                        . " reader=" . ($rd ? $rd->is_complete : 'absent')
                        . " writer=" . ($wr ? $wr->is_complete : 'absent')
                        . " WSclose=" . ($client_ws ? $client_ws->close_complete : 'absent')
                        . " server_tx=" . (@ws_transactions
                            ? $ws_transactions[0]->state : 'absent'));
                    my $conn = $tx->{connection};
                    diag("H3 flags: output_finished=" . ($conn->{output_finished}{$tx->{stream_id}} // 'undef')
                        . " lifecycle=" . ($conn->{stream_lifecycle}{$tx->{stream_id}}
                            ? join(',', sort keys %{ $conn->{stream_lifecycle}{$tx->{stream_id}} })
                            : 'absent')) if $conn;
                },
            ) : undef;
        my $guard = Linux::Event::Kernel::Timer->new(
            loop => $loop, after => 8,
            on_timer => sub { push @errors, 'multiplexed timeout'; $loop->stop },
        );
        $loop->run;
        $guard->cancel;
        $snapshot->cancel if $snapshot && $snapshot->is_active;
        if (@errors) {
            for my $label (['client', $client_ws], ['server', $server_ws]) {
                my ($name, $ws) = @$label;
                diag("$name websocket absent"), next unless $ws;
                diag("$name ws: sent=" . $ws->close_sent
                    . " received=" . $ws->close_received
                    . " complete=" . $ws->close_complete
                    . " closed=" . $ws->is_closed
                    . " finished=" . ($ws->{transport_finished} // 'undef')
                    . " blocked=" . ($ws->{transport_blocked} // 'undef')
                    . " syncing=" . ($ws->{transport_syncing} // 'undef'));
                my $bridge = $ws->{transport};
                diag("$name bridge: " . join(' ', map {
                    "$_=" . ($bridge->{$_} // 'undef')
                } qw(ending ended waiting scheduled detached queued)))
                    if $bridge;
            }
            diag("client operation: " . $ws_op->state
                . " tx: " . ($ws_op->transaction ? $ws_op->transaction->state : 'none'));
            diag("server tx: " . (@ws_transactions
                ? $ws_transactions[0]->state : 'none'));
            my $client_tx = $ws_op->transaction;
            if ($client_tx) {
                my $body = $client_tx->_request_body_object;
                diag("client writer: " . ($body
                    ? ("state=" . ($body->can('state') ? $body->state : 'n/a')
                        . " complete=" . $body->is_complete)
                    : 'absent'));
                diag("client tx response complete: "
                    . ($client_tx->response ? $client_tx->response->is_complete : 'no response'));
            }
            diag("pool active: " . $client->pool_stats->{active});
        }
        is_deeply(\@errors, [], 'no protocol error');
        is($ws_open, 1, 'one WebSocket opened');
        is_deeply($ws_message, ['echo:hello', 'text'], 'actual WebSocket echo');
        is($ws_finish, 1, 'WebSocket stream finished exactly once');
        is($normal, 1, 'only ordinary HTTP enters on_request');
        is($http_finish, 1, 'ordinary HTTP finished once');
        is($http_op->state, 'complete', 'ordinary HTTP operation complete');
        is($http_body, 'ordinary-ok', 'HTTP body preserved');
        is(scalar @ws_transactions, 1, 'one server extended CONNECT');
        ok($ws_op->websocket, 'WebSocket session created');
        is($server->connection_count, 1, 'one shared transport connection');
        is($client->pool_stats->{connections}, 1, 'client reuses one connection');
        is($client->pool_stats->{active}, 0, 'all stream credits returned');

        $client->shutdown;
        my $done = 0;
        $server->shutdown(grace => 0, on_complete => sub {
            ++$done; $loop->stop;
        });
        if (!$done) {
            my $closing_guard = Linux::Event::Kernel::Timer->new(
                loop => $loop, after => 5,
                on_timer => sub { push @errors, 'shutdown timeout'; $loop->stop },
            );
            $loop->run;
            $closing_guard->cancel;
        }
        is($done, 1, 'server shutdown completes once');
        is($server->connection_count, 0, 'multiplexed session fully released');
        is($loop->count, 0, 'no socket or timer watchers');
    };
}
done_testing;
