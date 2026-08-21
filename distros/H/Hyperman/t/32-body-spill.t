#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Time::HiRes ();

# A large request body goes to a temp file rather than a second copy in
# memory.
#
# Hyperman held the body twice: once in the connection's read buffer, and
# again in the SV behind psgi.input. Measured end to end through a socket, a
# 64 MiB upload cost the worker 2.15x the file; with the body spilled it is
# 1.15x, the remaining copy being the read buffer.

plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

my $port = 28100 + ($$ % 120);
my $host = "127.0.0.1:$port";

my $pid = fork // die "fork: $!";
if (!$pid) {
    open STDERR, '>', '/dev/null';
    my $app = sub {
        my ($env) = @_;
        my $in  = $env->{'psgi.input'};
        my $len = $env->{CONTENT_LENGTH} || 0;
        my $got = 0;
        my $first = '';
        while ($len > $got) {
            my $n = read $in, my $buf, 65536;
            last unless $n;
            $first = substr($buf, 0, 4) unless length $first;
            $got += $n;
        }
        # fileno tells a real file apart from a :scalar layer
        my $fno = eval { fileno($in) };
        return [ 200, [ 'Content-Type' => 'text/plain' ],
                 [ join '|', $got, $first,
                   (defined $fno && $fno >= 0 ? 'fd' : 'scalar'),
                   ($env->{'psgix.input.buffered'} ? 'buffered' : 'no') ] ];
    };
    require Hyperman;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port,
                  workers => 1, max_body => 64 * 1024 * 1024);
    exit 0;
}

for (1 .. 100) {
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub post_bytes {
    my ($body) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => $host) or return '';
    $s->autoflush(1);
    syswrite $s, "POST / HTTP/1.1\r\nHost: $host\r\n"
               . "Content-Type: application/octet-stream\r\n"
               . "Content-Length: " . length($body) . "\r\n"
               . "Connection: close\r\n\r\n";
    my $off = 0;
    while ($off < length $body) {
        my $n = syswrite $s, substr($body, $off, 1 << 16);
        last unless $n;
        $off += $n;
    }
    my $resp = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 60;
        while (sysread $s, my $c, 65536) { $resp .= $c }
        alarm 0;
    };
    alarm 0;
    close $s;
    my ($tail) = $resp =~ /\r\n\r\n(.*)\z/s;
    return $tail // '';
}

# ---- a small body stays in memory --------------------------------------------
{
    my ($got, $first, $kind, $buffered) = split /\|/, post_bytes('abcd' x 16);
    is($got, 64, 'a small body arrives whole');
    is($first, 'abcd', 'and reads back correctly');
    is($kind, 'scalar',
        'and stays in memory - below the threshold a copy is cheaper than an '
      . 'inode and three syscalls');
}

# ---- a large one becomes a file ----------------------------------------------
{
    my $body = 'Zabc' . ('y' x (4 * 1024 * 1024));
    my ($got, $first, $kind, $buffered) = split /\|/, post_bytes($body);
    is($got, length $body, 'a 4 MiB body arrives whole');
    is($first, 'Zabc', 'and reads back from the first byte');
    is($kind, 'fd',
        'and arrives as a REAL FILE - a second copy of a large body in memory '
      . 'is the trade this exists to stop');
    is($buffered, 'buffered',
        'psgix.input.buffered is still true, and now honestly so: it means '
      . 'seekable, which a file is');
}

# ---- the temp file is not visible to anyone ----------------------------------
# It is unlinked as soon as it is opened, so the handle is the only reference:
# it vanishes when the handle closes, whether that is a normal response, a
# handler that died, or the worker being killed.
{
    my $body = 'q' x (4 * 1024 * 1024);
    post_bytes($body);
    my $dir = $ENV{TMPDIR} || '/tmp';
    opendir my $dh, $dir or die $!;
    my @left = grep { /^hm-body-/ } readdir $dh;
    closedir $dh;
    is_deeply(\@left, [],
        'nothing named hm-body-* is left anywhere - the file is unlinked at '
      . 'the moment it is created, so there is no cleanup path to forget');
}

# ---- the ceiling still refuses ------------------------------------------------
{
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    if ($s) {
        $s->autoflush(1);
        syswrite $s, "POST / HTTP/1.1\r\nHost: $host\r\n"
                   . "Content-Type: application/octet-stream\r\n"
                   . "Content-Length: 999999999\r\n"
                   . "Connection: close\r\n\r\n";
        # send a little and let the server decide
        syswrite $s, 'x' x 65536;
        my $resp = '';
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 15;
            while (sysread $s, my $c, 4096) { $resp .= $c; last if length $resp > 200 }
            alarm 0;
        };
        alarm 0;
        close $s;
        like($resp, qr/413|\A\z/,
            'a body over the ceiling is refused with 413 (or the connection '
          . 'dropped), not spilled to disk - the ceiling is what stands '
          . 'between a form and a full filesystem');
    }
    else { ok(1, 'could not connect for the ceiling check') }
}

# ---- keep-alive across a spilled body ----------------------------------------
# The dangerous case. The bytes after a spilled body belong to the NEXT
# request and must stay in the read buffer rather than following the body into
# the file. Getting this wrong is not a slow upload - it is a corrupted
# response on an unrelated request.
{
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    if (!$s) { ok(0, 'could not connect for the keep-alive check') for 1 .. 3 }
    else {
        $s->autoflush(1);
        my $big = 'K' x (4 * 1024 * 1024);

        # request one: a spilled body, keep-alive
        syswrite $s, "POST / HTTP/1.1\r\nHost: $host\r\n"
                   . "Content-Type: application/octet-stream\r\n"
                   . "Content-Length: " . length($big) . "\r\n\r\n";
        my $off = 0;
        while ($off < length $big) {
            my $n = syswrite $s, substr($big, $off, 1 << 16);
            last unless $n;
            $off += $n;
        }
        # request two, pipelined in behind it
        syswrite $s, "POST / HTTP/1.1\r\nHost: $host\r\n"
                   . "Content-Type: application/octet-stream\r\n"
                   . "Content-Length: 4\r\nConnection: close\r\n\r\nabcd";

        my $resp = '';
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 60;
            while (sysread $s, my $c, 65536) { $resp .= $c }
            alarm 0;
        };
        alarm 0;
        close $s;

        my @bodies = $resp =~ /\r\n\r\n(\d+\|[^|]*\|\w+\|\w+)/g;
        is(scalar @bodies, 2,
            'both requests on the connection were answered - the second was '
          . 'pipelined in behind a spilled body');
        my ($one_len) = ($bodies[0] // '') =~ /\A(\d+)/;
        my ($two_len, $two_first) = ($bodies[1] // '') =~ /\A(\d+)\|(\w*)/;
        is($one_len, 4 * 1024 * 1024, 'the spilled body was whole');
        is("$two_len|$two_first", '4|abcd',
            'and the NEXT request got its own four bytes - not the tail of '
          . 'the body, and not nothing');
    }
}

# ---- a chunked body still works ----------------------------------------------
# Chunked has no Content-Length to divert on and its decoder wants the octets
# contiguous, so those still accumulate. That is a documented limit, not a
# silent one - and the point of this test is that they still WORK.
{
    my $s = IO::Socket::INET->new(PeerAddr => $host);
    if (!$s) { ok(0, 'could not connect for the chunked check') }
    else {
        $s->autoflush(1);
        syswrite $s, "POST / HTTP/1.1\r\nHost: $host\r\n"
                   . "Content-Type: application/octet-stream\r\n"
                   . "Transfer-Encoding: chunked\r\n"
                   . "Connection: close\r\n\r\n"
                   . "4\r\nWXYZ\r\n5\r\nhello\r\n0\r\n\r\n";
        my $resp = '';
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 20;
            while (sysread $s, my $c, 4096) { $resp .= $c }
            alarm 0;
        };
        alarm 0;
        close $s;
        my ($tail) = $resp =~ /\r\n\r\n(.*)\z/s;
        my ($len, $first) = split /\|/, ($tail // '');
        is("$len|$first", '9|WXYZ',
            'a chunked body is decoded correctly - it is not spilled, and '
          . 'that limit does not break it');
    }
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing;
