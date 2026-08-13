#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# ---- a small forking-free test server ------------------------------------
# Accepts in a loop and echoes the request method, path and body so we can
# assert what the client actually sent. Runs in a child process.
my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    # Never hold the harness TAP pipe open, and never outlive the run:
    # a leaked server child hangs the whole suite after this test is done.
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    while (my $cli = $srv->accept) {
        my ($line, %h);
        $line = <$cli>;
        my ($method, $path) = $line =~ m{^(\S+)\s+(\S+)};
        while (my $l = <$cli>) {
            last if $l eq "\r\n";
            $h{lc $1} = $2 if $l =~ /^([^:]+):\s*(.*?)\r\n$/;
        }
        my $body = '';
        if (my $len = $h{'content-length'}) { read($cli, $body, $len) }
        my $status = $path eq '/notfound' ? '404 Not Found' : '200 OK';
        my $out = "method=$method path=$path body=$body";
        print $cli "HTTP/1.1 $status\r\n"
                 . "Content-Type: text/plain\r\n"
                 . "Content-Length: " . length($out) . "\r\n"
                 . "X-Echo: yes\r\n"
                 . "Connection: close\r\n\r\n$out";
        close $cli;
    }
    exit 0;
}
select(undef, undef, undef, 0.2);   # let the child bind/listen

my $base = "http://127.0.0.1:$port";
my $ua   = Fetch->new;

plan tests => 11;

# ---- GET -----------------------------------------------------------------
{
    my $res = $ua->get("$base/hello")->get;
    isa_ok($res, 'Fetch::Response', 'get returns a Fetch::Response');
    is($res->status, 200, 'GET status 200');
    ok($res->is_success, 'is_success true');
    is($res->header('Content-Type'), 'text/plain', 'header() case-insensitive');
    like($res->content, qr/method=GET path=\/hello/, 'server saw GET /hello');
}

# ---- POST with a body ----------------------------------------------------
{
    my $res = $ua->post("$base/submit", body => 'ping123')->get;
    is($res->status, 200, 'POST status 200');
    like($res->content, qr/method=POST path=\/submit body=ping123/,
        'server received the POST body');
}

# ---- non-2xx status is surfaced, not an error ----------------------------
{
    my $res = $ua->get("$base/notfound")->get;
    is($res->status, 404, '404 surfaced as a normal response');
    ok(!$res->is_success, 'is_success false for 404');
}

# ---- concurrency: many requests share one loop ---------------------------
{
    my @f = map { $ua->get("$base/c$_") } 1 .. 8;
    my $all = Fetch::Future->needs_all(@f);
    $all->get;
    my @codes = map { $_->get->status } @f;
    is_deeply(\@codes, [ (200) x 8 ], 'eight concurrent GETs all 200');
    like(($f[3]->get)->content, qr{path=/c4}, 'concurrent responses not crossed');
}

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
