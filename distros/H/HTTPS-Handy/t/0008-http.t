######################################################################
#
# t/0008-http.t - The HTTP half, driven without a socket.
#
#   _handle_connection only ever calls read_line, read_bytes,
#   write_data, cipher_name and was_resumed on the connection it is
#   given. A few lines of Perl provide all five out of a string, so the
#   whole request and response path can be tested in memory: no TLS, no
#   socket, no fork, and therefore no skip on Windows.
#
#   Covered here: the request line, headers, the PSGI environment, the
#   response, what happens when the request or the application
#   misbehaves, and that the log option really does silence this
#   module.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec ();

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }

use HTTPS::Handy;

###############################################################################
# A connection made of two strings
###############################################################################
{
    package HTTPS::Handy::Test::Conn;

    sub new {
        my ($class, $request) = @_;
        return bless { 'in' => $request, 'out' => '' }, $class;
    }

    sub read_line {
        my ($self) = @_;
        return undef if $self->{'in'} eq '';
        my $nl = index($self->{'in'}, "\n");
        my $line;
        if ($nl < 0) {
            $line = $self->{'in'};
            $self->{'in'} = '';
        }
        else {
            $line = substr($self->{'in'}, 0, $nl + 1);
            $self->{'in'} = substr($self->{'in'}, $nl + 1);
        }
        return $line;
    }

    sub read_bytes {
        my ($self, $n) = @_;
        my $out = substr($self->{'in'}, 0, $n);
        $self->{'in'} = (length($self->{'in'}) > $n)
                      ? substr($self->{'in'}, $n) : '';
        return $out;
    }

    sub write_data {
        my ($self, $data) = @_;
        $self->{'out'} .= $data;
        return 1;
    }

    sub cipher_name { return 'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256' }
    sub was_resumed { return 0 }
}

# _serve - Run one request through the server and return the response
sub _serve {
    my ($request, $app, %opt) = @_;
    my $conn = HTTPS::Handy::Test::Conn->new($request);
    HTTPS::Handy::_handle_connection(
        $conn, $app, (defined $opt{'log'} ? $opt{'log'} : 0),
        (defined $opt{'max_post_size'} ? $opt{'max_post_size'} : 1048576),
        8443);
    my $raw = $conn->{'out'};
    my ($head, $body) = split /\r\n\r\n/, $raw, 2;
    $head = '' unless defined $head;
    my @lines = split /\r\n/, $head;
    my $status = @lines ? shift(@lines) : '';
    my %h;
    for my $l (@lines) { $h{lc $1} = $2 if $l =~ /^([^:]+):\s*(.*)$/ }
    return ($status, { %h }, (defined $body ? $body : ''), $raw);
}

my $echo_env;
my $app = sub {
    my ($env) = @_;
    $echo_env = $env;
    return HTTPS::Handy->response_text("path=$env->{PATH_INFO}");
};

######################################################################
# The request line and the environment
######################################################################

my ($status, $head, $body, $raw);

($status, $head, $body) = _serve("GET /hello?a=1&b=2 HTTP/1.0\r\nHost: example.jp:8443\r\n\r\n", $app);
is($status, 'HTTP/1.0 200 OK', 'GET: the status line');
is($body, 'path=/hello', 'GET: the body the application returned');
is($head->{'connection'}, 'close', 'GET: Connection: close is always sent');
is($echo_env->{'REQUEST_METHOD'}, 'GET',   'env: REQUEST_METHOD');
is($echo_env->{'PATH_INFO'},      '/hello', 'env: PATH_INFO without the query');
is($echo_env->{'QUERY_STRING'},   'a=1&b=2', 'env: QUERY_STRING without the "?"');
is($echo_env->{'SERVER_NAME'},    'example.jp', 'env: SERVER_NAME without the port');
is($echo_env->{'SERVER_PORT'},    8443, 'env: SERVER_PORT from the Host header');
is($echo_env->{'psgi.url_scheme'}, 'https', 'env: psgi.url_scheme');
is($echo_env->{'psgi.ssl'},        1,       'env: psgi.ssl');
is($echo_env->{'psgix.tls_cipher'},
   'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256', 'env: psgix.tls_cipher');
is($echo_env->{'psgix.tls_resumed'}, 0, 'env: psgix.tls_resumed');

# A request with no query string at all
($status, $head, $body) = _serve("GET / HTTP/1.0\r\n\r\n", $app);
is($echo_env->{'QUERY_STRING'}, '', 'env: QUERY_STRING is empty when there is none');
is($echo_env->{'SERVER_PORT'}, 8443, 'env: SERVER_PORT falls back to the bound port');

# Headers become HTTP_* with hyphens turned into underscores
($status, $head, $body) = _serve(
    "GET / HTTP/1.0\r\nUser-Agent: test/1.0\r\nX-Two-Words: yes\r\n\r\n", $app);
is($echo_env->{'HTTP_USER_AGENT'}, 'test/1.0', 'env: HTTP_USER_AGENT');
is($echo_env->{'HTTP_X_TWO_WORDS'}, 'yes',     'env: hyphens become underscores');

######################################################################
# POST
######################################################################

my $post_app = sub {
    my ($env) = @_;
    my $buf = '';
    $env->{'psgi.input'}->read($buf, $env->{'CONTENT_LENGTH'});
    return HTTPS::Handy->response_text("got:$buf");
};

# The body is longer than Content-Length says: only the declared
# number of bytes belongs to this request
($status, $head, $body) = _serve(
    "POST /f HTTP/1.0\r\nContent-Type: application/x-www-form-urlencoded\r\n"
  . "Content-Length: 8\r\n\r\nname=ina&x=1", $post_app);
is($status, 'HTTP/1.0 200 OK', 'POST: the status line');
is($body, 'got:name=ina', 'POST: exactly Content-Length bytes are read');

# A Content-Length that is not a number must not be believed, and must
# not make Perl complain either
($status, $head, $body) = _serve(
    "POST /f HTTP/1.0\r\nContent-Length: abc\r\n\r\nbody", $post_app);
is($status, 'HTTP/1.0 200 OK', 'POST: a non-numeric Content-Length is survivable');
is($body, 'got:', 'POST: and is treated as no body at all');

# Too large a body is refused before it is read
($status, $head, $body) = _serve(
    "POST /f HTTP/1.0\r\nContent-Length: 5000\r\n\r\n", $post_app,
    max_post_size => 100);
is($status, 'HTTP/1.0 413 Request Entity Too Large', 'POST: over the limit is refused');

######################################################################
# Methods and failures
######################################################################

($status) = _serve("DELETE / HTTP/1.0\r\n\r\n", $app);
is($status, 'HTTP/1.0 405 Method Not Allowed', 'DELETE is refused');

($status) = _serve('', $app);
is($status, '', 'a client that sends nothing gets no response');

($status) = _serve("\r\n", $app);
is($status, 'HTTP/1.0 405 Method Not Allowed',
   'a request line with no method is refused');

($status) = _serve("GET / HTTP/1.0\r\n\r\n", sub { die "on purpose\n" });
is($status, 'HTTP/1.0 500 Internal Server Error', 'an application that dies gives 500');

($status) = _serve("GET / HTTP/1.0\r\n\r\n", sub { return 'not an arrayref' });
is($status, 'HTTP/1.0 500 Internal Server Error', 'a malformed response gives 500');

($status) = _serve("GET / HTTP/1.0\r\n\r\n", sub { return [ 200, [] ] });
is($status, 'HTTP/1.0 500 Internal Server Error', 'a two element response gives 500');

######################################################################
# The response cannot be forged by the application
######################################################################

# A header value holding CR LF would otherwise end the headers early
($status, $head, $body, $raw) = _serve("GET / HTTP/1.0\r\n\r\n", sub {
    return [200, [ 'X-Note', "ok\r\nX-Injected: yes" ], [ 'body' ] ];
});
is($status, 'HTTP/1.0 200 OK', 'response splitting: the status line survives');
ok(!exists $head->{'x-injected'}, 'response splitting: no extra header appears');
is($head->{'x-note'}, 'okX-Injected: yes',
   'response splitting: the line breaks are removed from the value');
is($body, 'body', 'response splitting: the body is still the body');

# So would a newline in a header name
($status, $head) = _serve("GET / HTTP/1.0\r\n\r\n", sub {
    return [200, [ "X-A\r\nX-B", 'v' ], [ '' ] ];
});
ok(!exists $head->{'x-b'}, 'a newline in a header name does not split it in two');

# A status that is not three digits must not reach the status line
($status) = _serve("GET / HTTP/1.0\r\n\r\n", sub {
    return [ "200 OK\r\nX-Bad: 1", [], [ '' ] ];
});
is($status, 'HTTP/1.0 500 Internal Server Error', 'a non-numeric status becomes 500');

# An unknown but well formed status is passed through
($status) = _serve("GET / HTTP/1.0\r\n\r\n", sub { return [ 418, [], [ '' ] ] });
is($status, 'HTTP/1.0 418 Unknown', 'an unlisted status code still works');

######################################################################
# The log option governs everything this module prints
######################################################################
#
# An application that dies is worth a line on STDERR, but only when
# logging is on. Running the test suite must not print anything, and a
# caller who asked for silence must get it.
######################################################################

# _serve_capturing - Run one request with STDERR diverted to a file
sub _serve_capturing {
    my ($request, $app, %opt) = @_;
    my $tmp = File::Spec->catfile(File::Spec->tmpdir, "https_handy_err_$$.txt");
    local *SAVEERR;
    open(SAVEERR, '>&STDERR') or return '(cannot save STDERR)';
    unless (open(STDERR, ">$tmp")) {
        open(STDERR, '>&SAVEERR');
        close SAVEERR;
        return '(cannot redirect STDERR)';
    }
    _serve($request, $app, %opt);
    open(STDERR, '>&SAVEERR');
    close SAVEERR;

    my $text = '';
    local *ERRFILE;
    if (open(ERRFILE, "<$tmp")) {
        local $/;
        my $data = <ERRFILE>;
        close ERRFILE;
        $text = defined $data ? $data : '';
    }
    unlink $tmp;
    return $text;
}

{
    my $dying = sub { die "on purpose\n" };

    my $quiet = _serve_capturing("GET / HTTP/1.0\r\n\r\n", $dying, log => 0);
    is($quiet, '', 'log => 0: an application that dies prints nothing');

    my $loud = _serve_capturing("GET / HTTP/1.0\r\n\r\n", $dying, log => 1);
    ok(($loud =~ /App error: on purpose/) ? 1 : 0,
       'log => 1: the application error is reported');

    my $access = _serve_capturing("GET /x HTTP/1.0\r\n\r\n", $app, log => 1);
    ok(($access =~ /\btime:.*\tmethod:GET\tpath:\/x\tstatus:200\b/) ? 1 : 0,
       'log => 1: the access log line is written in LTSV');

    my $none = _serve_capturing("GET /x HTTP/1.0\r\n\r\n", $app, log => 0);
    is($none, '', 'log => 0: no access log either');
}

######################################################################
# serve_static refuses what it should
######################################################################

{
    my $env = { 'PATH_INFO' => '/../lib/HTTPS/Handy.pm' };
    my $res = HTTPS::Handy->serve_static($env, '.');
    is($res->[0], 403, 'serve_static: ".." is refused');

    $env = { 'PATH_INFO' => "/a\x00b.txt" };
    $res = HTTPS::Handy->serve_static($env, '.');
    is($res->[0], 403, 'serve_static: a null byte in the path is refused');

    $env = { 'PATH_INFO' => "/a\nb.txt" };
    $res = HTTPS::Handy->serve_static($env, '.');
    is($res->[0], 403, 'serve_static: a newline in the path is refused');

    $env = { 'PATH_INFO' => '/no/such/file.txt' };
    $res = HTTPS::Handy->serve_static($env, '.');
    is($res->[0], 404, 'serve_static: a missing file is 404');
}

print "1..$T\n";
exit($FAIL ? 1 : 0);
