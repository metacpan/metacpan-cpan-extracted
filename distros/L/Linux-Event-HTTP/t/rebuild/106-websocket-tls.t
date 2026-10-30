use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

my $available = eval { require Unblock::WebSocket::Client; 1 };
die "WebSocket required: $@" if !$available && $ENV{REBUILD_REQUIRE_WEBSOCKET};
plan skip_all => 'optional Unblock::WebSocket required' unless $available;
plan skip_all => 'openssl executable required' unless -x '/usr/bin/openssl';
my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/localhost-cert.pem", "$dir/localhost-key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1',
    '-days', '1') == 0 or die "openssl certificate generation failed";

my $loop = Linux::Event::Loop->new;
my (@errors, @trace, $server_tls, $client_tls, $echo, $opened, $ws);
my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    native_input => $native,
    http1 => { websocket => 1 },
    tls => { cert_file => $cert, key_file => $key },
    on_headers => sub { push @trace, 'server-headers' },
    on_request => sub ($tx, $request) {
        push @trace, 'server-request';
        $tx->respond(status => 200, body => 'ordinary');
    },
    on_error => sub ($tx, $error) {
        push @trace, 'server-http-error';
        push @errors, "server HTTP: $error";
    },
    on_websocket => sub ($tx, $req) {
        push @trace, 'server-websocket';
        return {
            backend => 'perl',
            on_open => sub ($websocket, $tx, $request) {
                push @trace, 'server-open';
                my $ok = eval {
                    my $host = $websocket->{transport};
                    $server_tls = $host && $host->transport_name eq 'tls'
                        && defined($host->tls_cipher) ? 1 : 0;
                    1;
                };
                push @errors, "server TLS inspection: $@" unless $ok;
            },
            on_message => sub ($websocket, $bytes, $type) {
                $websocket->send_text("tls:$bytes");
            },
            on_error => sub ($websocket, $error) {
                push @trace, 'server-ws-error';
                push @errors, "server: $error"; $loop->stop;
            },
        };
    },
);
my $client = Linux::Event::HTTP::Client->new(
    loop => $loop, native_input => $native,
    http1 => { websocket => 1 },
    tls => { ca_file => $cert },
);
my $op = $client->connect_websocket(
    url => 'wss://localhost:' . $server->port . '/ws',
    http_version => '1.1', backend => 'perl', timeout => 5,
    on_open => sub ($websocket, $tx) {
        $ws = $websocket;
        ++$opened;
        push @trace, 'client-open';
        my $ok = eval {
            my $host = $websocket->{transport};
            $client_tls = $host && $host->transport_name eq 'tls'
                && defined($host->tls_cipher) ? 1 : 0;
            1;
        };
        push @errors, "client TLS inspection: $@" unless $ok;
        $websocket->send_text('hello');
    },
    on_message => sub ($websocket, $payload, $type) {
        push @trace, 'client-message';
        $echo = [$payload, $type];
        $websocket->close;
        $loop->stop;
    },
    on_error => sub ($obj, $error) {
        push @trace, 'client-error';
        push @errors, "client: $error"; $loop->stop;
    },
);
my $timeout = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 8,
    on_timer => sub { push @errors, 'TLS WebSocket timeout'; $loop->stop },
);
$loop->run;
$timeout->cancel;

diag("TLS WebSocket callback trace: " . join(' -> ', @trace))
    if @errors || !$opened;
is_deeply(\@errors, [], 'real TLS WebSocket handshake and exchange have no errors');
is($opened, 1, 'client WebSocket opens once after verified TLS');
is($server_tls, 1, 'Server successor retains TLS transport and cipher');
is($client_tls, 1, 'Client successor retains TLS transport and cipher');
is_deeply($echo, ['tls:hello', 'text'], 'encrypted socket delivers real WebSocket frames');
ok($op->websocket, 'operation exposes established WebSocket');
is($client->pool_stats->{connections}, 0, 'upgraded TLS socket leaves HTTP pool');

$loop->run_for(0.1);
$ws->{transport}->close if $ws && $ws->{transport}
    && !$ws->{transport}->is_closed;
$client->shutdown;
my $shutdown = 0;
$server->shutdown(grace => 0, on_complete => sub {
    ++$shutdown; $loop->stop;
});
if (!$shutdown) {
    $timeout = Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 4,
        on_timer => sub { push @errors, 'shutdown timeout'; $loop->stop },
    );
    $loop->run;
    $timeout->cancel;
}
is($shutdown, 1, 'TLS Server shutdown notifies once');
is($server->connection_count, 0, 'upgraded TLS stream released');
is($loop->count, 0, 'TLS handshake and successor retain no watchers');
done_testing;
