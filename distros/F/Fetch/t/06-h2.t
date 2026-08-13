#!perl
use 5.008003;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use Fetch;

# HTTP/2 over TLS (ALPN-negotiated). We stand up Hyperman as the server with
# tls + http2 => 1, giving a nice client/server symmetry across the Semantic
# stack. Needs OpenSSL+nghttp2 in the Fetch build and a Hyperman with both
# TLS and HTTP/2; skips cleanly otherwise.
plan skip_all => 'Fetch built without OpenSSL' unless Fetch::_tls_available();
plan skip_all => 'Fetch built without nghttp2' unless Fetch::_h2_available();
plan skip_all => 'Hyperman not installed'
    unless eval { require Hyperman; 1 };
plan skip_all => 'Hyperman built without TLS'
    unless Hyperman->can('has_tls') && Hyperman->has_tls;
plan skip_all => 'Hyperman built without HTTP/2'
    unless Hyperman->can('has_http2') && Hyperman->has_http2;

my $dir  = File::Temp->newdir;
my $cert = "$dir/cert.pem";
my $key  = "$dir/key.pem";
my $rc = system("openssl req -x509 -newkey rsa:2048 -keyout $key -out $cert "
              . "-days 1 -nodes -subj /CN=localhost >/dev/null 2>&1");
plan skip_all => 'openssl(1) not available to make a test cert' if $rc != 0;

require IO::Socket::INET;
my $probe = IO::Socket::INET->new(LocalHost => '127.0.0.1', LocalPort => 0,
    Listen => 1, ReuseAddr => 1) or plan skip_all => "cannot pick a port: $!";
my $port = $probe->sockport;
close $probe;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    open STDOUT, '>', '/dev/null';   # never hold the harness TAP pipe open
    open STDERR, '>', '/dev/null';
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p = $env->{PATH_INFO};
            return [ 200,
                [ 'Content-Type' => 'text/plain', 'X-Proto' => $env->{SERVER_PROTOCOL} ],
                [ "body-of$p" ] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
        http2 => 1, tls_cert => $cert, tls_key => $key,
    );
    exit 0;
}

# wait for the TLS listener to come up
my $up;
for (1 .. 50) {
    select(undef, undef, undef, 0.1);
    my $s = IO::Socket::INET->new(PeerHost => '127.0.0.1', PeerPort => $port);
    if ($s) { close $s; $up = 1; last }
}
unless ($up) { kill 'TERM', $pid; waitpid $pid, 0;
    plan skip_all => 'Hyperman server did not start' }

plan tests => 7;

my $ua   = Fetch->new;
my $base = "https://127.0.0.1:$port";

# ---- a single h2 GET negotiated via ALPN ---------------------------------
{
    my $res = $ua->get("$base/f0", tls_verify => 0)->get;
    is($res->status,  200,        'h2 GET status 200');
    is($res->content, 'body-of/f0', 'h2 body delivered');
    is($res->header('x-proto'), 'HTTP/2',
        'server saw the request as HTTP/2 (ALPN)');
}

# ---- header delivery over h2 ---------------------------------------------
{
    my $res = $ua->get("$base/f1", tls_verify => 0)->get;
    is($res->header('content-type'), 'text/plain',
        'h2 response carries headers');
}

# ---- many concurrent h2 requests all resolve, uncrossed ------------------
{
    my @f = map { $ua->get("$base/f$_", tls_verify => 0) } 1 .. 5;
    Fetch::Future->needs_all(@f)->get;
    is_deeply([ map { $_->get->status } @f ], [ (200) x 5 ],
        'five concurrent h2 requests all 200');
    is_deeply([ map { $_->get->content } @f ],
        [ map { "body-of/f$_" } 1 .. 5 ],
        'concurrent h2 bodies not crossed');
}

# ---- streaming an h2 body via on_body ------------------------------------
{
    my $seen = '';
    my $res  = $ua->get("$base/stream", tls_verify => 0,
        on_body => sub { $seen .= $_[0] })->get;
    is($seen, 'body-of/stream', 'h2 body delivered through on_body, not buffered');
}

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
