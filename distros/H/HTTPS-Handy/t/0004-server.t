######################################################################
#
# t/0004-server.t - Live HTTPS server tests.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Config;
use File::Spec ();
use IO::Socket;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }
sub like { my ($g, $re, $n) = @_; $T++; defined($g) && ($g =~ $re) ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

# Skip if fork() is not available on this platform.
plan_skip('fork() not available')
    unless $Config{d_fork} || $Config{d_pseudofork};

# Pick a random unused port in the dynamic range 49152-65535.
sub _free_port {
    for (1..20) {
        my $p = 49152 + int(rand(16383));
        my $s = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1', LocalPort => $p,
            Proto => 'tcp', Listen => 1, ReuseAddr => 1);
        if ($s) { close $s; return $p }
    }
    return undef;
}

# Skip if loopback TCP is not usable.
{
    local $SIG{__WARN__} = sub {};
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => 1, Proto => 'tcp', Timeout => 2);
    plan_skip("loopback TCP unavailable: $!")
        unless $s || $!{ECONNREFUSED} || $! =~ /refused|connect/i;
}

my $port = _free_port();
plan_skip('no free port') unless $port;

use HTTPS::Handy;

# Isolated cert_dir so this test does not touch a real ~/.https_handy_certs
# or race a concurrently running example script.
my $cert_dir = File::Spec->catdir(File::Spec->tmpdir, "https_handy_certs_$$");

# --- Test application ---------------------------------------------------
my $test_app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};
    my $query  = $env->{QUERY_STRING} || '';

    if ($path eq '/hello') {
        return [200, ['Content-Type', 'text/plain'], ['Hello, Secure World!']];
    }
    if ($path eq '/scheme') {
        return [200, ['Content-Type', 'text/plain'], [$env->{'psgi.url_scheme'}]];
    }
    if ($path eq '/ssl-flag') {
        return [200, ['Content-Type', 'text/plain'], [$env->{'psgi.ssl'}]];
    }
    if ($path eq '/echo-method') {
        return [200, ['Content-Type', 'text/plain'], [$method]];
    }
    if ($path eq '/echo-query') {
        return [200, ['Content-Type', 'text/plain'], [$query]];
    }
    if ($path eq '/echo-post') {
        my $b = '';
        $env->{'psgi.input'}->read($b, $env->{CONTENT_LENGTH} || 0);
        return [200, ['Content-Type', 'text/plain'], [$b]];
    }
    if ($path eq '/status/404') {
        return [404, ['Content-Type', 'text/plain'], ['not found']];
    }
    if ($path eq '/status/500') {
        return [500, ['Content-Type', 'text/plain'], ['error']];
    }
    if ($path eq '/die') {
        die "intentional\n";
    }
    if ($path eq '/custom-header') {
        return [200, ['Content-Type', 'text/plain', 'X-HTTPS-Handy', 'test-value'], ['ok']];
    }
    return [404, ['Content-Type', 'text/plain'], ['not found']];
};

# --- Certificate ---------------------------------------------------------
# Generate the key and certificate here, before the server is forked,
# so that the cost is paid once and the wait for the listening socket
# below stays short.
my ($cert_file, $key_file) = HTTPS::Handy::_generate_self_signed(
    cert_dir => $cert_dir,
    log      => 0,
);

# --- Fork the server ----------------------------------------------------
my $server_pid = fork();
die "fork: $!" unless defined $server_pid;
if ($server_pid == 0) {
    HTTPS::Handy->run(app => $test_app, port => $port, log => 0,
                      ssl_cert_file => $cert_file, ssl_key_file => $key_file);
    exit 0;
}

# Wait up to 15 seconds for the server to start listening.
my $ready = 0;
for (1..150) {
    select undef, undef, undef, 0.1;
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 1);
    if ($s) { close $s; $ready = 1; last }
}

# Terminate the server and clean up the certificate directory on exit.
END {
    if ($server_pid) {
        kill 'TERM', $server_pid;
        waitpid $server_pid, 0;
        $? = 0;
    }
    if (defined $cert_dir && -d $cert_dir) {
        unlink File::Spec->catfile($cert_dir, $_)
            for qw(selfsigned-cert.pem selfsigned-key.pem);
        rmdir $cert_dir;
    }
}

plan_skip('server did not start') unless $ready;

ok(1, 'server started');

# Send an HTTPS/1.0 request over TLS and return ($status_line, \%headers, $body).
# The TLS client is the one inside HTTPS::Handy itself, so this test needs
# no other TLS implementation. It accepts the server's self-signed
# certificate, which is expected and documented behaviour.
sub https_req {
    my (%a)    = @_;
    my $method = $a{method} || 'GET';
    my $path   = $a{path}   || '/';
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    ) or return (undef, {}, undef);
    binmode $s;
    my $tls = HTTPS::Handy::TLS->client_handshake($s, host => 'localhost');
    unless ($tls) {
        close $s;
        return (undef, {}, undef);
    }
    my $req = "$method $path HTTP/1.0\r\nHost: localhost\r\n";
    if (defined $a{headers}) {
        for my $k (keys %{$a{headers}}) { $req .= "$k: $a{headers}{$k}\r\n" }
    }
    if (defined $a{body}) {
        $req .= "Content-Length: " . length($a{body}) . "\r\n"
              . "Content-Type: application/x-www-form-urlencoded\r\n";
    }
    $req .= "\r\n";
    $req .= $a{body} if defined $a{body};
    $tls->write_data($req);
    my $raw = '';
    while (defined(my $c = $tls->read_line)) { $raw .= $c }
    close $s;
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    my @lines  = split /\r\n/, $head;
    my $status = shift @lines;
    my %h;
    for (@lines) { $h{lc $1} = $2 if /^([^:]+):\s*(.*)$/ }
    return ($status, { %h }, defined $body ? $body : '');
}

# --- GET /hello -----------------------------------------------------------
my ($st, $hh, $bo);
($st, $hh, $bo) = https_req(path => '/hello');

like($st, qr{^HTTP/1\.0 200}, 'GET /hello: 200');
is($bo, 'Hello, Secure World!', 'GET /hello: body');
like(lc(defined $hh->{connection} ? $hh->{connection} : ''), qr{close}, 'Connection: close');
like($hh->{'content-type'}, qr{text/plain}, 'Content-Type');

# --- HTTPS-specific $env keys ----------------------------------------------
($st, $hh, $bo) = https_req(path => '/scheme');
is($bo, 'https', 'psgi.url_scheme is https');

($st, $hh, $bo) = https_req(path => '/ssl-flag');
is($bo, '1', 'psgi.ssl is 1');

# --- Request data mapped to $env -------------------------------------------
($st, $hh, $bo) = https_req(path => '/echo-method');
is($bo, 'GET', 'REQUEST_METHOD GET');

($st, $hh, $bo) = https_req(path => '/echo-query?foo=bar&baz=1');
is($bo, 'foo=bar&baz=1', 'QUERY_STRING');

# --- Status codes ------------------------------------------------------------
($st) = https_req(path => '/status/404');
like($st, qr{^HTTP/1\.0 404}, '404');

($st) = https_req(path => '/status/500');
like($st, qr{^HTTP/1\.0 500}, '500');

($st) = https_req(path => '/die');
like($st, qr{^HTTP/1\.0 500}, 'app die -> 500');

($st) = https_req(path => '/hello');
like($st, qr{^HTTP/1\.0 200}, 'alive after die');

($st) = https_req(method => 'DELETE', path => '/hello');
like($st, qr{^HTTP/1\.0 405}, 'DELETE -> 405');

# --- POST ---------------------------------------------------------------
($st, $hh, $bo) = https_req(method => 'POST', path => '/echo-method');
is($bo, 'POST', 'POST method');

($st, $hh, $bo) = https_req(method => 'POST', path => '/echo-post', body => 'name=ina&lang=perl');
is($bo, 'name=ina&lang=perl', 'POST body');

# --- Miscellaneous -------------------------------------------------------
($st, $hh) = https_req(path => '/custom-header');
is($hh->{'x-https-handy'}, 'test-value', 'custom header');

($st) = https_req(path => '/no/such/path');
like($st, qr{^HTTP/1\.0 404}, 'unknown path 404');

# --- Plain HTTP request to the HTTPS port is rejected, not crashed --------
{
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 5);
    if ($s) {
        print $s "GET /hello HTTP/1.0\r\n\r\n";
        my $raw = '';
        local $SIG{ALRM} = sub { die "timeout\n" };
        eval {
            alarm(3);
            while (my $c = <$s>) { $raw .= $c }
            alarm(0);
        };
        alarm(0);
        close $s;
        # The server should either close the connection or refuse the
        # handshake -- it must not send back a plaintext HTTP response.
        ok($raw !~ /^HTTP\/1\.0 200/, 'plain HTTP to TLS port: no plaintext 200 leaked');
    }
    else {
        ok(1, 'plain HTTP to TLS port: connect failed (acceptable)');
    }
}

# The server must still be alive after the non-TLS probe above.
($st) = https_req(path => '/hello');
like($st, qr{^HTTP/1\.0 200}, 'alive after non-TLS probe');

print "1..$T\n";
exit($FAIL ? 1 : 0);
