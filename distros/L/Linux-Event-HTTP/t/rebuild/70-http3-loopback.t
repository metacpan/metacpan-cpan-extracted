use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::_QUICSocket;

my $available = eval {
    require Net::QUIC;
    Net::QUIC->VERSION('0.06');
    require Unblock::HTTP3;
    Unblock::HTTP3->VERSION('0.14');
    require Unblock::HTTP::QUIC;
    require Unblock::HTTP::Server;
    1;
};
die "HTTP3 required by this test lane: $@" if !$available && $ENV{REBUILD_REQUIRE_HTTP3};
plan skip_all => 'optional Net::QUIC >= 0.06 and Unblock::HTTP3 >= 0.14 required'
    unless $available;
plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec', '-pkeyopt',
    'ec_paramgen_curve:prime256v1', '-nodes', '-keyout', $key,
    '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost', '-days', '1') == 0
    or die 'could not generate HTTP3 loopback certificate';

my $loop = Linux::Event::Loop->new;
my (@order, @errors, @ready, @client_tx);
my (%responses, %bodies);
my $server_definition = Unblock::HTTP::Server->new(
    http3 => {},
    on_headers => sub ($tx, $request) {
        push @order, 'headers:' . $request->target;
        isa_ok($tx, 'Unblock::HTTP3::Transaction');
        isa_ok($request, 'Uniform::HTTP::Request');
    },
    on_request => sub ($tx, $request) {
        push @order, 'complete:' . $request->target;
        $tx->respond(status => 200, body => 'h3:' . $request->target);
    },
    on_error => sub ($tx, $error, @extra) { push @errors, "server: $error" },
);
my $server_socket = Linux::Event::HTTP::_QUICSocket->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    on_error => sub ($socket, $error) { push @errors, "server UDP: $error" },
);
my $server = Unblock::HTTP::QUIC->server(
    server => $server_definition,
    certificate_file => $cert, private_key_file => $key,
    send => $server_socket->send_callback,
    set_timeout => $server_socket->set_timeout_callback,
    on_ready => sub ($engine, $manager) {
        push @ready, 'server';
        isa_ok($engine, 'Unblock::HTTP3::Server');
    },
);
$server_socket->start($server);

my $client_socket = Linux::Event::HTTP::_QUICSocket->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    on_error => sub ($socket, $error) { push @errors, "client UDP: $error" },
);
my $completed = 0;
my $client = Unblock::HTTP::QUIC->client(
    local => $client_socket->local,
    peer => $server_socket->local,
    server_name => 'localhost', ca_file => $cert,
    send => $client_socket->send_callback,
    set_timeout => $client_socket->set_timeout_callback,
    on_ready => sub ($engine, $manager) {
        push @ready, 'client';
        isa_ok($engine, 'Unblock::HTTP3::Client');
        for my $path ('/first', '/second') {
            my $tx = $engine->request(
                method => 'GET', target => $path,
                scheme => 'https', authority => 'localhost',
                on_response => sub ($transaction, $response) {
                    $responses{$path} = $response;
                },
                on_complete => sub ($transaction) {
                    $bodies{$path} = $responses{$path}->body;
                    $loop->stop if ++$completed == 2;
                },
                on_error => sub ($transaction, $error, @extra) {
                    push @errors, "client: $error";
                    $loop->stop;
                },
            );
            ok($tx, "HTTP3 request $path admitted");
            push @client_tx, $tx if $tx;
        }
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 8,
    on_timer => sub { die "HTTP3 QUIC loopback timed out\n" },
);
$client_socket->start($client);
$loop->run;
$guard->cancel;

is_deeply(\@errors, [], 'real QUIC/TLS/HTTP3 loopback had no errors');
is_deeply([sort @ready], [qw(client server)], 'both HTTP3 engines attached once');
is($completed, 2, 'two independent multiplexed requests completed');
is_deeply(\%bodies, { '/first' => 'h3:/first', '/second' => 'h3:/second' },
    'both response bodies arrived unmodified');
is($responses{$_}->status, 200, "HTTP3 response $_ status") for sort keys %responses;
for my $path ('/first', '/second') {
    my %position;
    for my $i (0 .. $#order) {
        $position{$order[$i]} = $i;
    }
    ok(defined($position{'headers:' . $path}) &&
       defined($position{'complete:' . $path}) &&
       $position{'headers:' . $path} < $position{'complete:' . $path},
       "header callback preceded completed request $path");
}
is(scalar($server->sessions), 1, 'one server QUIC connection served two streams');
is(scalar(@client_tx), 2, 'two real HTTP3 transactions returned');
$client_socket->close;
$server_socket->close;
is($loop->count, 0, 'all UDP and QUIC timer watchers released');

done_testing;
