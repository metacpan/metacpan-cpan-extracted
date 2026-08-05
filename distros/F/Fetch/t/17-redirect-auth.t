#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;

# Security: credential headers (Authorization, Cookie) must NOT survive a
# redirect that crosses origin (different scheme/host/port), but MUST be kept
# on a same-origin redirect. Two servers on different ports = different origin.

sub spawn {
    my ($handler) = @_;
    my $srv = IO::Socket::INET->new(
        LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
    ) or return;
    my $port = $srv->sockport;
    my $pid  = fork;
    return unless defined $pid;
    if (!$pid) {
        $SIG{TERM} = sub { exit 0 };
        while (my $c = $srv->accept) {
            my $l = <$c> // next;
            my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
            my %h;
            while (my $line = <$c>) {
                last if $line eq "\r\n";
                $h{lc $1} = $2 if $line =~ /^([^:]+):\s*(.*?)\r\n$/;
            }
            my ($status, $extra, $out) = $handler->($m, $p, \%h);
            print $c "HTTP/1.1 $status\r\nContent-Type: text/plain\r\n$extra"
                   . "Content-Length: " . length($out) . "\r\nConnection: close\r\n\r\n"
                   . $out;
            close $c;
        }
        exit 0;
    }
    return ($pid, $port, $srv);
}

# Server B (the redirect target): reports the credential headers it received.
my ($pidB, $portB, $srvB) = spawn(sub {
    my ($m, $p, $h) = @_;
    my $out = "auth=" . (defined $h->{authorization} ? $h->{authorization} : '-')
            . ";cookie=" . (defined $h->{cookie} ? $h->{cookie} : '-');
    return ('200 OK', '', $out);
}) or plan skip_all => "cannot set up server B";
my $baseB = "http://127.0.0.1:$portB";

# Server A: /xorigin -> B (cross origin), /sameorigin -> A/land (same origin),
# /land -> report headers.
my ($pidA, $portA, $srvA) = spawn(sub {
    my ($m, $p, $h) = @_;
    return ('302 Found', "Location: $baseB/land\r\n", '') if $p eq '/xorigin';
    return ('302 Found', "Location: /land\r\n",      '') if $p eq '/sameorigin';
    my $out = "auth=" . (defined $h->{authorization} ? $h->{authorization} : '-')
            . ";cookie=" . (defined $h->{cookie} ? $h->{cookie} : '-');
    return ('200 OK', '', $out);
}) or plan skip_all => "cannot set up server A";
my $baseA = "http://127.0.0.1:$portA";

my $ua = Fetch->new;

# same-origin redirect: credentials are preserved
my $same = $ua->get("$baseA/sameorigin",
    headers => { Authorization => 'Bearer TOK', Cookie => 'sid=1' })->get;
like($same->content, qr/auth=Bearer TOK/, 'same-origin redirect keeps Authorization');
like($same->content, qr/cookie=sid=1/,    'same-origin redirect keeps Cookie');

# cross-origin redirect: credentials are stripped
my $cross = $ua->get("$baseA/xorigin",
    headers => { Authorization => 'Bearer TOK', Cookie => 'sid=1' })->get;
like($cross->content, qr/auth=-/,   'cross-origin redirect strips Authorization');
like($cross->content, qr/cookie=-/, 'cross-origin redirect strips Cookie');

kill 'TERM', $pidA, $pidB;
waitpid $pidA, 0;
waitpid $pidB, 0;
done_testing;
