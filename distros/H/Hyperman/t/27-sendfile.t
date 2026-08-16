#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();

# Streaming response bodies (hm_bsrc): a filehandle body is no longer
# slurped into one SV - it drips from the file (or goes straight to
# sendfile(2)) as the socket drains, stopping exactly at Content-Length.
# Asserted here, against a real server:
#   - memory: serving a 16MB file leaves the worker's RSS bounded
#   - framing: a handle seeked mid-file with an explicit Content-Length
#     sends exactly that window, and the connection stays reusable
#   - pipelining: a request sent behind a streaming response is parked
#     and served once the stream completes
#   - the getline-object fallback streams too, chunk by chunk
#   - a client that disconnects mid-file does not hurt the worker

my $dir = File::Temp::tempdir(CLEANUP => 1);
my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;

# 16MB, every 64KB block tagged with its index so a mis-offset window
# cannot alias to the right bytes
my $big = "$dir/big.bin";
my $data;
{
    my $block = join '', map chr($_ % 256), 0 .. 65535;
    $data = join '', map { pack('N', $_) . substr($block, 4) } 0 .. 255;
    open my $fh, '>', $big or die $!;
    binmode $fh;
    print {$fh} $data;
    close $fh;
}
my $size = length $data;   # 16_777_216

my $gl_expect = join '', map { sprintf '%07d', $_ } 0 .. 42_856;  # ~300KB
my $gl_len    = length $gl_expect;

my $sup = fork;
die "fork: $!" unless defined $sup;
if ($sup == 0) {
    open STDERR, '>', "$dir/stderr.log";
    open STDOUT, '>', '/dev/null';
    require Hyperman;

    package FdBody;   # getline + fileno: lifts to the fd source
    sub new {
        my ($class, $path, $off) = @_;
        open my $fh, '<', $path or die $!;
        binmode $fh;
        seek $fh, $off, 0;
        return bless { fh => $fh }, $class;
    }
    sub getline { my $n = read $_[0]{fh}, my $b, 65536; $n ? $b : undef }
    sub fileno  { CORE::fileno $_[0]{fh} }
    sub close   { CORE::close $_[0]{fh} }

    package GlBody;   # getline only: the chunkwise drip
    sub new { bless { buf => $_[1], off => 0 }, $_[0] }
    sub getline {
        my ($self) = @_;
        return undef if $self->{off} >= length $self->{buf};
        my $c = substr $self->{buf}, $self->{off}, 7000;
        $self->{off} += length $c;
        return $c;
    }
    sub close { }

    package main;
    Hyperman->run(
        app => sub {
            my $env  = shift;
            my $path = $env->{PATH_INFO};
            if ($path eq '/ping') {
                return [ 200, [ 'Content-Type' => 'text/plain' ], ['pong'] ];
            }
            if ($path eq '/rss') {
                my $kb = (split ' ', `ps -o rss= -p $$`)[0] || 0;
                return [ 200, [ 'Content-Type' => 'text/plain' ], [$kb] ];
            }
            if ($path eq '/glob') {          # plain filehandle, no CL header
                open my $fh, '<', $big or die $!;
                binmode $fh;
                return [ 200, [ 'Content-Type' => 'application/octet-stream' ],
                         $fh ];
            }
            if ($path eq '/range') {         # seeked handle + explicit CL
                open my $fh, '<', $big or die $!;
                binmode $fh;
                seek $fh, 1_048_576, 0;
                return [ 206, [ 'Content-Type'   => 'application/octet-stream',
                                'Content-Length' => 100_000 ], $fh ];
            }
            if ($path eq '/obj') {           # fileno object window
                return [ 206, [ 'Content-Type'   => 'application/octet-stream',
                                'Content-Length' => 100_000 ],
                         FdBody->new($big, 2_097_152) ];
            }
            if ($path eq '/gl') {            # getline-only object
                return [ 200, [ 'Content-Type'   => 'text/plain',
                                'Content-Length' => $gl_len ],
                         GlBody->new($gl_expect) ];
            }
            return [ 404, [ 'Content-Type' => 'text/plain' ], ['nope'] ];
        },
        host => '127.0.0.1', port => $port, workers => 1,
    );
    exit 0;
}

use constant BUDGET => 15;

sub connect_srv {
    my $deadline = Time::HiRes::time() + BUDGET;
    while (Time::HiRes::time() < $deadline) {
        my $s = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port,
            Proto => 'tcp', Timeout => 2);
        return $s if $s;
        Time::HiRes::sleep(0.1);
    }
    return undef;
}

# Read one HTTP/1.1 response off $s; returns (status, \%headers, $body).
sub read_response {
    my ($s) = @_;
    my $hdr = '';
    my $deadline = Time::HiRes::time() + BUDGET;
    while ($hdr !~ /\r\n\r\n/) {
        die "timeout reading headers\n" if Time::HiRes::time() > $deadline;
        my $n = sysread $s, $hdr, 65536, length $hdr;
        die "peer closed in headers\n" unless $n;
    }
    my ($head, $rest) = split /\r\n\r\n/, $hdr, 2;
    my ($status) = $head =~ m{^HTTP/1\.\d (\d+)};
    my %h;
    for (split /\r\n/, $head) {
        $h{lc $1} = $2 if /^([^:]+):\s*(.*)$/;
    }
    my $need = $h{'content-length'} // 0;
    my $body = $rest // '';
    while (length($body) < $need) {
        die "timeout reading body\n" if Time::HiRes::time() > $deadline;
        my $n = sysread $s, $body, 1 << 20, length $body;
        die "peer closed mid-body\n" unless $n;
    }
    # anything past $need belongs to the next pipelined response
    my $extra = substr $body, $need;
    $body = substr $body, 0, $need;
    return ($status, \%h, $body, $extra);
}

my $s = connect_srv();
ok $s, 'server came up' or do { kill 'TERM', $sup; server_reap($sup); done_testing; exit };

# ---- the full file, byte for byte -------------------------------------------
$s->print("GET /glob HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body) = read_response($s);
    is $st, 200, 'file serves';
    is $h->{'content-length'}, $size, 'auto Content-Length is the file size';
    ok $body eq $data, 'all 16MB arrive byte-identical';
}

# ---- the worker stayed small ------------------------------------------------
$s->print("GET /rss HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body) = read_response($s);
    is $st, 200, 'rss probe on the same worker';
    my $mb = $body / 1024;
    cmp_ok $mb, '<', 60,
        "worker RSS ${mb}MB stays bounded (a slurp would hold the 16MB)";
}

# ---- a seeked window with explicit Content-Length, then reuse ---------------
$s->print("GET /range HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body) = read_response($s);
    is $st, 206, 'window serves';
    is length $body, 100_000, 'exactly Content-Length bytes';
    ok $body eq substr($data, 1_048_576, 100_000),
        'and they are the right window';
}
$s->print("GET /ping HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body) = read_response($s);
    is $body, 'pong',
        'the connection is still framed after a trimmed file body';
}

# ---- pipelining behind a stream ---------------------------------------------
$s->print("GET /range HTTP/1.1\r\nHost: t\r\n\r\n"
        . "GET /ping HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body, $extra) = read_response($s);
    is $st, 206, 'streamed response first';
    ok $body eq substr($data, 1_048_576, 100_000), 'with the right bytes';
    # the pipelined request was parked and answered after the stream
    my $rest = $extra;
    while ($rest !~ /\r\n\r\npong/) {
        my $n = sysread $s, $rest, 65536, length $rest;
        last unless $n;
    }
    like $rest, qr/HTTP\/1\.1 200 .*\r\n\r\npong/s,
        'the pipelined request is served after the stream completes';
}

# ---- the fileno-object window -----------------------------------------------
$s->print("GET /obj HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body) = read_response($s);
    is $st, 206, 'fileno object serves';
    ok $body eq substr($data, 2_097_152, 100_000),
        'the fd was read at its seeked position for exactly CL bytes';
}

# ---- the getline-only drip --------------------------------------------------
$s->print("GET /gl HTTP/1.1\r\nHost: t\r\n\r\n");
{
    my ($st, $h, $body) = read_response($s);
    is $st, 200, 'getline body serves';
    ok $body eq $gl_expect, 'chunk boundaries left no seams';
}
$s->close;

# ---- a client that walks away mid-file --------------------------------------
{
    my $a = connect_srv();
    $a->print("GET /glob HTTP/1.1\r\nHost: t\r\n\r\n");
    my $got = '';
    while (length($got) < 200_000) {
        my $n = sysread $a, $got, 65536, length $got;
        last unless $n;
    }
    close $a;                                   # mid-stream hangup
    Time::HiRes::sleep(0.2);
    my $b = connect_srv();
    ok $b, 'reconnect after mid-stream abort';
    $b->print("GET /ping HTTP/1.1\r\nHost: t\r\nConnection: close\r\n\r\n");
    my ($st, $h, $body) = read_response($b);
    is $body, 'pong', 'the worker shrugged off the aborted download';
    close $b;
}

kill 'TERM', $sup;
server_reap($sup);
done_testing;
