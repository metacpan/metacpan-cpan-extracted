#!perl
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Socket ();
use Fetch;

my $pid;   # file scope so the END block below can always reap the server

# $ua->clone(%overrides): a second agent over the same pool and loop. The
# reason it exists is per-request cookie isolation, so that is what most of
# this asserts - two clones of one agent must not see each other's cookies.

# ---- what is shared and what is not ----------------------------------------
{
    my $ua = Fetch->new(agent => 'parent/1', timeout => 9, max_redirects => 2);
    my $c  = $ua->clone(cookie_jar => 1);

    isa_ok($c, 'Fetch', 'clone');
    is($c->loop, $ua->loop, 'the loop is shared, not re-resolved');
    ok(!defined $ua->cookie_jar, 'the parent did not gain a jar');
    isa_ok($c->cookie_jar, 'Fetch::CookieJar', 'the clone got its own jar');

    my $d = $ua->clone(cookie_jar => 1);
    isnt($d->cookie_jar, $c->cookie_jar, 'two clones get two different jars');
}

# ---- the shared things cannot be overridden --------------------------------
{
    my $ua = Fetch->new;
    for my $k (qw(loop pool_size)) {
        eval { $ua->clone($k => 1) };
        like($@, qr/cannot be overridden/, "clone refuses to override $k");
    }
}

# ---- an inherited jar can be dropped ---------------------------------------
{
    my $ua = Fetch->new(cookie_jar => 1);
    isa_ok($ua->cookie_jar, 'Fetch::CookieJar', 'parent jar');
    my $c = $ua->clone;
    is($c->cookie_jar, $ua->cookie_jar, 'a clone inherits the parent jar');
    my $n = $ua->clone(cookie_jar => undef);
    ok(!defined $n->cookie_jar, 'cookie_jar => undef drops it');
}

# ---- the point: cookies do not cross between clones ------------------------
SKIP: {
    my $srv;
    socket($srv, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or skip 'no socket', 4;
    setsockopt($srv, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($srv, Socket::pack_sockaddr_in(0, Socket::inet_aton('127.0.0.1')))
        or skip 'no bind', 4;
    listen($srv, 20) or skip 'no listen', 4;
    my $port = (Socket::unpack_sockaddr_in(getsockname $srv))[0];

    $pid = fork;
    skip 'no fork', 4 unless defined $pid;
    if (!$pid) {
        # Never hold the harness TAP pipe open, and never outlive the run:
        # a leaked server child hangs the whole suite after this test is done.
        open STDOUT, '>', File::Spec->devnull();
        open STDERR, '>', File::Spec->devnull();
        alarm 120;
        # sets a cookie every time, and reports whichever one it was sent
        for (1 .. 8) {
            accept(my $cl, $srv) or last;
            my $req = '';
            while (sysread($cl, my $b, 4096)) { $req .= $b; last if $req =~ /\r\n\r\n/ }
            my ($seen) = $req =~ /^Cookie:[ \t]*(.*?)\r\n/mi;
            my $body = defined $seen ? "saw:$seen" : "saw:none";
            # This server closes after every response, so say so: without it
            # the client is entitled to pool the connection and the next
            # request races the close. Keep-alive reuse is t/20's subject,
            # cookie isolation is this one's.
            syswrite($cl, "HTTP/1.1 200 OK\r\nSet-Cookie: sid=secret; Path=/\r\n"
                        . "Connection: close\r\n"
                        . "Content-Length: " . length($body) . "\r\n\r\n$body");
            close $cl;
        }
        exit 0;
    }
    close $srv;

    my $url    = "http://127.0.0.1:$port/";
    my $shared = Fetch->new;
    my $a      = $shared->clone(cookie_jar => 1);
    my $b      = $shared->clone(cookie_jar => 1);

    is($a->get($url)->get->content, 'saw:none',
       'first request through a clone sends no cookie');
    is($a->get($url)->get->content, 'saw:sid=secret',
       'the clone remembers its own cookie');
    is($b->get($url)->get->content, 'saw:none',
       'a second clone never sees the first clone\'s cookie');
    is($shared->get($url)->get->content, 'saw:none',
       'and the jarless parent never collected one');

}

done_testing;

# In an END block, and SIGKILL: a die anywhere above must not leave a server
# child holding the harness's TAP pipe open.
END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
