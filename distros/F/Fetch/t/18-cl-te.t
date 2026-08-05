#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;

# RFC 7230 3.3.3: a response carrying both Content-Length and Transfer-Encoding:
# chunked must be framed by the chunked encoding (TE overrides CL), and the
# lingering Content-Length must not truncate the body or desync a keep-alive
# connection into a response-smuggling situation.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    # Serve two requests on ONE keep-alive connection. The first response has a
    # deliberately-wrong Content-Length: 3 alongside a 12-byte chunked body.
    my $c = $srv->accept or exit 0;
    my $n = 0;
    while (1) {
        defined(my $l = <$c>) or last;
        while (my $line = <$c>) { last if $line eq "\r\n" }
        $n++;
        if ($n == 1) {
            # CL says 3 bytes; chunked body is "HELLO"+"WORLD!!" = 12 bytes
            print $c "HTTP/1.1 200 OK\r\n"
                   . "Content-Type: text/plain\r\n"
                   . "Content-Length: 3\r\n"
                   . "Transfer-Encoding: chunked\r\n\r\n"
                   . "5\r\nHELLO\r\n7\r\nWORLD!!\r\n0\r\n\r\n";
        } else {
            my $b = "second";
            print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                   . "Content-Length: " . length($b) . "\r\n\r\n" . $b;
            last;
        }
    }
    close $c;
    exit 0;
}

my $ua  = Fetch->new(keep_alive => 1);
my $r1  = $ua->get("$base/one")->get;
is($r1->content, 'HELLOWORLD!!',
   'CL+TE: full chunked body decoded, not truncated at Content-Length');

# If the first response had desynced (leftover chunk bytes attributed to the
# next response), this second request on the same keep-alive conn would be
# mis-parsed. It must come back clean.
my $r2 = $ua->get("$base/two")->get;
is($r2->content, 'second', 'keep-alive after CL+TE response is not desynced');

kill 'TERM', $pid;
waitpid $pid, 0;
done_testing;
