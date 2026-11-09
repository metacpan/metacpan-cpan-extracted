#!perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use HMTest qw(free_ports quiet_child server_reap);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();
use Hyperman;

# HTTP/2 edges: a file body lifted onto the stream and an object body
# slurped, hop-by-hop headers dropped, a header the library refuses, the
# responder's three-element form and a second call, handlers that die before
# and after producing, a response of the wrong shape, foreign and failed
# futures, a stream reset while its future is pending, a response past the
# write mark, a stream opened after parking, the upgrade's settings with
# whitespace and with a bad length, and raw frames: a preface in two writes,
# a Host beside :authority, trailers, a header block past the ceiling, and a
# GOAWAY from the client.

plan skip_all => 'HTTP/2 support not built' unless Hyperman->has_http2;
plan skip_all => 'fork is not Windows' if $^O eq 'MSWin32';
my $curl;
for my $c ('/opt/homebrew/opt/curl/bin/curl', '/usr/local/opt/curl/bin/curl', split /\n/, `which -a curl 2>/dev/null` || '') {
    next unless $c && -x $c;
    next unless (`$c --version 2>/dev/null` || '') =~ /^Features:.*\bHTTP2\b/m;
    $curl = $c;
    last;
}
plan skip_all => 'no HTTP/2-capable curl' unless $curl;

my ($pa, $pb) = free_ports(2);
plan skip_all => 'no free loopback ports' unless $pa && $pb;
my $dir = File::Temp::tempdir(CLEANUP => 1);
sub slurp { my $f = shift; -f $f ? do { local (@ARGV, $/) = ($f); <> } // '' : '' }
sub wait_for { my ($file, $re) = @_; for (1 .. 50) { my $t = slurp($file); return $t if $t =~ $re; Time::HiRes::sleep(0.1) } return slurp($file) }

package Duck;
sub new { my ($class, %o) = @_; bless { %o }, $class }
sub on_ready { my ($self, $cb) = @_; $cb->($self); $self }
sub is_ready { 1 }
sub is_done { 1 }
sub is_failed { 0 }
sub is_cancelled { 0 }
sub get { my $self = shift; die "duck get dies\n" if $self->{dies}; $self->{value} }
sub failure { () }
sub cancel { $_[0] }
package Getliner;
sub new { my ($class, $s) = @_; bless { s => $s, done => 0 }, $class }
sub getline { my $self = shift; return undef if $self->{done}++; $self->{s} }
sub read { my $self = shift; return 0 if $self->{done}++; $_[0] = $self->{s}; length $self->{s} }
sub close { 1 }
package main;

my $note = "$dir/note";
my $keep;
open my $ffh, '>', "$dir/file.bin" or die; print $ffh 'f' x 65536; close $ffh;
my $app = sub {
    my $env = shift;
    my $p = $env->{PATH_INFO};
    my $ok = sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ @_ ] ] };
    if ($p eq '/detach') { my $err = eval { Hyperman::detach($env); 'none' } // $@; return $ok->($err) }
    if ($p eq '/file') { open my $fh, '<', "$dir/file.bin" or die; return [ 200, [ 'Content-Length' => 65536 ], $fh ] }
    if ($p eq '/obj') { return [ 200, [ 'Content-Type' => 'text/plain' ], Getliner->new('from-getline') ] }
    if ($p eq '/hop') { return [ 200, [ 'Keep-Alive' => 'timeout=5', 'Proxy-Connection' => 'close', 'Transfer-Encoding' => 'chunked', 'Upgrade' => 'x', 'TE' => 'trailers', 'Connection' => 'close', 'X-Kept' => 'yes' ], ['hop'] ] }
    if ($p eq '/badhdr') { return [ 200, [ 'bad name' => 'x' ], ['bad'] ] }
    if ($p eq '/resp3') { return sub { $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ], ['three'] ]) } }
    if ($p eq '/resp_twice') {
        return sub {
            my $r = shift;
            my $w = $r->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
            my $err = eval { $r->([ 200, [], ['again'] ]); 'none' } // $@;
            open my $fh, '>', $note or die; print $fh $err; close $fh;
            $w->write('once'); $w->close;
        };
    }
    if ($p eq '/die_producing') { return sub { my $w = Hyperman::stream($env, 200, [ 'Content-Type' => 'text/plain' ]); $w->write('x'); $keep = $w; die "producing boom\n" } }
    if ($p eq '/die_early') { return sub { die "early boom\n" } }
    if ($p eq '/junk') { return { not => 'a response' } }
    if ($p eq '/duck') { return Duck->new(value => $ok->('duck')) }
    if ($p eq '/duck_dies') { return Duck->new(dies => 1) }
    if ($p eq '/fail') { return Hyperman::Future->fail_future("async nope\n") }
    if ($p eq '/badval') { return Hyperman::Future->done_future('not a response') }
    if ($p eq '/slow') { return Hyperman->timer(3)->then(sub { $ok->('late') }) }
    if ($p eq '/big') { return $ok->('b' x (4 * 1024 * 1024)) }
    if ($p eq '/stream_sync') {
        Hyperman->timer(0.01)->get;
        my $w = Hyperman::stream($env, 200, [ 'Content-Type' => 'text/plain' ]);
        $w->write('synced'); $w->close;
        return [ 101, [], [] ];
    }
    if ($p eq '/echo') {
        my $body = '';
        $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 1 << 20);
        return $ok->('len=' . length($body));
    }
    if ($p eq '/env') { return $ok->(join '|', map { $_ . '=' . ($env->{$_} // '') } qw(HTTP_HOST psgix.proxy_addr REMOTE_ADDR)) }
    $ok->($p);
};

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child(stderr => "$dir/stderr");
    Hyperman->run(app => $app, host => '127.0.0.1', workers => 1, http2 => 1,
        listen => [ { port => $pa }, { port => $pb, proxy_protocol => 1 } ],
        access_log => "$dir/access.log", access_log_format => '%h %>s %D %{psgix.proxy_addr}e');
    exit 0;
}

sub curl { my ($path, @extra) = @_; my $port = @extra && $extra[0] =~ /^\d+$/ ? shift @extra : $pa; my $out = `$curl -s --http2-prior-knowledge @extra "http://127.0.0.1:$port$path" 2>&1`; return $out // '' }
sub up {
    for (1 .. 60) { my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$pa"); return 1 if $s; Time::HiRes::sleep(0.1) }
    return 0;
}
ok(up(), 'the h2 server is up');
is(curl('/plain'), '/plain', 'a plain request over prior knowledge');
like(curl('/detach'), qr/no psgix\.hyperman\.conn in this env \(HTTP\/2 and HTTP\/3 streams share one connection/, 'a detach on an h2 stream is refused, the env carrying no ticket');
is(length(curl('/file')), 65536, 'a file body is lifted onto the stream and read per window');
is(curl('/obj'), 'from-getline', 'an object body with getline is slurped');
my $hop = curl('/hop', '-i');
like($hop, qr/x-kept: yes/i, 'a response keeps its ordinary headers');
unlike($hop, qr/keep-alive|proxy-connection|transfer-encoding|upgrade:|^te:/im, 'and loses the hop-by-hop ones');
my $bad = curl('/badhdr', '-i', '-w', '%{exitcode}');
unlike($bad, qr/bad name/i, 'a header name the library refuses is not sent');
is(curl('/resp3'), 'three', 'the responder takes a whole response');
is(curl('/resp_twice'), 'once', 'a responder called twice answers once');
like(wait_for($note, qr/\S/), qr/a response has already been started/, 'and the second call croaks');
my $dp = curl('/die_producing', '-w', '%{exitcode}');
like($dp, qr/^x92\z/, 'a handler that dies while producing resets the stream after what it wrote');
like(wait_for("$dir/stderr", qr/producing boom/), qr/producing boom/, 'and its death is logged');
like(curl('/die_early', '-i'), qr/^HTTP\/2 500/, 'a handler that dies before producing is a 500');
like(curl('/junk', '-i'), qr/^HTTP\/2 500/, 'a response of the wrong shape is a 500');
is(curl('/duck'), 'duck', 'a foreign future that is done is asked for its value');
like(curl('/duck_dies', '-i'), qr/^HTTP\/2 500/, 'one whose get dies is a 500');
like(curl('/fail', '-i'), qr/^HTTP\/2 500/, 'a failed future is a 500');
like(wait_for("$dir/stderr", qr/async nope/), qr/async response failed: async nope/, 'and its failure is logged');
like(curl('/badval', '-i'), qr/^HTTP\/2 500/, 'a future done with a non-response is a 500');
my $slow = curl('/slow', '-m', '0.5', '-w', '%{exitcode}');
like($slow, qr/28/, 'a client that gives up on a slow stream resets it');
is(length(curl('/big', '--limit-rate', '4M')), 4 * 1024 * 1024, 'a response past the write mark arrives whole to a slow reader');
is(curl('/stream_sync'), 'synced', 'a stream opened after parking in a plain handler answers');
open my $bfh, '>', "$dir/body.bin" or die; print $bfh 'u' x 100000; close $bfh;
is(curl('/echo', '-X', 'POST', '--data-binary', "\@$dir/body.bin"), 'len=100000', 'a body in several DATA frames is joined');
like(curl('/env', $pb, '--haproxy-protocol'), qr/proxy_addr=127\.0\.0\.1/, 'a PROXY line before the preface names the proxy');

# --- the upgrade dance by hand ---
sub raw {
    my ($port, $bytes, %o) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or return '';
    if ($o{split}) { $s->syswrite(substr $bytes, 0, $o{split}); Time::HiRes::sleep(0.3); $s->syswrite(substr $bytes, $o{split}) }
    else { $s->syswrite($bytes) }
    my $buf = '';
    my $closed = 0;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($o{budget} || 2);
        while (1) { my $n = $s->sysread(my $c, 65536); if (!$n) { $closed = 1; last } $buf .= $c; last if $o{until} && $buf =~ $o{until} }
        alarm 0;
    };
    return wantarray ? ($buf, $closed) : $buf;
}
{
    my $ws = raw($pa, "GET /up HTTP/1.1\r\nHost: a\r\nConnection: Upgrade, HTTP2-Settings\r\nUpgrade: h2c\r\nHTTP2-Settings: AAMA AABk\r\nAAQA AP__\r\n\r\n", until => qr/\/up/);
    like($ws, qr/101 Switching Protocols/, 'HTTP2-Settings with whitespace and a fold still upgrades');
    my ($bad, $closed) = raw($pa, "GET /up HTTP/1.1\r\nHost: a\r\nConnection: Upgrade, HTTP2-Settings\r\nUpgrade: h2c\r\nHTTP2-Settings: AAAA\r\n\r\n", until => qr/\/up/);
    ok($closed && $bad !~ /101/, 'a settings payload of the wrong length closes the connection without switching');
}

# --- raw frames ---
my $frame = sub { my ($type, $flags, $sid, $payload) = @_; substr(pack('N', length $payload), 1) . pack('CCN', $type, $flags, $sid) . $payload };
my $hint = sub { my ($bits, $n) = @_; my $max = (1 << $bits) - 1; return chr($n) if $n < $max; my $o = chr($max); $n -= $max; while ($n >= 128) { $o .= chr(($n & 127) | 128); $n >>= 7 } return $o . chr($n) };
my $lit = sub { my ($n, $v) = @_; "\x00" . $hint->(7, length $n) . $n . $hint->(7, length $v) . $v };
my $preface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n" . $frame->(4, 0, 0, '');
my $req = sub { my ($path, @extra) = @_; join '', $lit->(':method', 'GET'), $lit->(':scheme', 'http'), $lit->(':path', $path), $lit->(':authority', 'a'), @extra };
{
    my $got = raw($pa, $preface . $frame->(1, 0x5, 1, $req->('/split')), split => 10, until => qr/\/split/);
    like($got, qr/\/split/, 'a preface arriving in two reads is still recognised');
    $got = raw($pa, $preface . $frame->(1, 0x5, 1, $req->('/env', $lit->('host', 'b'))), until => qr/HTTP_HOST=/);
    like($got, qr/HTTP_HOST=a\|/, 'a Host beside :authority is ignored');
    $got = raw($pa, $preface . $frame->(1, 0x4, 1, $req->('/echo', $lit->('content-length', '3'))) . $frame->(0, 0, 1, 'abc') . $frame->(1, 0x5, 1, $lit->('x-trailer', 'end')), until => qr/len=/);
    like($got, qr/len=3/, 'trailers after the body are accepted');
    my $huge = $req->('/huge', $lit->('x-big', 'h' x 70000));
    my @blocks = unpack '(a16384)*', $huge;
    my $hdrs = $frame->(1, 0x1, 1, shift @blocks);
    $hdrs .= $frame->(9, ($_ == $#blocks ? 0x4 : 0), 1, $blocks[$_]) for 0 .. $#blocks;
    $got = raw($pa, $preface . $hdrs, until => qr/\/huge/);
    unlike($got, qr/\/huge/, 'a header block past the ceiling is reset');
    my ($bye, $closed) = raw($pa, $preface . $frame->(7, 0, 0, pack('NN', 0, 0)), budget => 3);
    ok($closed, 'a GOAWAY from the client closes the connection');
}

kill 'TERM', $pid;
server_reap($pid);
done_testing;
