#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use Time::HiRes ();
use Hyperman;

# A real QUIC handshake from a real client, end to end.
#
# There is no HTTP/3 semantics behind it yet, so what is asserted is the
# transport: an Initial arrives on the UDP listener, routes through the
# Connection ID map, drives a TLS 1.3 handshake through ngtcp2_crypto_ossl,
# and the reply flight goes back out through the pull path. The client then
# finds nothing to talk HTTP/3 to and gives up, which is why the assertion is
# on the server's own count rather than on a response.
#
# Finding a client for this was most of the work: the h2load on the machine
# it was developed on advertises --h3 in its help and has no QUIC linked at
# all - the flag is shorthand for an ALPN string over TCP. So the client is
# checked for the HTTP3 feature rather than for a version or a flag.

plan skip_all => 'HTTP/3 support not built' unless Hyperman->has_http3;

my $curl;
for my $c ('/opt/homebrew/opt/curl/bin/curl', '/usr/local/opt/curl/bin/curl',
           split /\n/, `which -a curl 2>/dev/null` || '') {
    next unless $c && -x $c;
    # The feature list, not the flag and not the version: a curl can accept
    # --http3 and refuse to use it.
    my $v = `$c --version 2>/dev/null` || '';
    next unless $v =~ /^Features:.*\bHTTP3\b/m;
    $curl = $c;
    last;
}
plan skip_all => 'no HTTP/3-capable curl' unless $curl;
note("client: $curl");

my $openssl = `which openssl 2>/dev/null`;
chomp $openssl;
plan skip_all => 'no openssl to make a test certificate' unless $openssl;

my $dir = "hm_h3hs_$$";
mkdir $dir or plan skip_all => "cannot make $dir";
my ($cert, $key) = ("$dir/c.pem", "$dir/k.pem");
if (system(qq{$openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert }
         . qq{-days 1 -nodes -subj "/CN=localhost" >/dev/null 2>&1}) != 0) {
    unlink $cert, $key; rmdir $dir;
    plan skip_all => 'openssl could not make a test certificate';
}

my ($port) = free_ports(1);
unless ($port) {
    unlink $cert, $key; rmdir $dir;
    plan skip_all => 'no free loopback port';
}

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    quiet_child();
    require Hyperman;
    Hyperman->run(
        app => sub {
            my $env = shift;
            if ($env->{PATH_INFO} eq '/stats') {
                my $s = Hyperman->stats;
                return [ 200, [ 'Content-Type' => 'text/plain' ],
                         [ "h3_conns=$s->{h3_conns} datagrams=$s->{datagrams}" ] ];
            }
            [ 404, [ 'Content-Type' => 'text/plain' ], ['nope'] ];
        },
        host     => '127.0.0.1',
        port     => $port,
        workers  => 1,
        http3    => 1,
        tls_cert => $cert,
        tls_key  => $key,
    );
    exit 0;
}

# The stats endpoint is read over TLS on the TCP half of the same listener,
# which is the only way into this process that does not depend on the thing
# under test.
sub stats {
    my $req = "GET /stats HTTP/1.1\r\nHost: 127.0.0.1\r\n"
            . "Connection: close\r\n\r\n";
    open my $fh, '-|', qq{printf '%s' '$req' | $openssl s_client -quiet }
                     . qq{-connect 127.0.0.1:$port 2>/dev/null} or return {};
    local $/;
    my $r = <$fh>;
    close $fh;
    return { ($r || '') =~ /(\w+)=(\d+)/g };
}

my $up = {};
for (1 .. 100) {
    $up = stats();
    last if exists $up->{h3_conns};
    Time::HiRes::sleep(0.05);
}
ok(exists $up->{h3_conns}, 'the listener is serving on its TCP half')
    or diag 'server never came up';

SKIP: {
    skip 'server did not start', 3 unless exists $up->{h3_conns};
    is($up->{h3_conns}, 0, 'no QUIC handshakes before a client tries one');

    # --http3-only, so a failure cannot be masked by a fallback to TCP - the
    # mistake that made an h2load with no QUIC look like a working client.
    system(qq{$curl -s --http3-only -k --max-time 8 -o /dev/null }
         . qq{https://127.0.0.1:$port/ >/dev/null 2>&1});

    my $st = {};
    for (1 .. 100) {
        $st = stats();
        last if ($st->{h3_conns} || 0) > 0;
        Time::HiRes::sleep(0.05);
    }

    cmp_ok($st->{datagrams} || 0, '>', 0,
           'the client sent QUIC datagrams to the UDP listener');
    is($st->{h3_conns} || 0, 1,
       'and one QUIC handshake completed: Initial routed through the CID '
     . 'map, TLS 1.3 driven by ngtcp2, reply flight sent back');
}

kill 'TERM', $pid;
server_reap($pid);
unlink $cert, $key;
rmdir $dir;
done_testing();
