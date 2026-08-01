#!perl
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# mutual TLS (client-certificate verification) and SNI multi-cert selection.
# Needs the OpenSSL build, the `openssl` CLI, and an HTTPS-capable curl.

plan skip_all => 'OpenSSL support not built' unless Hyperman->has_tls;
my $openssl = `which openssl`; chomp $openssl;
plan skip_all => 'openssl CLI not found' unless $openssl;
my $curl = `which curl`; chomp $curl;
plan skip_all => 'curl not found' unless $curl;

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub sh { system("$_[0] >/dev/null 2>&1") == 0 or die "cmd failed: $_[0]\n" }

# --- a tiny CA, a server cert signed by it, and a client cert signed by it ---
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/ca.key -out $dir/ca.pem -days 1 -subj "/CN=Test CA"});
# server cert (CN=localhost)
sh(qq{openssl req -newkey rsa:2048 -nodes -keyout $dir/srv.key -out $dir/srv.csr -subj "/CN=localhost"});
sh(qq{openssl x509 -req -in $dir/srv.csr -CA $dir/ca.pem -CAkey $dir/ca.key -CAcreateserial -out $dir/srv.pem -days 1});
# client cert (CN=alice)
sh(qq{openssl req -newkey rsa:2048 -nodes -keyout $dir/cli.key -out $dir/cli.csr -subj "/CN=alice"});
sh(qq{openssl x509 -req -in $dir/cli.csr -CA $dir/ca.pem -CAkey $dir/ca.key -CAcreateserial -out $dir/cli.pem -days 1});
# a second server cert for SNI host "example.test"
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/ex.key -out $dir/ex.pem -days 1 -subj "/CN=example.test"});

my $mtls_port = 24000 + ($$ % 500);
my $sni_port  = 24500 + ($$ % 500);

# ---- server 1: require client certs ----
my $mpid = fork // die;
if ($mpid == 0) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $who = $env->{SSL_CLIENT_S_DN} // '';
            my $vf  = $env->{SSL_CLIENT_VERIFY} // '';
            return [ 200, [ 'Content-Type' => 'text/plain' ],
                     [ "verify=$vf dn=$who https=" . ($env->{HTTPS} // '') ] ];
        },
        host => '127.0.0.1', port => $mtls_port, workers => 1,
        tls_cert => "$dir/srv.pem", tls_key => "$dir/srv.key",
        tls_ca => "$dir/ca.pem", tls_verify => 'require',
    );
    exit 0;
}

# ---- server 2: SNI, default cert + example.test cert ----
my $spid = fork // die;
if ($spid == 0) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'sni-ok' ] ] },
        host => '127.0.0.1', port => $sni_port, workers => 1,
        tls_cert => "$dir/srv.pem", tls_key => "$dir/srv.key",
        tls_sni => { 'example.test' => { cert => "$dir/ex.pem", key => "$dir/ex.key" } },
    );
    exit 0;
}

for my $p ($mtls_port, $sni_port) {
    for (1 .. 50) {
        my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$p");
        last if $s;
        Time::HiRes::sleep(0.1);
    }
}

# ---- mTLS ----
{
    # with a valid client cert: accepted, DN surfaced in $env
    my $cmd = "curl -s --cacert $dir/ca.pem --cert $dir/cli.pem --key $dir/cli.key "
            . "--resolve localhost:$mtls_port:127.0.0.1 https://localhost:$mtls_port/ 2>/dev/null";
    my $out = `$cmd`;
    like($out, qr/verify=SUCCESS/, 'mTLS: valid client cert verified');
    like($out, qr/dn=.*CN=alice/, 'mTLS: client DN in SSL_CLIENT_S_DN');
    like($out, qr/https=on/, 'mTLS: HTTPS env flag set');

    # without a client cert: handshake refused
    my $rc = system(qq{curl -s --cacert $dir/ca.pem --resolve localhost:$mtls_port:127.0.0.1 }
                  . qq{https://localhost:$mtls_port/ >/dev/null 2>&1});
    isnt($rc, 0, 'mTLS: connection without client cert is rejected');
}

# ---- SNI ----
{
    # default host -> server cert (CN=localhost)
    my $def = `curl -sk -v --resolve localhost:$sni_port:127.0.0.1 https://localhost:$sni_port/ 2>&1`;
    like($def, qr/CN=localhost/, 'SNI: default host serves the default cert');
    # SNI host example.test -> its own cert (CN=example.test)
    my $ex = `curl -sk -v --resolve example.test:$sni_port:127.0.0.1 https://example.test:$sni_port/ 2>&1`;
    like($ex, qr/CN=example\.test/, 'SNI: example.test serves its own cert');
    like($ex, qr/sni-ok/, 'SNI: request still served');
}

kill 'TERM', $mpid, $spid;
waitpid $mpid, 0;
waitpid $spid, 0;
done_testing;
