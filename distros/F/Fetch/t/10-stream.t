#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;

# Streaming: with an on_body sink, body bytes are delivered to the callback as
# they arrive and are not retained in the Response (content is empty). Covered
# for a fixed Content-Length body and a chunked one; the reassembled stream
# must equal what the server sent.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    while (my $c = $srv->accept) {
        my $l = <$c>;
        my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
        while (my $h = <$c>) { last if $h eq "\r\n" }
        if ($p eq '/plain') {
            my $b = 'abcdefghij' x 500;         # 5000 bytes
            print $c "HTTP/1.1 200 OK\r\nContent-Length: " . length($b)
                   . "\r\nConnection: close\r\n\r\n$b";
        } elsif ($p eq '/chunk') {
            print $c "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n"
                   . "Connection: close\r\n\r\n";
            for my $piece (qw(one two three four)) {
                printf $c "%x\r\n%s\r\n", length($piece), $piece;
            }
            print $c "0\r\n\r\n";
        }
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.2);

plan tests => 5;

my $ua = Fetch->new;

# ---- fixed-length body streamed, not buffered ----------------------------
{
    my $seen = '';
    my $res  = $ua->get("$base/plain", on_body => sub { $seen .= $_[0] })->get;
    is(length($seen), 5000,   'on_body received the whole fixed-length body');
    is($res->content, '',     'streamed body is not retained in the Response');
    is($res->status,  200,    'streamed request still reports status');
}

# ---- chunked body streamed, reassembles to the sent bytes ----------------
{
    my @got;
    my $res = $ua->get("$base/chunk", on_body => sub { push @got, $_[0] })->get;
    is(join('', @got), 'onetwothreefour', 'chunked stream reassembles correctly');
    is($res->content,  '',                'chunked streamed body not retained');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
