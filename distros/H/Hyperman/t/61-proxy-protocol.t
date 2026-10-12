#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# The PROXY protocol: a proxy listener reads a v1 or v2 header off the raw
# socket before TLS and before the request, rewrites the peer, re-checks the
# denylist for the real client, and refuses connections that do not begin
# with one; a plain listener treats the header as a bad request line.

my ($pp, $plain, $ptls) = free_ports(3);
plan skip_all => "no free loopback port" unless $pp && $plain && $ptls;
is(Hyperman->_proxy_selftest, 0, 'the parser passes its C selftest over hostile inputs');

my $dir = File::Temp::tempdir(CLEANUP => 1);
my ($cert, $key) = ("$dir/srv.pem", "$dir/srv.key");
my $have_tls = Hyperman->has_tls && `which openssl 2>/dev/null`
    && eval { require IO::Socket::SSL; 1 };
if ($have_tls) {
    system(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout "$key" -out "$cert" }
         . qq{-days 1 -subj "/CN=localhost" >/dev/null 2>&1});
    $have_tls = -s $cert && -s $key;
}

my $app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ join '|', map { $_ // '-' }
        @{$env}{qw(REMOTE_ADDR REMOTE_PORT psgix.proxy_addr)} ] ]
        unless $env->{PATH_INFO} eq '/stats';
    my $s = Hyperman->stats;
    [ 200, [], [ "denied=$s->{denied}" ] ];
};

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    my @listen = ({ host => '127.0.0.1', port => $pp, proxy_protocol => 1 },
                  { host => '127.0.0.1', port => $plain });
    push @listen, { host => '127.0.0.1', port => $ptls, proxy_protocol => 1,
                    tls_cert => $cert, tls_key => $key } if $have_tls;
    Hyperman->run(app => $app, workers => 1, listen => \@listen,
                  deny => ['203.0.113.66'], header_timeout => 1);
    exit 0;
}
for (1 .. 50) { IO::Socket::INET->new(PeerAddr => "127.0.0.1:$plain") and last; Time::HiRes::sleep(0.1) }

sub connect_to { IO::Socket::INET->new(PeerAddr => "127.0.0.1:$_[0]") or die "connect: $!" }
sub read_all {
    my ($s, $secs) = @_;
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($secs || 5);
        while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}
sub body { my $r = shift; $r =~ /\r\n\r\n(.*)\z/s ? $1 : "<no response: " . length($r) . " bytes>" }
my $GET = "GET / HTTP/1.0\r\n\r\n";

sub v2 {
    my (%o) = @_;
    my $sig = "\r\n\r\n\0\r\nQUIT\n";
    my $cmd = $o{local} ? 0x20 : 0x21;
    my $addr = $o{v6}
        ? pack('a16 a16 n n', pack('H*', '20010db8' . '0' x 23 . '1'), pack('H*', '20010db8' . '0' x 23 . '2'), 7777, 443)
        : pack('a4 a4 n n', pack('C4', 192, 0, 2, 44), pack('C4', 10, 0, 0, 1), 5555, 80);
    my $fam = $o{v6} ? 0x21 : 0x11;
    my $tlv = $o{tlv} ? pack('C n a*', 0xee, 3, 'abc') : '';
    return $sig . pack('C C n', $cmd, $fam, length($addr) + length($tlv)) . $addr . $tlv;
}

# ---- v1 ------------------------------------------------------------------
{
    my $s = connect_to($pp);
    $s->syswrite("PROXY TCP4 192.0.2.1 10.0.0.1 54321 80\r\n$GET");
    is body(read_all($s)), '192.0.2.1|54321|127.0.0.1', 'v1 TCP4: REMOTE_ADDR and port from the header, the proxy in psgix.proxy_addr';
}
{
    my $s = connect_to($pp);
    $s->syswrite("PROXY TCP6 2001:db8::1 2001:db8::2 4242 443\r\n$GET");
    is body(read_all($s)), '2001:db8::1|4242|127.0.0.1', 'v1 TCP6';
}
{
    my $s = connect_to($pp);
    $s->syswrite("PROXY UNKNOWN\r\n$GET");
    is body(read_all($s)), '127.0.0.1|' . $s->sockport . '|127.0.0.1', 'v1 UNKNOWN keeps the accepted peer';
}
{
    my $s = connect_to($pp);
    $s->syswrite("PROXY TCP4 192.0.2.1 10.0.0.1 ");          # split mid-header
    Time::HiRes::sleep(0.3);
    $s->syswrite("54321 80\r\n");
    Time::HiRes::sleep(0.1);
    $s->syswrite($GET);
    is body(read_all($s)), '192.0.2.1|54321|127.0.0.1', 'a header split across three writes is reassembled';
}

# ---- v2 ------------------------------------------------------------------
{
    my $s = connect_to($pp);
    $s->syswrite(v2(tlv => 1) . $GET);
    is body(read_all($s)), '192.0.2.44|5555|127.0.0.1', 'v2 PROXY TCP4 with a TLV';
}
{
    my $s = connect_to($pp);
    $s->syswrite(v2(v6 => 1) . $GET);
    is body(read_all($s)), '2001:db8::1|7777|127.0.0.1', 'v2 PROXY TCP6';
}
{
    my $s = connect_to($pp);
    $s->syswrite(v2(local => 1) . $GET);
    like body(read_all($s)), qr/\A127\.0\.0\.1\|\d+\|127\.0\.0\.1\z/, 'v2 LOCAL keeps the accepted peer';
}

# ---- refusals ------------------------------------------------------------
{
    my $s = connect_to($pp);
    $s->syswrite($GET);
    is read_all($s, 3), '', 'a plain request on the proxy listener gets nothing but EOF';
}
{
    my $s = connect_to($plain);
    $s->syswrite("PROXY TCP4 192.0.2.1 10.0.0.1 54321 80\r\n$GET");
    like read_all($s), qr{\AHTTP/1\.1 400}, 'a PROXY header on a plain listener is a 400';
    $s = connect_to($plain);
    $s->syswrite($GET);
    like body(read_all($s)), qr/\A127\.0\.0\.1\|\d+\|-\z/, '...and the plain listener still reports the real peer';
}
{
    my $s = connect_to($pp);
    $s->syswrite('x' x 200);
    is read_all($s, 3), '', '200 bytes with no CRLF: closed, not buffered';
}
{
    my $s = connect_to($pp);
    $s->syswrite("PROXY TCP4 203.0.113.66 10.0.0.1 1 80\r\n$GET");
    is read_all($s, 3), '', 'a denied client address behind the proxy is dropped';
    $s = connect_to($plain);
    $s->syswrite("GET /stats HTTP/1.0\r\n\r\n");
    like body(read_all($s)), qr/denied=[1-9]/, '...and counted as denied';
}
{
    my $s = connect_to($pp);
    my $t0 = Time::HiRes::time();
    my $r = read_all($s, 8);
    is $r, '', 'a connection that sends no header is closed';
    cmp_ok Time::HiRes::time() - $t0, '<', 7, '...within the header timeout, not the read timeout';
}

# ---- TLS behind the header -----------------------------------------------
SKIP: {
    skip 'no TLS build, openssl CLI or IO::Socket::SSL', 1 unless $have_tls;
    my $s = connect_to($ptls);
    $s->syswrite("PROXY TCP4 192.0.2.9 10.0.0.1 2020 443\r\n");
    IO::Socket::SSL->start_SSL($s, SSL_verify_mode => 0) or skip 'start_SSL: ' . IO::Socket::SSL::errstr(), 1;
    $s->syswrite($GET);
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5;
           while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c } alarm 0 };
    is body($buf), '192.0.2.9|2020|127.0.0.1', 'the header read on the raw socket, then TLS, then the request';
}

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
