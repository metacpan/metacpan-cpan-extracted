######################################################################
#
# t/0005-psgi-env.t - Verify that the PSGI $env hash contains the correct values.
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

# --- Pre-flight checks (all must pass before plan_tests is printed) -----

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

my $is_windows = ($^O =~ /\A(?:MSWin32|NetWare|symbian|dos)\z/);

# On Unix, fork() must be available.
unless ($is_windows) {
    plan_skip('fork() not available')
        unless $Config{d_fork} || $Config{d_pseudofork};
}

use HTTP::Handy;

# --- Test application code ----------------------------------------------
# Writes every scalar $env entry as "KEY=VALUE\n".
# Reference values (psgi.input, psgi.errors) are written as "KEY=PRESENT".
# The POST body read from psgi.input is appended as "POST_BODY=...".
my $lib_path = $FindBin::Bin . '/../lib';
my $app_code = <<"APP";
use lib "$lib_path";
use HTTP::Handy;
my \$port = $port;
my \$app = sub {
    my \$env = shift;
    my \$pb  = '';
    if ((\$env->{CONTENT_LENGTH} || 0) > 0) {
        \$env->{'psgi.input'}->read(\$pb, \$env->{CONTENT_LENGTH});
    }
    my \@lines;
    for my \$k (sort keys \%\$env) {
        next if ref \$env->{\$k};
        push \@lines, "\$k=" . (defined \$env->{\$k} ? \$env->{\$k} : '');
    }
    push \@lines, 'psgi.input=PRESENT'  if defined \$env->{'psgi.input'};
    push \@lines, 'psgi.errors=PRESENT' if defined \$env->{'psgi.errors'};
    push \@lines, "POST_BODY=\$pb"      if \$pb ne '';
    my \$body = join("\\n", \@lines) . "\\n";
    return [200, ['Content-Type', 'text/plain'], [\$body]];
};
HTTP::Handy->run(app => \$app, port => \$port, log => 0);
APP

# --- Start the server process -------------------------------------------
my $server_pid;
my $tmpfile;

if ($is_windows) {
    # Write the server code to a temporary file and launch asynchronously.
    # system(1, ...) is a Win32 Perl built-in: it starts the process
    # without waiting and returns its PID.
    $tmpfile = "tmp_psgienv_$$.pl";
    local *TMP;
    open TMP, ">$tmpfile" or plan_skip("cannot write temp file: $!");
    print TMP $app_code;
    close TMP;
    $server_pid = system(1, $^X, $tmpfile, $port);
    plan_skip("system(1,...) failed: $!") unless $server_pid;
}
else {
    # Unix: fork and run the server inline in the child process.
    # eval $app_code so the same code runs on both Unix and Windows.
    $server_pid = fork();
    die "fork: $!" unless defined $server_pid;
    if ($server_pid == 0) {
        eval $app_code;  ## no critic
        exit 0;
    }
}

# Wait up to 5 seconds (50 x 0.1s) for the server to start listening.
my $ready = 0;
for (1..50) {
    select undef, undef, undef, 0.1;
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp', Timeout => 1);
    if ($s) { close $s; $ready = 1; last }
}

# Terminate the server on exit.
# kill(9,...) on Windows maps to TerminateProcess; waitpid is not needed.
END {
    if ($server_pid) {
        kill 9, $server_pid;
        waitpid($server_pid, 0) unless $is_windows;
        $? = 0;
    }
    unlink $tmpfile if defined $tmpfile && -f $tmpfile;
}

plan_skip('server did not start') unless $ready;

# All pre-flight checks passed; now declare the number of tests.
print "1..22
";

# ok 1: server is up
ok(1, 'server ready');

# Send a raw HTTP request and parse the response body into a hash.
# The body is expected to contain lines of the form "KEY=VALUE".
sub send_and_parse {
    my $req = shift;
    my $s = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1', PeerPort => $port,
        Proto => 'tcp', Timeout => 5)
        or return ();
    print $s $req;
    my $raw = '';
    while (my $c = <$s>) { $raw .= $c }
    close $s;
    my (undef, $body) = split /\r\n\r\n/, $raw, 2;
    $body = defined $body ? $body : '';
    my %h;
    for (split /\n/, $body) { $h{$1} = $2 if /^([^=]+)=(.*)$/ }
    return %h;
}

# --- GET request $env (ok 2-12) -----------------------------------------
my %e;
%e = send_and_parse(
    "GET /some/path?foo=bar&baz=1 HTTP/1.0\r\n"
    . "Host: testhost:$port\r\n"
    . "User-Agent: EnvTest/1.0\r\n\r\n");

# ok 2-8: core CGI-style variables
is($e{REQUEST_METHOD},    'GET',           'GET: REQUEST_METHOD');   # ok 2
is($e{PATH_INFO},         '/some/path',    'GET: PATH_INFO');        # ok 3
is($e{QUERY_STRING},      'foo=bar&baz=1', 'GET: QUERY_STRING');     # ok 4
is($e{SERVER_NAME},       'testhost',      'GET: SERVER_NAME');      # ok 5
ok($e{SERVER_PORT} == $port,               'GET: SERVER_PORT');      # ok 6
ok($e{CONTENT_LENGTH} == 0,               'GET: CONTENT_LENGTH 0'); # ok 7
is($e{'psgi.url_scheme'}, 'http',          'GET: psgi.url_scheme');  # ok 8

# ok 9-10: psgi.* objects are present
is($e{'psgi.input'},  'PRESENT', 'GET: psgi.input');   # ok 9
is($e{'psgi.errors'}, 'PRESENT', 'GET: psgi.errors');  # ok 10

# ok 11-12: request headers appear as HTTP_* variables
is($e{HTTP_USER_AGENT}, 'EnvTest/1.0',    'GET: HTTP_USER_AGENT'); # ok 11
is($e{HTTP_HOST},       "testhost:$port", 'GET: HTTP_HOST');       # ok 12

# --- POST request $env (ok 13-19) ---------------------------------------
my $pb = 'name=ina&lang=perl553';
%e = send_and_parse(
    "POST /post/path HTTP/1.0\r\n"
    . "Host: localhost\r\n"
    . "Content-Type: application/x-www-form-urlencoded\r\n"
    . "Content-Length: " . length($pb) . "\r\n\r\n$pb");

# ok 13-16: core CGI-style variables
is($e{REQUEST_METHOD},  'POST',       'POST: REQUEST_METHOD');     # ok 13
is($e{PATH_INFO},       '/post/path', 'POST: PATH_INFO');          # ok 14
is($e{QUERY_STRING},    '',           'POST: QUERY_STRING empty'); # ok 15
ok($e{CONTENT_LENGTH} == length($pb), 'POST: CONTENT_LENGTH');    # ok 16

# ok 17: CONTENT_TYPE
like($e{CONTENT_TYPE}, qr{application/x-www-form-urlencoded}, 'POST: CONTENT_TYPE'); # ok 17

# ok 18-19: POST body is readable via psgi.input
is($e{'psgi.input'}, 'PRESENT', 'POST: psgi.input');         # ok 18
is($e{POST_BODY},    $pb,       'POST: body via psgi.input'); # ok 19

# --- Header name conversion (ok 20) -------------------------------------
# HTTP header hyphens must be converted to underscores with an HTTP_ prefix.
%e = send_and_parse(
    "GET / HTTP/1.0\r\n"
    . "Host: localhost\r\n"
    . "X-Custom-Header: myvalue\r\n\r\n");
is($e{HTTP_X_CUSTOM_HEADER}, 'myvalue', 'hyphen -> underscore'); # ok 20

# --- Root path (ok 21-22) -----------------------------------------------
%e = send_and_parse("GET / HTTP/1.0\r\nHost: localhost\r\n\r\n");

# ok 21: PATH_INFO is / for a bare request
is($e{PATH_INFO}, '/', 'PATH_INFO bare /');                  # ok 21

# ok 22: psgi.url_scheme is always http
is($e{'psgi.url_scheme'}, 'http', 'psgi.url_scheme http');   # ok 22

exit($FAIL ? 1 : 0);
