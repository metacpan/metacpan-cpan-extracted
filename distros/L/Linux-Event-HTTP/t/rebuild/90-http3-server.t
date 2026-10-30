use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use Socket qw(inet_aton pack_sockaddr_in);
use Linux::Event::Loop;
use Linux::Event::Kernel::Timer;
use Linux::Event::HTTP::Server;
use Linux::Event::HTTP::_QUICSocket;

my $available = eval {
    require Net::QUIC;
    Net::QUIC->VERSION('0.06');
    require Unblock::HTTP3;
    Unblock::HTTP3->VERSION('0.14');
    require Unblock::HTTP::QUIC;
    1;
};
die "HTTP3 required by this test lane: $@" if !$available && $ENV{REBUILD_REQUIRE_HTTP3};
plan skip_all => 'optional Net::QUIC and Unblock::HTTP3 required' unless $available;
plan skip_all => 'openssl command required' unless -x '/usr/bin/openssl';

subtest 'runtime HTTP3 minimum rejects pre-integration releases' => sub {
    {
        local $Unblock::HTTP3::VERSION = '0.13';
        my %option = (http3 => 1);
        my $ok = eval { Linux::Event::HTTP::_Config::protocols(\%option); 1 };
        ok(!$ok, '0.13 cannot enable HTTP3');
        like("$@", qr/http3 requires Unblock::HTTP3 >= 0\.14/,
            'required published version is reported');
    }
    my %option = (http3 => 1);
    my %actual = Linux::Event::HTTP::_Config::protocols(\%option);
    ok(exists $actual{http3}, 'published compatible HTTP3 accepted');
};

my $dir = tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/cert.pem", "$dir/key.pem");
system('/usr/bin/openssl', 'req', '-x509', '-newkey', 'ec',
    '-pkeyopt', 'ec_paramgen_curve:prime256v1', '-nodes',
    '-keyout', $key, '-out', $cert, '-subj', '/CN=localhost',
    '-addext', 'subjectAltName=DNS:localhost', '-days', '1') == 0
    or die 'certificate generation failed';

my $loop = Linux::Event::Loop->new;
my (@events, @errors);
my $server = Linux::Event::HTTP::Server->new(
    loop => $loop, host => '127.0.0.1', port => 0, http3 => 1,
    tls => { cert_file => $cert, key_file => $key },
    on_headers => sub ($tx, $request) {
        isa_ok($tx, 'Unblock::HTTP3::Transaction');
        push @events, 'headers:' . $request->target;
    },
    on_request => sub ($tx, $request) {
        push @events, 'request:' . $request->target;
        $tx->respond(status => 200, body => 'server:' . $request->target);
    },
    on_error => sub ($tx, $error, @extra) {
        push @errors, "server: $error";
    },
);
ok($server->port > 0, 'public Server owns one bound TCP/UDP port');
my $socket = Linux::Event::HTTP::_QUICSocket->new(
    loop => $loop, host => '127.0.0.1', port => 0,
);
my (%responses, %bodies);
my $done = 0;
my $shutdowns = 0;
my $client = Unblock::HTTP::QUIC->client(
    local => $socket->local,
    peer => pack_sockaddr_in($server->port, inet_aton('127.0.0.1')),
    server_name => 'localhost', ca_file => $cert,
    send => $socket->send_callback,
    set_timeout => $socket->set_timeout_callback,
    on_ready => sub ($engine, $manager) {
        for my $path ('/one', '/two') {
            my $tx = $engine->request(
                method => 'GET', target => $path, scheme => 'https',
                authority => 'localhost',
                on_response => sub ($tx, $response) { $responses{$path} = $response },
                on_complete => sub ($tx) {
                    $bodies{$path} = $responses{$path}->body;
                    if (++$done == 2) {
                        is($server->connection_count, 1,
                            'one active HTTP3 connection serves both requests');
                        $server->shutdown(grace => 1, on_complete => sub {
                            ++$shutdowns;
                            $loop->stop;
                        });
                    }
                },
                on_error => sub ($tx, $error, @extra) {
                    push @errors, "client: $error";
                    $loop->stop;
                },
            );
            ok($tx, "request admitted: $path");
        }
    },
);
my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop, after => 7,
    on_timer => sub { die "public HTTP3 Server test timed out\n" },
);
$socket->start($client);
$loop->run;
$guard->cancel;

is_deeply(\@errors, [], 'public Server HTTP3 had no engine errors');
is($done, 2, 'both HTTP3 transactions completed');
is_deeply(\%bodies, {
    '/one' => 'server:/one', '/two' => 'server:/two',
}, 'public Server sent both response bodies');
is_deeply(\@events, [
    'headers:/one', 'request:/one', 'headers:/two', 'request:/two',
], 'headers precede completed request callbacks');
is($shutdowns, 1, 'public Server shutdown completed once');
$socket->close;
is($server->connection_count, 0, 'all owned QUIC connections retired');
is($loop->count, 0, 'no UDP, TCP or grace timer watcher remains');

done_testing;
