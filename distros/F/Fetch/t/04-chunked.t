#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# Server that replies with a chunked body (and, for one path, an
# until-close body with no Content-Length).
my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    # Never hold the harness TAP pipe open, and never outlive the run:
    # a leaked server child hangs the whole suite after this test is done.
    open STDOUT, ">", File::Spec->devnull();
    open STDERR, ">", File::Spec->devnull();
    alarm 120;
    $SIG{TERM} = sub { exit 0 };
    while (my $c = $srv->accept) {
        my $path;
        my $l = <$c>; ($path) = $l =~ m{^\S+\s+(\S+)};
        while (my $h = <$c>) { last if $h eq "\r\n" }
        if ($path eq '/close') {
            # no Content-Length, no chunked: body terminated by close
            print $c "HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n";
            print $c "body-until-close";
        }
        else {
            print $c "HTTP/1.1 200 OK\r\n"
                   . "Transfer-Encoding: chunked\r\nConnection: close\r\n\r\n";
            # "Wikipedia in chunks" split across chunks; sizes in hex
            print $c "4\r\nWiki\r\n";        # 4
            print $c "5\r\npedia\r\n";       # 5
            print $c "a\r\n in chunks\r\n";  # 10 (0xa)
            print $c "0\r\n\r\n";            # last chunk
        }
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.2);

my $ua   = Fetch->new;
my $base = "http://127.0.0.1:$port";

plan tests => 4;

{
    my $res = $ua->get("$base/chunked")->get;
    is($res->status, 200, 'chunked response status 200');
    is($res->content, 'Wikipedia in chunks', 'chunked body decoded correctly');
}

# split across many tiny chunks reassembles
{
    my $res = $ua->get("$base/chunked2")->get;
    is(length($res->content), 19, 'decoded length is the sum of chunk sizes');
}

# body with neither Content-Length nor chunked ends at connection close
{
    my $res = $ua->get("$base/close")->get;
    is($res->content, 'body-until-close', 'until-close body captured');
}

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
