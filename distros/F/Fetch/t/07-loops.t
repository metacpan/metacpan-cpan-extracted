#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;
use File::Spec ();
use Fetch;

# The same request suite under every loop adapter we can load: a single GET, a
# batch of concurrent GETs multiplexed on the one loop, and a bare ->get that
# pumps the loop via install_await. Standalone always runs; the foreign
# adapters run when their loop is installed.

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 32, ReuseAddr => 1,
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
        my $l = <$c>;
        my ($m, $p) = $l =~ m{^(\S+)\s+(\S+)};
        while (my $h = <$c>) { last if $h eq "\r\n" }
        my $b = "loop:$p";
        print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
               . "Content-Length: " . length($b) . "\r\n"
               . "Connection: close\r\n\r\n$b";
        close $c;
    }
    exit 0;
}
select(undef, undef, undef, 0.2);

my $base = "http://127.0.0.1:$port";

# each candidate: a name, a guard that returns a loop arg (or undef to skip)
my @adapters = (
    [ 'Standalone', sub { undef } ],   # the default, always present
    [ 'IO::Async', sub {
        return undef unless eval { require IO::Async::Loop; 1 };
        IO::Async::Loop->new;
    } ],
    [ 'Hyperman', sub {
        return undef unless eval { require Hyperman::Loop; 1 };
        Hyperman::Loop->new;
    } ],
    [ 'AnyEvent', sub {
        return undef unless eval { require AnyEvent; 1 };
        'AnyEvent';
    } ],
);

for my $a (@adapters) {
    my ($name, $make) = @$a;
    my $loop = $make->();
    my $has  = $name eq 'Standalone' ? 1 : defined $loop;

  SKIP: {
        skip "$name not installed", 3 unless $has;

        my $ua = $name eq 'Standalone' ? Fetch->new : Fetch->new(loop => $loop);

        # single GET
        my $res = $ua->get("$base/one")->get;
        is($res->content, 'loop:/one', "$name: single GET");

        # concurrent GETs multiplexed on the one loop
        my @f = map { $ua->get("$base/c$_") } 1 .. 6;
        Fetch::Future->needs_all(@f)->get;
        is_deeply([ map { $_->get->content } @f ],
            [ map { "loop:/c$_" } 1 .. 6 ],
            "$name: six concurrent GETs, uncrossed");

        # a second bare ->get still works (install_await re-pumps)
        is($ua->get("$base/again")->get->content, 'loop:/again',
            "$name: bare ->get pumps the loop again");
    }
}

done_testing;

END { local $?; if ($pid) { kill 'KILL', $pid; waitpid $pid, 0 } }
