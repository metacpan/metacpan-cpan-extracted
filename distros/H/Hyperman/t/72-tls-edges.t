#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# The TLS edges: a certificate that does not match its key, a CA that cannot
# be loaded, SNI entries without a certificate or with a NUL in the host, a
# client whose ALPN list names nothing we speak, a detach on a TLS
# connection, a TLS write that fills the socket and one whose peer has gone,
# a stream handle told it is full, and the pre-0.57 writer pair closed and
# dropped by hand.

plan skip_all => 'OpenSSL support not built' unless Hyperman->has_tls;
plan skip_all => 'fork is not Windows' if $^O eq 'MSWin32';
my $openssl = `which openssl`; chomp $openssl;
plan skip_all => 'openssl CLI not found' unless $openssl;
plan skip_all => 'IO::Socket::SSL is not installed' unless eval { require IO::Socket::SSL; 1 };

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $made = 1;
sub sh { $made &&= system("$_[0] >/dev/null 2>&1") == 0 }
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/a.key -out $dir/a.pem -days 1 -subj "/CN=localhost"});
sh(qq{openssl req -x509 -newkey rsa:2048 -nodes -keyout $dir/b.key -out $dir/b.pem -days 1 -subj "/CN=other"});
plan skip_all => 'could not create the test certificates'
    unless $made && !grep { !-s "$dir/$_" } qw(a.pem a.key b.pem b.key);

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;
sub slurp { my $f = shift; -f $f ? do { local (@ARGV, $/) = ($f); <> } // '' : '' }
sub wait_for { my ($file, $re) = @_; for (1 .. 50) { my $t = slurp($file); return $t if $t =~ $re; Time::HiRes::sleep(0.1) } return slurp($file) }

# A run() that must refuse, in a child with stderr captured, since the TLS
# layer explains itself there before the croak.
sub refused_in_child {
    my ($name, %opts) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        quiet_child(stderr => "$dir/$name.stderr");
        my $err = eval { Hyperman->run(app => sub { [ 200, [], [] ] }, host => '127.0.0.1', port => 0, workers => 1, %opts); 'none' } // $@;
        open my $fh, '>', "$dir/$name.err" or exit 1; print $fh $err; close $fh;
        exit 0;
    }
    server_reap($pid);
    return (slurp("$dir/$name.err"), slurp("$dir/$name.stderr"));
}

{
    my ($err, $log) = refused_in_child('mismatch', tls_cert => "$dir/a.pem", tls_key => "$dir/b.key");
    like($err, qr/TLS: could not initialise/, 'a certificate with the wrong key is refused');
    like($log, qr/cannot load private key/, 'and the reason is logged');
    ($err, $log) = refused_in_child('badca', tls_cert => "$dir/a.pem", tls_key => "$dir/a.key", tls_verify => 'require', tls_ca => "$dir/missing.pem");
    like($err, qr/TLS: could not initialise/, 'a CA that does not exist is refused');
    like($log, qr/cannot load CA/, 'and named');
}

my $result = "$dir/result";
my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    if ($p eq '/big') { return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'b' x (8 * 1024 * 1024) ] ] }
    if ($p eq '/detach') {
        my $err = eval { Hyperman::detach($env); 'none' } // $@;
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $err ] ];
    }
    if ($p eq '/stream_full') {
        return sub {
            my $w = Hyperman::stream($env, 200, [ 'Content-Type' => 'text/plain' ]);
            my @rc;
            for (1 .. 64) { my $rc = $w->write('s' x (1024 * 1024)); push @rc, $rc; last if $rc != 1 }
            open my $fh, '>', $result or die; print $fh join ',', @rc; close $fh;
            $w->close;
        };
    }
    if ($p eq '/hand_close') {
        return sub {
            my $w = shift->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
            my ($fd, $id) = @{ $env->{'psgix.hyperman.conn'} };
            my $h = bless [ $fd, $id ], 'Hyperman::Writer';
            $h->write('hand-closed');
            $h->close;
        };
    }
    if ($p eq '/hand_drop') {
        return sub {
            my $w = shift->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
            my ($fd, $id) = @{ $env->{'psgix.hyperman.conn'} };
            { my $h = bless [ $fd, $id ], 'Hyperman::Writer'; $h->write('hand-dropped') }
        };
    }
    [ 200, [ 'Content-Type' => 'text/plain' ], [ "$env->{'psgi.url_scheme'} $env->{SERVER_PROTOCOL}" ] ];
};

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child(stderr => "$dir/server.stderr");
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1,
        tls_cert => "$dir/a.pem", tls_key => "$dir/a.key", access_log => undef,
        (Hyperman->has_http2 ? (http2 => 1) : ()),
        tls_sni => { 'nocert.test' => {}, "nul\0host" => { cert => "$dir/b.pem", key => "$dir/b.key" }, 'other.test' => { cert => "$dir/b.pem", key => "$dir/b.key" } });
    exit 0;
}

sub tls_connect {
    my %o = @_;
    for (1 .. 60) {
        my $s = IO::Socket::SSL->new(PeerAddr => "127.0.0.1:$port", SSL_verify_mode => 0, %o);
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return;
}
sub read_all {
    my ($s, $budget) = @_;
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm($budget || 15); while (my $n = $s->sysread(my $c, 1 << 20)) { $buf .= $c } alarm 0 };
    return $buf;
}
sub get {
    my ($path, %o) = @_;
    my $s = tls_connect(%o) or return '';
    $s->syswrite("GET $path HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    return read_all($s);
}
sub body { my $r = shift; (split /\r\n\r\n/, $r, 2)[1] // '' }

like(get('/'), qr/https HTTP\/1\.1/, 'the TLS server answers');
my $log = wait_for("$dir/server.stderr", qr/NUL/);
like($log, qr/SNI host 'nocert\.test' needs cert and key/, 'an SNI entry without a certificate is skipped');
like($log, qr/SNI host key carries a NUL; skipped/, 'and one whose host carries a NUL');

SKIP: {
    skip 'ALPN needs the h2 build', 2 unless Hyperman->has_http2;
    my $s = tls_connect(SSL_alpn_protocols => ['foo']);
    ok($s, 'a client offering an unknown ALPN protocol still connects');
    $s->syswrite("GET / HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    like(read_all($s), qr/https HTTP\/1\.1/, 'and gets HTTP/1.1 without an ALPN answer');
}

like(body(get('/detach')), qr/TLS connections cannot be detached/, 'a detach on a TLS connection is refused');

# --- a big response: the socket fills while the client sleeps, and the peer goes ---
{
    my $s = tls_connect() or die;
    $s->syswrite("GET /big HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    Time::HiRes::sleep(1);
    is(length(body(read_all($s))), 8 * 1024 * 1024, 'a response that filled the socket arrives whole once the client reads');
    my $t = tls_connect() or die;
    $t->syswrite("GET /big HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    $t->sysread(my $first, 1);
    $t->close(SSL_no_shutdown => 1);
    Time::HiRes::sleep(0.5);
    like(get('/'), qr/https/, 'the server survives a peer that left mid-response');
}

# --- a stream handle told it is full ---
{
    unlink $result;
    my $s = tls_connect() or die;
    $s->syswrite("GET /stream_full HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
    Time::HiRes::sleep(1);
    my $got = body(read_all($s, 30));
    like(wait_for($result, qr/\d/), qr/(?:^|,)0$/, 'a stream handle answers 0 once the connection holds too much');
    ok(length($got) >= 1024 * 1024, 'and what it wrote arrives');
}

# --- the pre-0.57 writer pair, closed and dropped ---
like(get('/hand_close'), qr/hand-closed/, 'a writer built by hand from the fd and id writes and closes');
like(get('/hand_drop'), qr/hand-dropped/, 'and one dropped without close still ends the body');

kill 'TERM', $pid;
server_reap($pid);
done_testing;
