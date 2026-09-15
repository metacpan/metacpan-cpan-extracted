use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $openssl = -x '/usr/bin/openssl' ? '/usr/bin/openssl' : undef;
if (!defined $openssl) {
    for my $dir (File::Spec->path) {
        my $candidate = File::Spec->catfile($dir, 'openssl');
        if (-x $candidate) {
            $openssl = $candidate;
            last;
        }
    }
}
plan skip_all => 'openssl command is required for HTTPS Client integration test'
    if !defined $openssl;

my $temp = tempdir(CLEANUP => 1);
my $cert = File::Spec->catfile($temp, 'server-cert.pem');
my $key = File::Spec->catfile($temp, 'server-key.pem');

my $generated;
{
    local $ENV{OPENSSL_CONF};
    delete $ENV{OPENSSL_CONF};
    $generated = system(
        $openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', $key,
        '-out', $cert,
        '-subj', '/CN=localhost',
        '-addext', 'subjectAltName=DNS:localhost',
        '-days', '1',
    );
}
plan skip_all => 'openssl could not generate temporary TLS certificate'
    if $generated != 0 || !-s $cert || !-s $key;

my $loop = Linux::Event::Loop->new;
my $state = {
    body => '',
};

my $server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    data => $state,
    tls => {
        cert_file => $cert,
        key_file  => $key,
        alpn      => ['http/1.1'],
    },
    on_request => sub ($conn, $req, $res) {
        $state->{server_alpn} = $conn->selected_alpn;
        $state->{server_tls_protocol} = $conn->tls_protocol;
        $state->{host} = $req->header('Host');
        $state->{target} = $req->target;
        $res->header('Content-Type', 'text/plain');
        $res->body("secure-client\n");
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 4,
    on_timer => sub ($timer) {
        die "high-level HTTPS Client integration test timed out\n";
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
    tls => {
        verify => 0,
        handshake_timeout => 2,
        shutdown_timeout => 1,
    },
);

my $url = 'https://localhost:' . $server->port . '/secure?x=1#ignored';
my $tx = $client->get(
    $url,
    on_response => sub ($transaction, $response) {
        $state->{status} = $response->status;
    },
    on_body => sub ($transaction, $response, $bytes) {
        $state->{body} .= $bytes;
    },
    on_complete => sub ($transaction) {
        $state->{complete} = $transaction->is_complete ? 1 : 0;
        $guard->cancel;
        $client->close;
        $server->close;
        $loop->stop;
    },
    on_error => sub ($transaction, $error) {
        die "HTTPS Client request failed: $error\n";
    },
);

is($tx->request->target, '/secure?x=1',
    'HTTPS URL produces ordinary origin-form Request target');
is($tx->request->header('Host'), 'localhost:' . $server->port,
    'HTTPS URL synthesizes Host including non-default port');

$loop->run;

is($state->{status}, 200, 'HTTPS Client receives HTTP response status');
is($state->{body}, "secure-client\n", 'HTTPS Client receives decrypted body bytes');
ok($state->{complete}, 'HTTPS Transaction completes successfully');
is($state->{target}, '/secure?x=1', 'server receives HTTPS request target');
is($state->{host}, 'localhost:' . $server->port, 'server receives synthesized HTTPS Host');
is($state->{server_alpn}, 'http/1.1',
    'Client HTTPS transport offers and negotiates only HTTP/1.1 ALPN');
ok(defined($state->{server_tls_protocol}) && length($state->{server_tls_protocol}),
    'server observes negotiated TLS protocol for high-level Client');

done_testing;
