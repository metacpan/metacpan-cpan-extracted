######################################################################
#
# t/0004-server.t - Live HTTP server tests.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Config;
use Socket;
use IO::Socket;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub like { my($g,$re,$n)=@_; $T++; defined($g)&&$g=~$re ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

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

# Skip if fork is not available on this platform.
plan_skip('fork() not available')
    unless $Config{d_fork} || $Config{d_pseudofork};

# Skip if loopback TCP is not usable.
{
    # Suppress IO::Socket warning on Perl 5.005_03 when connection is refused.
    local $SIG{__WARN__} = sub {};
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => 1, Proto => 'tcp', Timeout => 2);
    plan_skip("loopback TCP unavailable: $!")
        unless $s || $!{ECONNREFUSED} || $! =~ /refused|connect/i;
}

my $port = _free_port();
plan_skip('no free port') unless $port;

use HTTP::Handy;

print "1..21
";

# --- Test application ---------------------------------------------------
# Returns different responses depending on PATH_INFO.
# /die intentionally dies to verify that the server catches exceptions.
my $test_app = sub {
    my $env    = shift;
    my $method = $env->{REQUEST_METHOD};
    my $path   = $env->{PATH_INFO};
    my $query  = $env->{QUERY_STRING} || '';

    if ($path eq '/hello') {
        return [200, ['Content-Type', 'text/plain'], ['Hello, World!']];
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
    if ($path eq '/echo-header') {
        return [200, ['Content-Type', 'text/plain'], [$env->{HTTP_USER_AGENT} || '']];
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
    if ($path eq '/multi-body') {
        return [200, ['Content-Type', 'text/plain'], ['part1', 'part2', 'part3']];
    }
    if ($path eq '/custom-header') {
        return [200, ['Content-Type', 'text/plain', 'X-HTTP-Handy', 'test-value'], ['ok']];
    }
    return [404, ['Content-Type', 'text/plain'], ['not found']];
};

# --- Fork the server ----------------------------------------------------
my $server_pid = fork();
die "fork: $!" unless defined $server_pid;
if ($server_pid == 0) {
    HTTP::Handy->run(app => $test_app, port => $port, log => 0);
    exit 0;
}

# Wait up to 5 seconds (50 x 0.1s) for the server to start listening.
my $ready = 0;
for (1..50) {
    select undef, undef, undef, 0.1;
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 1);
    if ($s) { close $s; $ready = 1; last }
}

# Terminate the server on exit.  Setting $? = 0 prevents the SIGTERM
# exit code from being propagated to prove.
END {
    if ($server_pid) {
        kill 'TERM', $server_pid;
        waitpid $server_pid, 0;
        $? = 0;
    }
}

plan_skip('server did not start') unless $ready;

# ok 1: server is up
ok(1, 'server started');

# Send an HTTP/1.0 request and return ($status_line, \%headers, $body).
# Header names are lowercased for case-insensitive comparison.
sub http_req {
    my (%a)    = @_;
    my $method = $a{method} || 'GET';
    my $path   = $a{path}   || '/';
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port,
        Proto => 'tcp', Timeout => 5)
        or return (undef, {}, undef);
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
    print $s $req;
    my $raw = '';
    while (my $c = <$s>) { $raw .= $c }
    close $s;
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    my @lines  = split /\r\n/, $head;
    my $status = shift @lines;
    my %h;
    for (@lines) { $h{lc $1} = $2 if /^([^:]+):\s*(.*)$/ }
    return ($status, \%h, defined $body ? $body : '');
}

# --- GET /hello (ok 2-6) ------------------------------------------------
my ($st, $hh, $bo);
($st, $hh, $bo) = http_req(path => '/hello');

# ok 2: status 200
like($st, qr{^HTTP/1\.0 200}, 'GET /hello: 200');
# ok 3: response body
is($bo, 'Hello, World!', 'GET /hello: body');
# ok 4: status line format is "HTTP/1.0 NNN <reason>"
like($st, qr{^HTTP/1\.0 \d{3} \S}, 'status line format');
# ok 5: Connection: close header is present
like(lc(defined $hh->{connection} ? $hh->{connection} : ''), qr{close}, 'Connection: close');
# ok 6: Content-Type header is present
like($hh->{'content-type'}, qr{text/plain}, 'Content-Type');

# --- Request data mapped to $env (ok 7-9) -------------------------------

# ok 7: REQUEST_METHOD is GET
($st, $hh, $bo) = http_req(path => '/echo-method');
is($bo, 'GET', 'REQUEST_METHOD GET');

# ok 8: QUERY_STRING is populated
($st, $hh, $bo) = http_req(path => '/echo-query?foo=bar&baz=1');
is($bo, 'foo=bar&baz=1', 'QUERY_STRING');

# ok 9: User-Agent header maps to HTTP_USER_AGENT
($st, $hh, $bo) = http_req(path => '/echo-header', headers => {'User-Agent' => 'NanoTest/1.0'});
is($bo, 'NanoTest/1.0', 'HTTP_USER_AGENT');

# --- Status codes (ok 10-14) --------------------------------------------

# ok 10: app returns 404
($st) = http_req(path => '/status/404');
like($st, qr{^HTTP/1\.0 404}, '404');

# ok 11: app returns 500
($st) = http_req(path => '/status/500');
like($st, qr{^HTTP/1\.0 500}, '500');

# ok 12: app die is converted to 500
($st) = http_req(path => '/die');
like($st, qr{^HTTP/1\.0 500}, 'app die -> 500');

# ok 13: server continues to accept requests after an app die
($st) = http_req(path => '/hello');
like($st, qr{^HTTP/1\.0 200}, 'alive after die');

# ok 14: unsupported method returns 405
($st) = http_req(method => 'DELETE', path => '/hello');
like($st, qr{^HTTP/1\.0 405}, 'DELETE -> 405');

# --- POST (ok 15-16) ----------------------------------------------------

# ok 15: REQUEST_METHOD is POST
($st, $hh, $bo) = http_req(method => 'POST', path => '/echo-method');
is($bo, 'POST', 'POST method');

# ok 16: POST body is readable via psgi.input
($st, $hh, $bo) = http_req(method => 'POST', path => '/echo-post', body => 'name=ina&lang=perl');
is($bo, 'name=ina&lang=perl', 'POST body');

# --- Miscellaneous (ok 17-21) -------------------------------------------

# ok 17: multi-element body array is joined before sending
($st, $hh, $bo) = http_req(path => '/multi-body');
is($bo, 'part1part2part3', 'multi-body joined');

# ok 18: custom response header is delivered to the client
($st, $hh) = http_req(path => '/custom-header');
is($hh->{'x-http-handy'}, 'test-value', 'custom header');

# ok 19: unknown path returns 404
($st) = http_req(path => '/no/such/path');
like($st, qr{^HTTP/1\.0 404}, 'unknown path 404');

# ok 20: QUERY_STRING is empty when no query string is present
($st, $hh, $bo) = http_req(path => '/echo-query');
is($bo, '', 'empty QUERY_STRING');

# ok 21: QUERY_STRING is separated from PATH_INFO
($st, $hh, $bo) = http_req(path => '/echo-query?x=1');
is($bo, 'x=1', 'QUERY_STRING from PATH_INFO');

exit($FAIL ? 1 : 0);
