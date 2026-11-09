#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp ();
use Hyperman;
use Hyperman::Loop;
use Hyperman::Future;

# The refusals and the odd shapes of the public API that need no server:
# run() checks its options before it binds or forks, the loop and the futures
# take theirs, and the writer and the bus answer for shapes they do not own.

my $app = sub { [ 200, [], ['ok'] ] };
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

sub refuses {
    my ($re, $name, @opts) = @_;
    eval { Hyperman->run(app => $app, @opts) };
    like($@, $re, $name);
}

# --- the API outside a running loop, before any run() has made an arena ---
eval { Hyperman->io_ready(\*STDIN) };
like($@, qr/no event loop is running/, 'io_ready needs a loop');
eval { Hyperman::detach({}) };
like($@, qr/detach: no running loop/, 'detach needs a loop');
eval { Hyperman::stream({}, 200, []) };
like($@, qr/stream: no running loop/, 'stream needs a loop');
ok(!defined Hyperman->loop, 'no current loop');
ok(!defined Hyperman->stats, 'no stats without a loop');
ok(!defined Hyperman->stats(pool => 1), 'no pool stats without a board');
is_deeply([ Hyperman->pool_stats ], [], 'no scoreboard rows');
ok(!defined Hyperman->leader('x'), 'no leader without an arena');
is_deeply([ Hyperman->distinct_clients ], [], 'no distinct client sketch');
is(Hyperman->bus_waker_take(0), -1, 'no waker without a bus');
Hyperman->bus_waker_drained;
pass('draining without a bus is harmless');
eval { Hyperman->subscribe('topic', 'not code') };
like($@, qr/subscribe: need a code reference/, 'subscribe wants code');

# --- run() ---
eval { Hyperman->run('lonely') };
like($@, qr/odd number of options/, 'an odd option list');
eval { Hyperman->run(port => 1) };
like($@, qr/'app' is required/, 'no app');
refuses(qr/unknown option 'nope'/, 'an unknown option', nope => 1);
refuses(qr/tls_verify must be/, 'a bad tls_verify', tls_verify => 'maybe');
refuses(qr/compress_level must be 1\.\.9/, 'a compress level out of range', compress_level => 12);
refuses(qr/max_body must be a byte count/, 'a zero max_body', max_body => 0);
refuses(qr/umask '0x' is not an octal number/, 'a umask that is not octal', umask => '0x');
refuses(qr/'listen' must be an arrayref/, 'a listen that is not a list', listen => 'nope');
refuses(qr/'listen'\/'port' is empty/, 'an empty port list', port => []);
refuses(qr/listen\[0\] must be a hashref/, 'a listen entry that is not a hash', listen => ['nope']);
refuses(qr/unknown listen option 'zzz'/, 'an unknown listen option', listen => [ { port => 1, zzz => 1 } ]);
refuses(qr/mode 'q' is not an octal number/, 'a path mode that is not octal', listen => [ { path => '/tmp/x.sock', mode => 'q' } ]);
refuses(qr/tls_verify must be/, 'a bad tls_verify on a listener', listen => [ { port => 1, tls_verify => 'maybe' } ]);
refuses(qr/tls_cert and tls_key must be given together/, 'a certificate without a key', tls_cert => '/no/cert');
refuses(qr/tls_verify needs tls_ca/, 'a verify without a CA', tls_cert => '/no/cert', tls_key => '/no/key', tls_verify => 'require');
refuses(qr/redirect_https on a TLS listener/, 'a redirect on a TLS listener', tls_cert => '/no/cert', tls_key => '/no/key', redirect_https => 1);
SKIP: {
    skip 'http2 is built in', 1 if Hyperman->has_http2;
    refuses(qr/http2 requested but nghttp2/, 'http2 without nghttp2', http2 => 1);
}
SKIP: {
    skip 'http3 is built in', 1 if Hyperman->can('has_http3') && Hyperman->has_http3;
    refuses(qr/http3 requested but QUIC/, 'http3 without QUIC', http3 => 1);
}
{
    no warnings 'once';
    refuses(qr/access_log handle has no fileno/, 'an access_log glob with no handle', access_log => \*NOSUCH);
    refuses(qr/error_log handle has no fileno/, 'an error_log glob with no handle', error_log => \*NOSUCH2);
}
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    refuses(qr/pid_file path too long/, 'a pid_file path past the buffer', pid_file => '/' . ('p' x 5000));
    refuses(qr/pid_file '.*': /, 'a pid_file in a missing directory', pid_file => "$dir/nope/x.pid", port => 0);
    refuses(qr/path is empty or longer/, 'a unix path too long', listen => [ { path => '/' . ('s' x 200) } ]);
    refuses(qr/malformed bracketed address|cannot resolve|getaddrinfo/, 'a bracketed host with no closing bracket', host => '[::1', port => 0);
}

# --- refusals that come after the options, still before a bind or a fork ---
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    refuses(qr/bind|CPU affinity is Linux-only/, "the counter, pool and affinity options are parsed", host => "203.0.113.1", port => 1, rate_capacity => 16, bus_slots => 8, bus_groups => 2, affinity => 1, tls_verify => "none");
    refuses(qr/reuseport cannot rebind a path listener/, 'reuseport with a path listener', listen => [ { path => "$dir/h.sock" } ], reuseport => 1);
    refuses(qr/open error_log '.*nope/, 'an error_log in a missing directory', error_log => "$dir/nope/e.log", port => 0);
    refuses(qr/open access_log '.*nope/, 'an access_log in a missing directory', access_log => "$dir/nope/a.log", port => 0);
    refuses(qr/access_log_format: unknown directive %\{\.\.\.\}z/, 'a %{...} directive with an unknown kind', access_log => "$dir/a.log", access_log_format => '%{x}z', port => 0);
    refuses(qr/access_log_format: unknown directive %\{\}/, 'an empty %{...} name', access_log => "$dir/a.log", access_log_format => '%{}i', port => 0);
    refuses(qr/access_log_format: unknown directive %\{\.\.\.\}\?/, 'an unclosed %{', access_log => "$dir/a.log", access_log_format => '%{abc', port => 0);
    SKIP: {
        skip 'TLS is not built in', 1 unless Hyperman->has_tls;
        open my $fh, '>', "$dir/bad.pem" or die; print $fh "not a certificate\n"; close $fh;
        refuses(qr/TLS: could not initialise from cert/, 'a certificate that does not parse', tls_cert => "$dir/bad.pem", tls_key => "$dir/bad.pem", port => 0);
    }
    eval { Hyperman::Loop::run('not a loop') };
    like($@, qr/not a Hyperman::Loop/, 'a loop method on something else');
    SKIP: {
        skip 'http3 is not built in', 3 unless Hyperman->has_http3;
        refuses(qr/http3 needs an IP listener/, 'http3 on a path listener', listen => [ { path => "$dir/q.sock", http3 => 1, tls_cert => '/no/cert', tls_key => '/no/key' } ]);
        @warned = ();
        refuses(qr/TLS: could not initialise/, 'proxy_protocol beside http3 warns and goes on', http3 => 1, proxy_protocol => 1, tls_cert => "$dir/bad.pem", tls_key => "$dir/bad.pem", port => 0);
        ok(scalar(grep { /proxy_protocol applies to the TCP side/ } @warned), 'with the warning');
    }
    # The low port is on an address no box has (TEST-NET-1), so a bind would
    # fail everywhere, root or not: the refusal has to come before it.
    SKIP: {
        skip 'no root entry here', 3 unless getpwuid(0);
        refuses(qr/user => with reuseport => 1 cannot rebind port 80/, 'a numeric user resolves through getpwuid', user => '0', reuseport => 1, host => '192.0.2.1', port => 80);
        refuses(qr/user => with reuseport => 1 cannot rebind port 80/, 'and a numeric group is taken as it is', user => '0', group => '0', reuseport => 1, host => '192.0.2.1', port => 80);
        refuses(qr/group 'no-such-group-\d+': no such group/, 'a group that does not exist', user => '0', group => "no-such-group-$$", port => 0);
    }
    refuses(qr/user \d+ has no passwd entry; name a group/, 'a uid with no entry and no group', user => '4000000000', port => 0);
    SKIP: {
        skip 'no nobody user here', 1 unless getpwnam('nobody');
        refuses(qr/user => with reuseport => 1 cannot rebind port 80/, 'a dropped user with reuseport on a low port', user => 'nobody', reuseport => 1, host => '192.0.2.1', port => 80);
        refuses(qr/user '.*' is not known|unknown user|no such user/i, 'a user that does not exist', user => 'no-such-user-here-' . $$, port => 0);
    }
    SKIP: {
        skip 'socket activation is not on Windows', 8 if $^O eq 'MSWin32';
        require IO::Socket::INET;
        require POSIX;
        {
            delete local $ENV{LISTEN_FDS};
            delete local $ENV{LISTEN_PID};
            refuses(qr/LISTEN_FDS and LISTEN_PID are not set/, 'inherit without the environment', listen_fds => 1, port => 0);
        }
        local $ENV{LISTEN_FDS} = 1;
        local $ENV{LISTEN_PID} = $$ + 1;
        refuses(qr/LISTEN_PID is \d+, this is \d+/, 'a LISTEN_PID that is not this process', listen_fds => 1, port => 0);
        $ENV{LISTEN_PID} = $$;
        refuses(qr/an inherited socket cannot be rebound per worker/, 'inherit with reuseport', listen => [ { port => 0, inherit => 1 } ], reuseport => 1);
        $ENV{LISTEN_FDS} = 0;
        refuses(qr/LISTEN_FDS=0 but listener 0 wants one too/, 'fewer sockets than listeners', listen_fds => 1, port => 0);
        $ENV{LISTEN_FDS} = 1;
        open my $plain, '<', $0 or die;
        POSIX::dup2(fileno $plain, 3) or die "dup2: $!";
        refuses(qr/inherited fd 3: getsockname/, 'an inherited fd that is not a socket', listen_fds => 1, port => 0);
        my $un = IO::Socket::UNIX->new(Type => IO::Socket::SOCK_STREAM(), Local => "$dir/fam.sock", Listen => 1) or die "unix socket: $!";
        POSIX::dup2(fileno $un, 3) or die "dup2: $!";
        refuses(qr/inherited fd 3 is address family \d+, listener 0 resolved to \d+/, 'an inherited socket of the wrong family', listen_fds => 1, host => '127.0.0.1', port => 0);
        SKIP: {
            skip 'SO_ACCEPTCONN answers only on Linux, elsewhere the check is passed over', 1 unless $^O eq 'linux';
            my $unlistened = IO::Socket::INET->new(Proto => 'tcp', LocalAddr => '127.0.0.1', LocalPort => 0) or die "socket: $!";
            POSIX::dup2(fileno $unlistened, 3) or die "dup2: $!";
            refuses(qr/inherited fd 3 is not a listening socket/, 'an inherited socket that is not listening', listen_fds => 1, host => '127.0.0.1', port => 0);
        }
        $ENV{LISTEN_FDS} = 1;
        $ENV{LISTEN_PID} = $$;
        SKIP: {
            skip 'http3 is not built in', 1 unless Hyperman->has_http3;
            refuses(qr/an inherited listener cannot carry http3/, 'inherit with http3', listen => [ { port => 0, inherit => 1, http3 => 1, tls_cert => "$dir/bad.pem", tls_key => "$dir/bad.pem" } ]);
        }
        POSIX::close(3);
    }
}

# --- the loop ---
eval { Hyperman::Loop->new(undef, 'lonely') };
like($@, qr/odd number of options/, 'a loop with an odd option list');
eval { Hyperman::Loop->new(undef, zzz => 1) };
like($@, qr/unknown option 'zzz'/, 'a loop with an unknown option');
my $loop = Hyperman::Loop->new(undef, completion => 1);
isa_ok($loop, 'Hyperman::Loop', 'completion asked for on any backend');
eval { $loop->run_until('not a future') };
like($@, qr/run_until: not a Hyperman::Future/, 'run_until wants a future');

# --- futures ---
{
    my $f = Hyperman::Future->new;
    my $g = $f->new;
    isa_ok($g, 'Hyperman::Future', 'new on an instance');
    my $failed = Hyperman::Future->fail_future;
    is(($failed->_values)[0], "Failed\n", 'fail with no message says Failed');
    my $h = Hyperman::Future->new;
    $h->fail;
    is(($h->_values)[0], "Failed\n", 'and so does failing a pending future');
    eval { $h->get };
    like($@, qr/^Failed/, 'get on it dies with the message');
    my $done = Hyperman::Future->done_future(1, 2);
    is_deeply([ $done->_values ], [1, 2], '_values lists the result');
    is($done->await, $done, 'await on a ready future returns it');
    eval { $done->transform('lonely') };
    like($@, qr/transform: odd number/, 'transform with an odd list');
    eval { $done->transform(zzz => sub { }) };
    like($@, qr/transform: unknown argument 'zzz'/, 'transform with an unknown key');
    my $t = $done->transform(done => sub { map { $_ * 2 } @_ });
    is_deeply([ $t->_values ], [2, 4], 'transform done applies');
    my $derived = Hyperman::Future->new;
    my $upstream = Hyperman::Future->new;
    $derived->_set_upstream($upstream);
    $derived->cancel;
    ok($upstream->is_cancelled, 'cancelling the derived future cancels its upstream');
}

# --- writers of shapes that own nothing ---
{
    my $pair = bless [ -1, 0 ], 'Hyperman::Writer';
    ok($pair->write('x') < 0, 'a connection pair with no loop cannot write');
    is($pair->abort, Hyperman::Writer->can('abort') ? $pair->abort : 0, 'abort on a pair is a no-op');
    my $handle = bless [ 0, 0, 0 ], 'Hyperman::Writer';
    ok($handle->write('x') < 0, 'a freed stream handle cannot write');
    is($handle->abort, $handle->abort, 'and abort twice says the same');
    undef $handle;
    pass('a freed stream handle is destroyed quietly');
    my $h1 = bless [ -1, 0, 0, 'h1' ], 'Hyperman::Writer';
    ok($h1->write('x') < 0, 'an HTTP/1 triple with no loop cannot write');
    undef $h1;
    pass('and is destroyed quietly');
}

SKIP: {
    skip 'zlib is not built in', 2 unless Hyperman->can('has_zlib') ? Hyperman->has_zlib : defined Hyperman::_gzip('x' x 100);
    ok(!defined Hyperman::_gzip(undef), 'nothing to gzip');
    ok(!defined Hyperman::_gzip('x'), 'a byte that would not shrink');
}

# --- a log handle whose dup fails: the descriptor table is full ---
SKIP: {
    skip "fork is not Windows", 2 if $^O eq "MSWin32";
    skip "no /bin/sh to lower the descriptor limit", 2 unless -x "/bin/sh";
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    for my $which (qw(access_log error_log)) {
        my $file = "$dir/dup-$which";
        my $code = "my \@hold; while (open my \$fh, q{<}, q{/dev/null}) { push \@hold, \$fh } "
            . "eval { Hyperman->run(app => sub { [200, [], [q{x}]] }, host => q{127.0.0.1}, port => 0, workers => 1, $which => \\*STDOUT) }; "
            . "print STDOUT qq{err=\$\@}";
        system "/bin/sh", "-c", "ulimit -n 48 && exec $^X -Mblib -MHyperman -e '$code' >$file 2>&1";
        my $got = do { local (@ARGV, $/) = ($file); <> } // "";
        like($got, qr/err=Hyperman->run: dup $which fd: /, "a $which handle that cannot be duplicated is refused");
    }
}

done_testing;
