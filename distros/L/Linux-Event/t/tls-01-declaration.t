use v5.36;
use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use Socket qw(AF_UNIX SOCK_STREAM);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::TLS;

{
    package T::DeclaredTLSServer;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS
        cert_file => "$FindBin::Bin/tls-certs/server-cert.pem",
        key_file  => "$FindBin::Bin/tls-certs/server-key.pem",
        alpn      => ['declaration-test/1'];

    sub on_data ($stream, $bytes) { return }
}

{
    package T::InheritedTLSServer;
    use parent -norequire, 'T::DeclaredTLSServer';
}

{
    package T::RuntimeTLSServer;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub tls_defaults ($class) {
        return alpn => ['declaration-test/1'];
    }
    sub on_data ($stream, $bytes) { return }
}

{
    package T::DeclaredTLSClient;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS
        ca_file => "$FindBin::Bin/tls-certs/server-cert.pem",
        alpn    => ['declaration-test/1'];

    sub on_data ($stream, $bytes) { return }
}

{
    package T::TLSWithoutCertificate;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS;

    sub on_data ($stream, $bytes) { return }
}

{
    package T::TLSWithUnreadableCertificate;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS
        cert_file => "$FindBin::Bin/tls-certs/missing-cert.pem",
        key_file  => "$FindBin::Bin/tls-certs/missing-key.pem";

    sub on_data ($stream, $bytes) { return }
}

my $listener = Linux::Event::IO::Sock::Listener->new(
    host => '127.0.0.1',
    port => 0,
    stream => {
        class => 'T::RuntimeTLSServer',
        tls => {
            cert_file => "$FindBin::Bin/tls-certs/server-cert.pem",
            key_file  => "$FindBin::Bin/tls-certs/server-key.pem",
        },
    },
);
ok($listener->port > 0,
    'Listener prepares runtime TLS from the generated-Stream recipe');
$listener->close;

my $client = T::DeclaredTLSClient->connect(
    host => 'localhost',
    port => 443,
);
isa_ok($client->transport, 'Linux::Event::TLS');
is($client->state, 'unattached',
    'declarative client TLS is prepared before Loop attachment');
$client->close;

my $ok = eval {
    Linux::Event::IO::Sock::Listener->new(
        host => '127.0.0.1',
        port => 0,
        stream => {
            class => 'T::TLSWithoutCertificate',
            tls   => {},
        },
    );
    1;
};
ok(!$ok, 'accepted TLS stream-socket declaration requires a certificate');
like($@, qr/requires cert_file and key_file/,
    'missing server credential error identifies the declaration');

$ok = eval {
    Linux::Event::IO::Sock::Listener->new(
        host => '127.0.0.1',
        port => 0,
        stream => {
            class => 'T::TLSWithUnreadableCertificate',
            tls => {
                cert_file => "$FindBin::Bin/tls-certs/missing-cert.pem",
                key_file  => "$FindBin::Bin/tls-certs/missing-key.pem",
            },
        },
    );
    1;
};
ok(!$ok, 'Listener preflights declared server identity files');
like($@, qr/(?:No such file or directory|failed to load TLS server identity)/,
    'unreadable server identity fails during Listener construction');

$ok = eval q{
    package T::TLSBeforeParent;
    use Linux::Event::TLS;
    use parent 'Linux::Event::IO::Sock::Stream';
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'TLS declaration requires stream-socket inheritance first');
like($@, qr/must be a Linux::Event IO stream-socket subclass/,
    'declaration-order error is explicit');

$ok = eval q{
    package T::TLSUnknownOption;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS imaginary => 1;
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'TLS declaration rejects unknown options');
like($@, qr/unknown options: imaginary/,
    'unknown TLS declaration option is named');

$ok = eval q{
    package T::TLSNulServerName;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS server_name => "example.test\0.invalid";
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'TLS declaration rejects strings containing NUL bytes');
like($@, qr/server_name must be a non-empty string without NUL bytes/,
    'TLS NUL-byte error identifies the option');

$ok = eval q{
    package T::TLSWideALPN;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS alpn => ["\x{100}"];
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'TLS declaration rejects non-byte ALPN values');
like($@, qr/ALPN protocol must be a byte string/,
    'wide-character ALPN error identifies the byte-string contract');

$ok = eval q{
    package T::TLSHugeTimeout;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS
        handshake_timeout =>
            '99999999999999999999999999999999999999999999999999';
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'TLS declaration rejects a timeout outside native timer range');
like($@, qr/(?:finite number|supported timer range)/,
    'oversized TLS timeout fails during declaration');

like(exception(sub { Linux::Event::TLS->client(
    server_name => 'localhost',
    verify      => 2,
) }), qr/verify must be 0 or 1/,
    'direct TLS client helper validates verification policy');
like(exception(sub { Linux::Event::TLS->client(
    server_name => '[]',
) }), qr/server_name must not be empty after removing brackets/,
    'direct TLS client helper rejects an empty normalized identity');
like(exception(sub { Linux::Event::TLS->client(
    server_name => 'localhost',
    alpn => [map { 'x' x 255 } 1 .. 256],
) }), qr/ALPN protocol list must not exceed 65535 bytes/,
    'TLS rejects an ALPN list that cannot fit its wire extension');
like(exception(sub { Linux::Event::TLS->server(
    cert_file => "/tmp/cert\0.pem",
    key_file  => '/tmp/key.pem',
) }), qr/cert_file must be a non-empty string without NUL bytes/,
    'direct TLS server helper rejects NUL in credential path');

$ok = eval q{
    package T::TLSPairedCredential;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS cert_file => '/tmp/certificate.pem';
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'TLS declaration requires paired server credentials');
like($@, qr/requires cert_file and key_file together/,
    'paired credential error is explicit');

$ok = eval q{
    package T::TLSDuplicateDeclaration;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Linux::Event::TLS;
    use Linux::Event::TLS;
    sub on_data ($stream, $bytes) { return }
    1;
};
ok(!$ok, 'stream-socket subclass rejects a duplicate TLS declaration');
like($@, qr/already declares TLS/,
    'duplicate TLS declaration error is explicit');

socketpair(my $left, my $right, AF_UNIX, SOCK_STREAM, 0)
    or die "socketpair: $!";
$ok = eval { T::DeclaredTLSServer->new(fh => $left); 1 };
ok(!$ok, 'adopted TLS handle requires an explicit advanced role');
like($@, qr/requires tls_role/,
    'adopted TLS role error is explicit');
close $left;
close $right;

done_testing;

sub exception ($code) {
    local $@;
    return eval { $code->(); 1 } ? '' : "$@";
}
