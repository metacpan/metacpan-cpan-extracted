use v5.36;
use Test::More;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

my $available = eval { require Unblock::WebSocket::Handshake; 1 };
die "WebSocket required by CI: $@" if !$available && $ENV{REBUILD_REQUIRE_WEBSOCKET};
plan skip_all => 'optional WebSocket not installed' unless $available;
my $loop = Linux::Event::Loop->new;
my ($opened, $received, $normal, $http_body, $http_finished, $ws_finished);
my (@errors, $ws, $op);
my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    native_input => $native, http1 => { websocket => 1 },
    on_request => sub ($tx, $request) {
        ++$normal;
        $tx->respond(status => 200, body => 'normal');
    },
    on_websocket => sub ($tx, $request) {
        return {
            backend => 'perl',
            on_message => sub ($server_ws, $body, $type) {
                $server_ws->send_text("reply:$body");
            },
        };
    },
);
my $client = Linux::Event::HTTP::Client->new(
    loop => $loop, native_input => $native,
    http1 => { websocket => 1 }, max_connections_per_origin => 1,
);
my $url = '127.0.0.1:' . $server->port;
$op = $client->connect_websocket(
    url => "ws://$url/ws", http_version => '1.1', backend => 'perl',
    timeout => 3,
    on_open => sub ($connection, $tx) {
        ++$opened;
        $ws = $connection;
        $connection->send_text('hello');
    },
    on_message => sub ($connection, $body, $type) {
        $received = [$body, $type];
        $connection->close;
        $loop->stop if $http_finished;
    },
    on_error => sub ($object, $error) { push @errors, "$error"; $loop->stop },
    on_finish => sub { ++$ws_finished },
);
my $http = $client->get("http://$url/plain", timeout => 3,
    on_response => sub ($tx, $response) { $http_body = $response->body },
    on_error => sub ($object, $error) { push @errors, "$error"; $loop->stop },
    on_finish => sub { ++$http_finished; $loop->stop if $received },
);
my $watchdog = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 7,
    on_timer => sub { push @errors, 'WebSocket client timed out'; $loop->stop },
);
$loop->run;
$watchdog->cancel;
is_deeply(\@errors, [], 'no WebSocket or HTTP client errors');
is($opened, 1, 'public client opens exactly one WebSocket');
is_deeply($received, ['reply:hello', 'text'],
    'public client receives actual WebSocket reply');
ok($op->websocket, 'operation exposes Unblock WebSocket session');
is($http->state, 'complete', 'ordinary HTTP operation completes');
is($http_body, 'normal', 'normal HTTP response survives socket takeover');
is($normal, 1, 'WebSocket request never reaches ordinary HTTP handler');
ok($ws_finished >= 1, 'handshake operation finished');

$client->shutdown;
my $complete = 0;
$server->shutdown(grace => 0, on_complete => sub { ++$complete; $loop->stop });
if (!$complete) {
    $watchdog = Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 3,
        on_timer => sub { push @errors, 'shutdown timeout'; $loop->stop },
    );
    $loop->run;
    $watchdog->cancel;
}
is($complete, 1, 'server cleanup completed');
is($server->connection_count, 0, 'server releases upgraded socket');
is($loop->count, 0, 'no remaining sockets or timers');
done_testing;
