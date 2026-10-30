use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Client;
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
plan skip_all => 'optional Net::QUIC and Unblock::HTTP3 required' unless $available;
plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost,DNS:127.0.0.1,IP:127.0.0.1',
    '-days', '1') == 0 or die 'certificate generation failed';

my $loop = Linux::Event::Loop->new;
my (@errors, @seen, @ops, @transactions);
my $definition = Unblock::HTTP::Server->new(
    http3 => {},
    on_request => sub ($tx, $request) {
        push @seen, $request->target;
        $tx->respond(status => 200, body => 'H3:' . $request->target);
    },
    on_error => sub ($tx, $error, @extra) { push @errors, "server: $error" },
);
my $udp = Linux::Event::HTTP::_QUICSocket->new(
    loop => $loop, host => '127.0.0.1', port => 0,
    on_error => sub ($sock, $error) { push @errors, "UDP: $error" },
);
my $manager = Unblock::HTTP::QUIC->server(
    server => $definition, certificate_file => $cert,
    private_key_file => $key,
    send => $udp->send_callback,
    set_timeout => $udp->set_timeout_callback,
);
$udp->start($manager);

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop, http3 => 1,
    quic => { ca_file => $cert },
);
my (%body, %version);
my $finished = 0;
for my $i (1 .. 4) {
    my $path = "/$i";
    my $op = $client->get('https://127.0.0.1:' . $udp->socket->local->port . $path,
        http_version => '3', timeout => 5,
        on_response => sub ($tx, $response) {
            isa_ok($tx, 'Unblock::HTTP3::Transaction');
            push @transactions, $tx;
            $body{$path} = $response->body;
            $version{$path} = $response->version;
        },
        on_error => sub ($object, $error, @extra) {
            push @errors, "client: $error";
        },
        on_finish => sub {
            $loop->stop if ++$finished == 4;
        },
    );
    push @ops, $op;
}
my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 9,
    on_timer => sub { die "public HTTP3 Client timed out\n" },
);
$loop->run;
$guard->cancel;
is_deeply(\@errors, [], 'strict HTTP3 operations completed without error');
is($finished, 4, 'all operations reached terminal callback');
is_deeply([sort @seen], [map { "/$_" } 1 .. 4], 'server received all requests');
is_deeply(\%body, { map { ("/$_", "H3:/$_") } 1 .. 4 },
    'all high-level responses delivered exactly');
is_deeply(\%version, { map { ("/$_", '3') } 1 .. 4 },
    'all operations selected HTTP3');
is(scalar($manager->sessions), 1, 'one shared QUIC connection serves all requests');
is(scalar @transactions, 4, 'real engine transactions exposed');
is($_->state, 'complete', 'operation completed') for @ops;

$client->shutdown;
$udp->close;
is($loop->count, 0, 'HTTP3 Client shutdown releases its UDP timers and watchers');
done_testing;
