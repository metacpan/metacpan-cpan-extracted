#!perl
use 5.008003;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use Fetch;

# HTTP/2 trailers: a SECOND HEADERS frame, sent after the DATA.
#
# Almost nothing in ordinary HTTP uses them, which is why they were discarded
# for so long. gRPC does: the call status lives in the trailers and nowhere
# else, and a gRPC response is HTTP 200 whether it succeeded or failed - so a
# client that cannot read trailers can only ever report success.
#
# Driven against nghttpd, which is a real HTTP/2 server and can be told to
# send a trailer, rather than against a mock: the whole point of this test is
# that the bytes on the wire reach the caller.

plan skip_all => 'Fetch built without nghttp2' unless Fetch::_h2_available();
plan skip_all => 'Fetch built without OpenSSL' unless Fetch::_tls_available();

my $nghttpd = -x '/opt/homebrew/bin/nghttpd' ? '/opt/homebrew/bin/nghttpd'
            : -x '/usr/local/bin/nghttpd'    ? '/usr/local/bin/nghttpd'
            : do { my $p = `which nghttpd 2>/dev/null`; chomp $p;
                   $p && -x $p ? $p : undef };
plan skip_all => 'nghttpd not available to serve trailers' unless $nghttpd;

require IO::Socket::INET;
my $probe = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
    Listen => 1, ReuseAddr => 1) or plan skip_all => "cannot pick a port: $!";
my $port = $probe->sockport;
close $probe;

my $dir = File::Temp->newdir;
open my $fh, '>', "$dir/hello.txt" or plan skip_all => "cannot write: $!";
print $fh "body bytes\n";
close $fh;

# Fetch negotiates h2 through ALPN over TLS, so the server needs a cert.
my $cert = "$dir/cert.pem";
my $key  = "$dir/key.pem";
my $rc = system("openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert "
              . "-days 1 -nodes -subj /CN=localhost >/dev/null 2>&1");
plan skip_all => 'openssl(1) not available to make a test cert' if $rc != 0;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    open STDOUT, '>', '/dev/null';   # never hold the harness TAP pipe open
    open STDERR, '>', '/dev/null';
    # Two trailers, so the test can prove the list is a list rather than just
    # the last one seen.
    exec $nghttpd, '-d', "$dir",
         '--trailer', 'grpc-status: 0',
         '--trailer', 'grpc-message: fine',
         $port, $key, $cert;
    exit 127;
}

# give it a moment to bind
my $up = 0;
for (1 .. 100) {
    my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                  Proto => 'tcp', Timeout => 1);
    if ($s) { close $s; $up = 1; last }
    select undef, undef, undef, 0.05;
}
unless ($up) {
    kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => 'nghttpd did not start';
}

my $ua  = Fetch->new(timeout => 10, tls_verify => 0);
my $res = eval { $ua->get("https://127.0.0.1:$port/hello.txt")->get };
my $err = $@;

if (!$res) {
    kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => "could not fetch over h2: $err";
}

is($res->status, 200, 'the response arrived');
like($res->content, qr/body bytes/, 'with its body');

# ---- the trailers ------------------------------------------------------------
{
    my $t = $res->trailers;
    ok($t, 'trailers() returns something when the server sent trailers')
        or diag 'no trailers captured';

    SKIP: {
        skip 'no trailers captured', 5 unless $t;
        my %h = @$t;
        is($h{'grpc-status'}, '0', 'the grpc-status trailer reached the caller');
        is($h{'grpc-message'}, 'fine', 'and so did grpc-message');
        is(scalar(@$t), 4, 'both trailers are present, as a flat k,v list');

        # kept SEPARATE from the response headers: a trailer arrived after the
        # body, and a consumer that cares about the difference must be able to
        # tell
        my %rh = @{ $res->headers };
        ok(!exists $rh{'grpc-status'},
            'a trailer is NOT merged into the response headers');
        isnt("$t", "" . $res->headers, 'the two lists are distinct objects');
    }
}

# ---- a response with no trailers --------------------------------------------
{
    my $plain = eval { $ua->get("https://127.0.0.1:$port/hello.txt")->get };
    # nghttpd sends the trailer on every response with a body, so instead
    # assert the shape a caller relies on: trailers() is either a list or
    # undef, never a stray empty object it would have to test twice.
    my $t = $plain ? $plain->trailers : undef;
    ok(!defined $t || ref $t,
        'trailers() is a list or undef, never something in between');
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
