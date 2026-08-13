#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports);
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

# A host that cannot mint a certificate is missing a prerequisite, the same
# one t/17 skips on - no usable openssl.cnf, an openssl too old for these
# arguments, no entropy. That has to skip here too. Dying instead exited
# before any plan was printed, which the harness can only read as a failed
# test file ("No plan found in TAP output"), so every such smoker reported
# FAIL for a certificate it was never able to create.
my $made = 1;
sub sh { $made &&= system("$_[0] >/dev/null 2>&1") == 0 }

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
# a third, for a host that is NOT in the map at boot - the certificate
# that arrives while the process is already serving
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/late.key -out $dir/late.pem -days 1 -subj "/CN=late.test"});

plan skip_all => 'could not create the test certificates'
    unless $made
        && !grep { !-s "$dir/$_" } qw(ca.pem ca.key srv.pem srv.key
                                      cli.pem cli.key ex.pem ex.key
                                      late.pem late.key);

my ($mtls_port, $sni_port, $rel_port) = free_ports(3);
plan skip_all => "no free loopback ports" unless $rel_port;

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

# ---- server 3: tls_reload, driven from inside the worker ----
#
# The context a listener serves is built in the parent before the fork,
# so a certificate issued afterwards is not served until the process is
# replaced. This is the way out of that, and the app is the trigger
# because the app is the only code that reliably runs IN a worker.
#
#   GET /reload      add late.test, keeping example.test
#   GET /reload-bad  a key that does not exist - must change nothing
my $rpid = fork // die;
if ($rpid == 0) {
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $n = 0;
            if ($env->{PATH_INFO} eq '/reload') {
                $n = Hyperman->tls_reload({
                    'example.test' => { cert => "$dir/ex.pem",   key => "$dir/ex.key" },
                    'late.test'    => { cert => "$dir/late.pem", key => "$dir/late.key" },
                });
            }
            elsif ($env->{PATH_INFO} eq '/reload-bad') {
                $n = Hyperman->tls_reload({
                    'late.test' => { cert => "$dir/late.pem",
                                     key  => "$dir/nonexistent.key" },
                });
            }
            return [ 200, [ 'Content-Type' => 'text/plain' ], [ "reloaded=$n" ] ];
        },
        host => '127.0.0.1', port => $rel_port, workers => 1,
        tls_cert => "$dir/srv.pem", tls_key => "$dir/srv.key",
        tls_sni => { 'example.test' => { cert => "$dir/ex.pem", key => "$dir/ex.key" } },
    );
    exit 0;
}

for my $p ($mtls_port, $sni_port, $rel_port) {
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

# ---- tls_reload ----
{
    my $cn = sub {
        my ($host) = @_;
        my $out = `curl -sk -v --resolve $host:$rel_port:127.0.0.1 https://$host:$rel_port/ 2>&1`;
        my ($cn) = $out =~ /subject:.*?CN=([^\s;,]+)/;
        return $cn // '';
    };

    # Before: late.test is in no map, so it falls back to the default.
    is $cn->('late.test'), 'localhost',
        'reload: a host with no certificate falls back to the default';
    is $cn->('example.test'), 'example.test',
        'reload: the boot-time SNI host serves its own';

    my $said = `curl -sk --resolve late.test:$rel_port:127.0.0.1 https://late.test:$rel_port/reload 2>/dev/null`;
    like $said, qr/reloaded=1/, 'reload: one listener was rebuilt';

    # After, on a NEW connection: the certificate that arrived while the
    # process was running is served, and the one that was already there
    # still is. Same process throughout - nothing was restarted.
    is $cn->('late.test'), 'late.test',
        'reload: a certificate added at runtime is served';
    is $cn->('example.test'), 'example.test',
        'reload: and the one already in the map is not lost';
    ok kill(0, $rpid), 'reload: the server was never replaced';

    # The failure case, which is the one that could take a fleet's TLS
    # down: an unbuildable map must leave the running certificates alone.
    $said = `curl -sk --resolve late.test:$rel_port:127.0.0.1 https://late.test:$rel_port/reload-bad 2>/dev/null`;
    like $said, qr/reloaded=0/, 'reload: an unbuildable map rebuilds nothing';
    is $cn->('late.test'), 'late.test',
        '...and what was being served still is';
    is $cn->('example.test'), 'example.test', '...for every host';
}

kill 'TERM', $mpid, $spid, $rpid;
waitpid $mpid, 0;
waitpid $spid, 0;
waitpid $rpid, 0;
done_testing;
