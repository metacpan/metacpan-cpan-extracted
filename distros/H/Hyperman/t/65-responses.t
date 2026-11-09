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

# The shapes of a response the suite had not sent: every precomputed status
# line and one built on the fly, HEAD, bodies that are handles and objects,
# the streaming responder's refusals, percent-decoded paths, the JSON log's
# escaping, the ETag rewrite under compression, a pid file, and a host in
# brackets.

my ($port) = free_ports(1);
plan skip_all => 'no free loopback port' unless $port;
my $dir = File::Temp::tempdir(CLEANUP => 1);
my $log = "$dir/access.log";
my $pidfile = "$dir/server.pid";

package Lines;
sub new { my ($class, @l) = @_; bless { l => [@l], closed => 0 }, $class }
sub getline { shift @{ $_[0]{l} } }
sub close { $_[0]{closed} = 1 }
package Dies;
sub new { bless {}, shift }
sub getline { die "no lines\n" }
package NoClose;
sub new { my ($class, @l) = @_; bless [@l], $class }
sub getline { shift @{ $_[0] } }
package main;

my $pid = fork // die "fork: $!";
if (!$pid) {
    quiet_child();
    Hyperman->run(
        app => sub {
            my $env = shift;
            my $p = $env->{PATH_INFO};
            if ($p =~ m{^/s/(\d+)$}) { return [ $1, [ 'Content-Type' => 'text/plain' ], ['body'] ] }
            if ($p eq '/date') { return [ 200, [ 'Date' => 'Thu, 01 Jan 1970 00:00:00 GMT', 'Connection' => 'close' ], ['dated'] ] }
            if ($p eq '/fh') {
                open my $fh, '<', "$dir/body.txt" or die;
                return [ 200, [], $fh ];
            }
            if ($p eq '/obj')      { return [ 200, [], Lines->new('one', 'two') ] }
            if ($p eq '/objdie')   { return [ 200, [], Dies->new ] }
            if ($p eq '/objnoclose') { return [ 200, [], NoClose->new('solo') ] }
            if ($p eq '/memfh') { my $mem = "in memory\n"; open my $fh, '<', \$mem or die; return [ 200, [], $fh ] }
            if ($p eq '/fh304') { open my $fh, '<', "$dir/body.txt" or die; return [ 304, [], $fh ] }
            if ($p eq '/etag3') { return [ 200, [ 'ETag' => 'plain', 'Content-Type' => 'text/plain' ], [ 'z' x 3000 ] ] }
            if ($p eq '/pct') { return [ 200, [], [ $env->{PATH_INFO} ] ] }
            if ($p =~ m{^/pct/}) { return [ 200, [], [ "[$p]" ] ] }
            if ($p eq '/etag')  { return [ 200, [ 'ETag' => '"abc"', 'Content-Type' => 'text/plain', 'Content-Length' => 3000 ], [ 'x' x 3000 ] ] }
            if ($p eq '/etag2') { return [ 200, [ 'ETag' => 'abc', 'Content-Type' => 'text/plain', 'Content-Encoding' => 'identity' ], [ 'y' x 3000 ] ] }
            if ($p =~ m{^/stream/(\w+)$}) {
                my $kind = $1;
                return sub {
                    my $responder = shift;
                    if ($kind eq 'ok') {
                        my $w = $responder->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
                        $w->write('streamed');
                        $w->close;
                    }
                    elsif ($kind eq 'twice') {
                        my $w = $responder->([ 200, [] ]);
                        $w->write('first');
                        eval { $responder->([ 200, [] ]) };
                        $w->write($@ =~ /already been started/ ? ' twice' : ' no');
                        $w->close;
                    }
                    elsif ($kind eq 'full_after') {
                        my $w = $responder->([ 200, [] ]);
                        $w->write('first');
                        eval { $responder->([ 200, [], ['again'] ]) };
                        $w->write($@ =~ /already been started/ ? ' twice' : ' no');
                        $w->close;
                    }
                    elsif ($kind eq 'date') { my $w = $responder->([ 200, [ 'Date' => 'Thu, 01 Jan 1970 00:00:00 GMT', 'Transfer-Encoding' => 'chunked' ] ]); $w->write("5\r\ndated\r\n0\r\n\r\n"); $w->close }
                    elsif ($kind eq 'nobody') { my $w = $responder->([ 204, [] ]); $w->close }
                    elsif ($kind eq 'crlf') { $responder->([ 200, [ 'X-Bad' => "a\r\nb" ] ]) }
                    elsif ($kind eq 'notref') { $responder->('nope') }
                    elsif ($kind eq 'short') { $responder->([ 200 ]) }
                };
            }
            [ 200, [], ['default'] ];
        },
        host => '[127.0.0.1]', port => $port, workers => 1,
        access_log => $log, access_log_format => 'json',
        compress => 1, compress_min_length => 100,
        pid_file => $pidfile,
    );
    exit 0;
}
open my $bfh, '>', "$dir/body.txt" or die; print $bfh "from a file\n"; close $bfh;

for (1 .. 50) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
    last if $s;
    Time::HiRes::sleep(0.1);
}

sub raw {
    my $req = shift;
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port") or return '';
    $s->syswrite($req);
    my $buf = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 3;
        while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c }
        alarm 0;
    };
    return $buf;
}
sub get {
    my ($path, @hdr) = @_;
    return raw(join("\r\n", "GET $path HTTP/1.1", "Host: a", 'Connection: close', @hdr) . "\r\n\r\n");
}

# --- every status line ---
my %reason = (102 => 'Processing', 103 => 'Early Hints', 201 => 'Created', 204 => 'No Content',
    301 => 'Moved Permanently', 302 => 'Found', 304 => 'Not Modified', 400 => 'Bad Request',
    401 => 'Unauthorized', 403 => 'Forbidden', 404 => 'Not Found', 405 => 'Method Not Allowed',
    426 => 'Upgrade Required', 500 => 'Internal Server Error', 299 => 'OK');
for my $st (sort { $a <=> $b } keys %reason) {
    my $r = get("/s/$st");
    like($r, qr{^HTTP/1\.1 $st \Q$reason{$st}\E\r\n}, "$st carries its reason");
    if ($st < 200 || $st == 204 || $st == 304) {
        unlike($r, qr/body\z/, "and $st carries no body");
    } else {
        like($r, qr/body\z/, "and $st carries the body");
    }
}
my $head = raw("HEAD /s/200 HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
like($head, qr/Content-Length: 4\r\n/, 'HEAD carries the length of the body');
unlike($head, qr/body\z/, 'and not the body');
my $dated = get('/date');
like($dated, qr/Date: Thu, 01 Jan 1970/, 'a Date the app gave is kept');
is(scalar(() = $dated =~ /^Date:/mg), 1, 'and not doubled');
is(scalar(() = $dated =~ /^Connection:/mg), 1, 'nor the Connection header');

# --- bodies that are handles and objects ---
like(get('/fh'), qr/from a file\n\z/, 'a filehandle body is read out');
like(get('/obj'), qr/onetwo\z/, 'an object body is read with getline and closed');
like(get('/objdie'), qr/Content-Length: 0/, 'a getline that dies ends the body');
like(get('/objnoclose'), qr/solo\z/, 'an object without close is read out');

like(get('/memfh'), qr/in memory\n\z/, 'an in-memory handle that cannot be lifted is slurped');
my $head_fh = raw("HEAD /fh HTTP/1.1\r\nHost: a\r\nConnection: close\r\n\r\n");
like($head_fh, qr/Content-Length: 12\r\n/, 'HEAD over a file body announces its length');
unlike($head_fh, qr/from a file/, 'and sends none of it');
unlike(get('/fh304'), qr/from a file/, 'a 304 drops a file body');

# --- percent decoding ---
like(get('/pct/a%20b%2Fc%zz%4'), qr/\[\/pct\/a b\/c%zz%4\]/, 'escapes are decoded and broken ones kept');

# --- the streaming responder ---
my $dated_stream = get('/stream/date');
like($dated_stream, qr/Date: Thu, 01 Jan 1970/, 'a stream keeps the Date it was given');
like($dated_stream, qr/dated/, 'and a Transfer-Encoding of its own ends at close');
like(get('/stream/nobody'), qr{^HTTP/1\.1 204}, 'a 204 stream carries no body');
like(get('/stream/ok'), qr/streamed\z/, 'a stream is written and closed');
like(get('/stream/twice'), qr/first twice\z/, 'a second start on the connection is refused');
like(get('/stream/full_after'), qr/first twice\z/, 'and so is a full response after a start');
like(get('/stream/crlf'), qr{^HTTP/1\.1 500}, 'a header with CR LF is refused');
like(get('/stream/notref'), qr{^HTTP/1\.1 500}, 'a responder argument that is not a list is refused');
like(get('/stream/short'), qr{^HTTP/1\.1 500}, 'and so is a one-element list');

# --- the ETag rewrite under compression ---
my $gz = get('/etag', 'Accept-Encoding: gzip');
like($gz, qr/Content-Encoding: gzip/, 'the long body is compressed');
like($gz, qr/ETag: "abc-gzip"/, 'the quoted ETag gains a -gzip suffix inside the quotes');
unlike($gz, qr/Content-Length: 3000/, 'and the app\'s length is dropped');
my $gz3 = get('/etag3', 'Accept-Encoding: gzip');
like($gz3, qr/ETag: plain-gzip\r/, 'an unquoted ETag gains the suffix bare');
my $gz2 = get('/etag2', 'Accept-Encoding: gzip');
like($gz2, qr/ETag: abc\r/, 'an identity response keeps its ETag, compression declined');
unlike($gz2, qr/identity|gzip/, 'and Content-Encoding: identity is not sent on');

# --- the JSON access log escapes what is not UTF-8 ---
get('/s/200', "User-Agent: caf\xc3\xa9 \x80 tab\there \"q\" back\\slash \xe2\x82\xac \xf0\x9f\x98\x80 \xe0\x80\x80 \xed\xa0\x80 \xf0\x80\x80\x80 \xf4\x90\x80\x80 \xc3");
Time::HiRes::sleep(0.2);
my @lines;
for (1 .. 20) {
    @lines = do { open my $fh, '<', $log or (); <$fh> };
    last if grep { /caf/ } @lines;
    Time::HiRes::sleep(0.1);
}
my ($ua) = grep { /caf/ } @lines;
ok($ua, 'the log line with the agent arrived');
like($ua, qr/caf\xc3\xa9 \\u0080 tab\\u0009here \\"q\\" back\\\\slash \xe2\x82\xac \xf0\x9f\x98\x80 \\u00e0\\u0080\\u0080 \\u00ed\\u00a0\\u0080 \\u00f0\\u0080\\u0080\\u0080 \\u00f4\\u0090\\u0080\\u0080 \\u00c3/, 'UTF-8 of every length passes, overlongs, surrogates, beyond-range and a torn lead byte are escaped');

# --- the pid file ---
my $pidtext = -f $pidfile ? do { open my $fh, '<', $pidfile or die; local $/; <$fh> } : '';
like($pidtext, qr/^\d+\n?\z/, 'the pid file holds a pid');
is($pidtext + 0, $pid, 'the supervisor\'s');

kill 'TERM', $pid;
server_reap($pid);
ok(!-e $pidfile, 'the pid file is removed on shutdown');

done_testing;
