#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use Fetch;

# Keep-alive pooling: a persistent server tags every TCP connection with an
# incrementing id and echoes it, so we can see whether requests reuse one
# connection (pooling on) or open a fresh one each time (pooling off). The
# server forks per connection so several may be open at once.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 128, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    $SIG{CHLD} = 'IGNORE';
    my $connid = 0;
    while (my $c = $srv->accept) {
        my $id  = ++$connid;
        my $kid = fork;
        if (defined $kid && $kid == 0) {
            $c->autoflush(1);
            while (my $line = <$c>) {           # one iteration per request
                my $close = 0;
                while (my $h = <$c>) {
                    $close = 1 if $h =~ /^Connection:\s*close/i;
                    last if $h eq "\r\n";
                }
                my $b = "conn$id";
                print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                       . "Content-Length: " . length($b) . "\r\n"
                       . ($close ? "Connection: close\r\n" : "")
                       . "\r\n$b";
                last if $close;
            }
            close $c;
            exit 0;
        }
        close $c;                                # parent keeps accepting
    }
    exit 0;
}
select(undef, undef, undef, 0.3);

plan tests => 5;

# ---- keep-alive on (default): one connection serves every request --------
{
    my $ua  = Fetch->new;
    my @ids = map { $ua->get("$base/")->get->content } 1 .. 8;
    my %seen; $seen{$_}++ for @ids;
    is(scalar(keys %seen), 1, 'keep-alive reuses a single connection for 8 GETs');
    is($ids[0], $ids[-1],   'first and last request landed on the same connection');
}

# ---- keep-alive off: a fresh connection every time -----------------------
{
    my $ua  = Fetch->new(keep_alive => 0);
    my @ids = map { $ua->get("$base/")->get->content } 1 .. 5;
    my %seen; $seen{$_}++ for @ids;
    is(scalar(keys %seen), 5, 'keep_alive => 0 opens a new connection per request');
}

# ---- reuse stays correct: bodies are right and status holds --------------
{
    my $ua = Fetch->new;
    my @res = map { $ua->get("$base/")->get } 1 .. 4;
    ok((!grep { $_->status != 200 } @res), 'every reused request is 200');
    like($res[-1]->content, qr/^conn\d+$/, 'reused connection still returns a body');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
