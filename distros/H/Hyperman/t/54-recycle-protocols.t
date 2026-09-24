#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use Time::HiRes ();
use File::Path ();
use Hyperman;

# max_requests_per_worker is a property of the WORKER, so every protocol that
# finishes a request has to move it towards the bound. It was tested over
# HTTP/1.0 alone, and the h2 and h3 paths counted the request without ever
# testing the bound: a pool serving browsers (which all negotiate h2, and h3
# where it is offered) never recycled, and the worker the option existed to
# retire grew until the box killed it.
#
# The worker answers with its own pid, and the test counts DISTINCT pids
# rather than watching for a change. In a pool of two the pid changes on
# every other request without anything having been recycled, so a change
# proves nothing; more pids than there are workers can only mean a worker
# was replaced.

plan skip_all => 'the worker pool needs fork(2)' if $^O eq 'MSWin32';
plan skip_all => 'nghttp2 support not built'     unless Hyperman->has_http2;

my $curl = `which curl 2>/dev/null`;
chomp $curl;
plan skip_all => 'curl not found' unless $curl;
plan skip_all => 'curl lacks HTTP/2'
    unless `curl --version 2>/dev/null` =~ /\bHTTP2\b/;

my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $WORKERS = 2;
my $MAX     = 5;

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    quiet_child();
    require Hyperman;
    Hyperman->run(
        app     => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "w$$" ] ] },
        host    => '127.0.0.1',
        port    => $port,
        workers => $WORKERS,
        http2   => 1,
        max_requests_per_worker => $MAX,
    );
    exit 0;
}

sub who {
    my ($proto) = @_;
    my $out = `$curl -s --$proto http://127.0.0.1:$port/ 2>/dev/null`;
    return $out =~ /\Aw(\d+)\z/ ? $1 : undef;
}

# How many different workers answered over $n requests. A recycle shows as a
# pid nothing else could have produced.
sub pids_over {
    my ($proto, $n) = @_;
    my %seen;
    for (1 .. $n) {
        my $w = who($proto) or next;
        $seen{$w}++;
    }
    return scalar keys %seen;
}

# The pool needs a moment to bind and fork; a worker that is not up yet
# answers nothing, and that is not a failure of the thing under test.
my $up;
for (1 .. 50) {
    $up = who('http1.1');
    last if $up;
    Time::HiRes::sleep(0.1);
}

SKIP: {
    skip 'server never answered', 3 unless $up;

    # Enough requests that every worker passes the bound several times over.
    my $n = $WORKERS * $MAX * 4;

    # HTTP/1.1 first: the path that always worked, so a failure here is the
    # harness and not the fix.
    cmp_ok pids_over('http1.1', $n), '>', $WORKERS,
        "HTTP/1.1 retires a worker at max_requests_per_worker "
        . "(more than $WORKERS pids over $n requests)";

    # HTTP/2, the regression. Prior knowledge over cleartext, which is what
    # h2 without a certificate in the way looks like.
    my $h2_up;
    for (1 .. 50) {
        $h2_up = who('http2-prior-knowledge');
        last if $h2_up;
        Time::HiRes::sleep(0.1);
    }

    SKIP: {
        skip 'h2 never answered', 2 unless $h2_up;

        cmp_ok pids_over('http2-prior-knowledge', $n), '>', $WORKERS,
            "HTTP/2 retires a worker at max_requests_per_worker "
            . "(more than $WORKERS pids over $n requests)";

        # A recycle that left no worker behind would also show as new pids,
        # and is the same outage this option is meant to prevent.
        my $still;
        for (1 .. 50) {
            $still = who('http2-prior-knowledge');
            last if $still;
            Time::HiRes::sleep(0.1);
        }
        ok defined $still, 'the pool still answers over h2 after the recycles';
    }
}

kill 'TERM', $sup;
waitpid $sup, 0;

# ---- HTTP/3, which needs its own server: QUIC wants a certificate ----------
#
# Its own curl too. A tool can accept --http3 and have no QUIC in it, so the
# client is chosen by the HTTP3 feature and driven with --http3-only, or
# nothing here could be told apart from a pass over TCP.

SKIP: {
    skip 'HTTP/3 support not built', 1 unless Hyperman->has_http3;

    my $h3curl;
    for my $c ('/opt/homebrew/opt/curl/bin/curl', '/usr/local/opt/curl/bin/curl',
               split /\n/, `which -a curl 2>/dev/null` || '') {
        next unless $c && -x $c;
        next unless (`$c --version 2>/dev/null` || '') =~ /^Features:.*\bHTTP3\b/m;
        $h3curl = $c;
        last;
    }
    skip 'no HTTP/3-capable curl', 1 unless $h3curl;

    my $openssl = `which openssl 2>/dev/null`;
    chomp $openssl;
    skip 'no openssl to make a test certificate', 1 unless $openssl;

    my $dir = "hm_recycle_h3_$$";
    mkdir $dir or skip "cannot make $dir", 1;
    my ($cert, $key) = ("$dir/c.pem", "$dir/k.pem");
    my $made = system(qq{$openssl req -x509 -newkey rsa:2048 -keyout $key }
                    . qq{-out $cert -days 1 -nodes -subj "/CN=localhost" }
                    . qq{>/dev/null 2>&1}) == 0;
    unless ($made) {
        File::Path::remove_tree($dir);
        skip 'openssl could not make a test certificate', 1;
    }

    my ($h3port) = free_ports(1);
    unless ($h3port) {
        File::Path::remove_tree($dir);
        skip 'no free loopback port', 1;
    }

    my $h3sup = fork;
    die "fork: $!" unless defined $h3sup;
    if ($h3sup == 0) {
        quiet_child();
        require Hyperman;
        Hyperman->run(
            app      => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "w$$" ] ] },
            host     => '127.0.0.1',
            port     => $h3port,
            workers  => $WORKERS,
            http3    => 1,
            tls_cert => $cert,
            tls_key  => $key,
            max_requests_per_worker => $MAX,
        );
        exit 0;
    }

    my $h3who = sub {
        my $out = `$h3curl -sk --http3-only https://127.0.0.1:$h3port/ 2>/dev/null`;
        return $out =~ /\Aw(\d+)\z/ ? $1 : undef;
    };

    my $h3up;
    for (1 .. 80) {
        $h3up = $h3who->();
        last if $h3up;
        Time::HiRes::sleep(0.1);
    }

    if ($h3up) {
        my %seen;
        for (1 .. $WORKERS * $MAX * 4) {
            my $w = $h3who->() or next;
            $seen{$w}++;
        }
        cmp_ok scalar keys %seen, '>', $WORKERS,
            "HTTP/3 retires a worker at max_requests_per_worker "
            . "(more than $WORKERS pids)";
    }

    kill 'TERM', $h3sup;
    waitpid $h3sup, 0;
    File::Path::remove_tree($dir);

    skip 'h3 never answered', 1 unless $h3up;
}

done_testing;
