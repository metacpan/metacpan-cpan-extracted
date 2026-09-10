#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use Hyperman;

# The datagram plumbing under QUIC, proved on its own because everything
# above it assumes the answer: a UDP socket bound beside the TCP one on the
# same host and port, routed in hm_dispatch between the TCP-listener check
# and conns[] - a UDP listener fd is never in conns[], since QUIC multiplexes
# every connection over the one socket - and drained with hm_accept's
# fairness cap.

plan skip_all => 'HTTP/3 support not built' unless Hyperman->has_http3;

# A certificate, because QUIC's handshake is a TLS handshake and the listener
# refuses http3 without one. Reused from the TLS tests' generator if there is
# one; otherwise this file has nothing to bind and says so.
my ($cert, $key);
my $openssl = `which openssl 2>/dev/null`;
chomp $openssl;
plan skip_all => 'no openssl to make a test certificate' unless $openssl;

my $dir = "hm_h3_$$";
mkdir $dir or plan skip_all => "cannot make $dir";
($cert, $key) = ("$dir/c.pem", "$dir/k.pem");
my $rc = system(qq{$openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert }
              . qq{-days 1 -nodes -subj "/CN=localhost" >/dev/null 2>&1});
if ($rc != 0) {
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
                         [ "datagrams=$s->{datagrams}" ] ];
            }
            [ 200, [ 'Content-Type' => 'text/plain' ], ['ok'] ];
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

# TLS is on this listener, so speak plain HTTP to it only through the QUIC
# side; the stats endpoint is reached over TLS with openssl s_client, which
# every other TLS test in this dist already relies on.
sub https_get {
    my ($path) = @_;
    my $req = "GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n";
    open my $fh, '-|', qq{printf '%s' '$req' | $openssl s_client -quiet }
                     . qq{-connect 127.0.0.1:$port 2>/dev/null} or return '';
    local $/;
    my $r = <$fh>;
    close $fh;
    return defined $r ? $r : '';
}

# Wait for the listener.
my $up = '';
for (1 .. 100) {
    $up = https_get('/');
    last if $up =~ /ok/;
    Time::HiRes::sleep(0.05);
}
like($up, qr/\bok\b/, 'the TLS listener is serving on the TCP socket');

my $before = https_get('/stats') =~ /datagrams=(\d+)/ ? $1 : -1;
is($before, 0, 'no datagrams counted before any are sent');

# The UDP socket is bound on the SAME port as the TCP one. That it accepts a
# datagram at all is the claim: nothing else in this server binds UDP, so a
# successful send here can only have reached the QUIC listener.
my $udp = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                Proto => 'udp');
ok($udp, "a UDP socket opens on the same port as the TLS listener")
    or diag "udp: $!";

SKIP: {
    skip 'no UDP socket', 3 unless $udp;

    # Not QUIC, and deliberately so: at this stage the packet is counted and
    # dropped, and a real Initial would prove nothing more than this does.
    ok($udp->send("not a quic packet") , 'a datagram is accepted by the socket');

    # Converge rather than sleep: on a loaded smoker the wakeup can be later
    # than any interval worth guessing at, and a fixed sleep is what fails
    # there.
    my $got = -1;
    for (1 .. 100) {
        $got = https_get('/stats') =~ /datagrams=(\d+)/ ? $1 : -1;
        last if $got > 0;
        Time::HiRes::sleep(0.02);
    }
    is($got, 1, 'the loop woke on the UDP socket and drained the datagram');

    # More than the fairness cap in one go: the socket stays level-readable,
    # so the batch limit must resume rather than lose the remainder.
    $udp->send("packet $_") for 1 .. 100;
    my $all = -1;
    for (1 .. 200) {
        $all = https_get('/stats') =~ /datagrams=(\d+)/ ? $1 : -1;
        last if $all >= 101;
        Time::HiRes::sleep(0.02);
    }
    is($all, 101,
       'a burst past the 64-per-wakeup cap is drained across wakeups, '
     . 'not truncated');
}

kill 'TERM', $pid;
server_reap($pid);
unlink $cert, $key;
rmdir $dir;
done_testing();
