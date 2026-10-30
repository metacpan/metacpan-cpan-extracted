use v5.36;
use Test::More;
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::Client;

{
    package Local::RawPeer;
    sub new ($class, %option) { bless { %option, bytes => '' }, $class }
    sub input ($self, $bytes) {
        $self->{bytes} .= $bytes;
        if ($self->{role} eq 'server' && index($self->{bytes}, 'PING') >= 0) {
            $self->{host}->unblock_send('PONG');
        }
        if ($self->{role} eq 'client' && index($self->{bytes}, 'PONG') >= 0) {
            $self->{loop}->stop;
        }
        return length $bytes;
    }
    sub input_eof ($self) { ++$self->{eof}; return }
    sub transport_error ($self, $error) { $self->{error} = "$error"; return }
    sub resume_output ($self) { ++$self->{drains}; return }
}

my $loop = Linux::Event::Loop->new;
my ($server_switch, $client_switch, $finished, $ordinary, $response_body);
my (@errors, $client_peer, $server_peer);
my $native = $ENV{REBUILD_NATIVE_INPUT} // 1;
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    native_input => $native,
    on_request => sub ($tx, $request) {
        if ($request->target eq '/switch') {
            $tx->respond(status => 101,
                headers => [[Connection => 'Upgrade'], [Upgrade => 'raw-peer']]);
        } else {
            ++$ordinary;
            $tx->respond(status => 200, body => 'normal');
        }
    },
    on_handoff => sub ($tx, $request, $response, $host) {
        ++$server_switch;
        $server_peer = Local::RawPeer->new(
            loop => $loop, host => $host, role => 'server',
        );
        $host->unblock_send('HELLO');
        return $server_peer;
    },
);
my $client = Linux::Event::HTTP::Client->new(
    loop => $loop, native_input => $native,
    max_connections_per_origin => 1,
);
my $origin = 'http://127.0.0.1:' . $server->port;
my $operation = $client->get("$origin/switch",
    http_version => '1.1',
    headers => [[Connection => 'Upgrade'], [Upgrade => 'raw-peer']],
    on_handoff => sub ($tx, $response, $host) {
        ++$client_switch;
        is($response->status, 101, 'client received accepted 101');
        $client_peer = Local::RawPeer->new(
            loop => $loop, host => $host, role => 'client',
        );
        $host->unblock_send('PING');
        return $client_peer;
    },
    on_error => sub ($tx, $err) { push @errors, "$err"; $loop->stop },
    on_finish => sub { ++$finished },
);
my $timeout = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 4,
    on_timer => sub { push @errors, 'generic Client timeout'; $loop->stop },
);
$loop->run;
$timeout->cancel;

is_deeply(\@errors, [], 'generic upgraded exchange has no failures');
is($server_switch, 1, 'Server handoff invoked once');
is($client_switch, 1, 'Client handoff invoked once');
is($finished, 1, 'HTTP transaction finishes at handoff boundary');
is($operation->state, 'complete', 'Client HTTP operation completed');
ok($client_peer && index($client_peer->{bytes}, 'HELLO') >= 0,
    'Client receives first raw server data');
ok($client_peer && index($client_peer->{bytes}, 'PONG') >= 0,
    'Client receives raw response over transferred socket');
is($server_peer->{bytes}, 'PING', 'Server successor receives Client raw data');
is($client->pool_stats->{connections}, 0,
    'transferred raw socket is not retained in HTTP connection pool');

my $normal = $client->get("$origin/normal", timeout => 3,
    on_response => sub ($tx, $response) { $response_body = $response->body },
    on_error => sub ($tx, $err) { push @errors, "$err"; $loop->stop },
    on_finish => sub { $loop->stop },
);
$timeout = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 4,
    on_timer => sub { push @errors, 'ordinary HTTP timeout'; $loop->stop },
);
$loop->run;
$timeout->cancel;
is($normal->state, 'complete', 'ordinary follow-up HTTP request completes');
is($response_body, 'normal', 'follow-up HTTP body intact');
is($ordinary, 1, 'ordinary handler bypasses generic handoff');
is_deeply(\@errors, [], 'no errors after socket transfer');

# The application, not the HTTP Client pool, now owns the upgraded socket.
$client_peer->{host}->close if $client_peer;
$client->shutdown;
my $done = 0;
$server->shutdown(grace => 0, on_complete => sub {
    ++$done; $loop->stop;
});
if (!$done) {
    $timeout = Linux::Event::Kernel::Timer->new(
        loop => $loop, after => 3,
        on_timer => sub { push @errors, 'shutdown timeout'; $loop->stop },
    );
    $loop->run;
    $timeout->cancel;
}
is($done, 1, 'server shutdown completed');
is($server->connection_count, 0, 'no remaining raw or HTTP transports');
is($loop->count, 0, 'no orphaned watchers');
done_testing;
