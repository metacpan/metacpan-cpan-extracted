#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Time::HiRes ();
use Test::More;
use Fetch;

# The per-request deadline again, but running on a Hyperman::Loop. That loop's
# adapter does not arm one kernel timer per request; it keeps deadlines in a
# list swept by a single coarse repeating timer. So this exercises a different
# code path from t/09: a stalled request must still time out (the sweep fires
# it), and a prompt one must still succeed with its deadline cancelled cleanly
# (leaving nothing for the sweep to fire, and the sweep stopping when idle).

plan skip_all => 'Hyperman not installed'
    unless eval { require Hyperman; require Hyperman::Loop; 1 };

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
) or plan skip_all => "cannot listen: $!";
my $port = $srv->sockport;
my $base = "http://127.0.0.1:$port";

my $pid = fork;
plan skip_all => "cannot fork: $!" unless defined $pid;
if (!$pid) {
    $SIG{TERM} = sub { exit 0 };
    my @hold;                       # keep slow sockets open, unanswered
    while (my $c = $srv->accept) {
        my $l = <$c>;
        my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
        if ($p =~ m{^/fast}) {
            while (my $h = <$c>) { last if $h eq "\r\n" }
            my $b = "quick";
            print $c "HTTP/1.1 200 OK\r\nContent-Length: " . length($b)
                   . "\r\nConnection: close\r\n\r\n$b";
            close $c;
        } else {
            push @hold, $c;         # never answer
        }
    }
    exit 0;
}
select(undef, undef, undef, 0.2);

plan tests => 4;

my $ua = Fetch->new(loop => Hyperman::Loop->new);

# ---- a stalled request fails with a timeout (the sweep fires it) ----------
{
    my $t0 = Time::HiRes::time();
    my $f  = $ua->get("$base/slow", timeout => 0.3);
    eval { $f->get };
    my $elapsed = Time::HiRes::time() - $t0;

    ok($f->is_failed, 'stalled request fails on the Hyperman loop');
    like($f->failure, qr/timed out/, 'failure says it timed out');
    cmp_ok($elapsed, '>=', 0.25, 'waited about the timeout, not forever');
}

# ---- a prompt request beats a generous timeout (deadline cancels cleanly) --
{
    my $res = $ua->get("$base/fast", timeout => 5)->get;
    is($res->content, 'quick', 'fast request succeeds with a timeout set');
}

END { local $?; if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }
