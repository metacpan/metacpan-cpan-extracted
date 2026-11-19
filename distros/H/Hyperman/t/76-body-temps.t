#!perl
use 5.010;
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child server_guard server_status);
use IO::Socket::INET;
use Time::HiRes ();
use POSIX ();

# A request body must not outlive its request.
#
# psgi.input over a small body was built with two mortals: the RV handed to
# the :scalar layer, and the glob name newGVgen makes. Both landed on the
# worker's event-loop frame, which never freed its temps, so every POST kept
# three SVs (the RV, the body copy and the name) until the worker exited.
# Reported against 0.64 and again against 0.70: a worker in a 384 MiB
# container sat at 378.7 MiB a day after the load stopped.
#
# Measured inside the worker, DURING the run, as live SVs before and after a
# run of POSTs. GET is the control: a bodyless request shares one input.

plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';
plan skip_all => 'Devel::Gladiator is needed to count live SVs'
    unless eval { require Devel::Gladiator; 1 };

my ($port) = free_ports(1);
plan skip_all => 'no free port' unless $port;
my $host = "127.0.0.1:$port";

my $pid = server_guard(fork // die "fork: $!");
if (!$pid) {
    quiet_child();
    my $app = sub {
        my ($env) = @_;
        my $body = $env->{PATH_INFO} eq '/count'
            ? scalar @{ Devel::Gladiator::walk_arena() }
            : 'date-diagnostic';
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
    };
    require Hyperman;
    Hyperman->run(app => $app, host => '127.0.0.1', port => $port, workers => 1);
    POSIX::_exit(0);
}

my $sock;
for (1 .. 100) {
    if (my $why = server_status($pid)) { plan skip_all => "server did not start: $why" }
    last if $sock = IO::Socket::INET->new(PeerAddr => $host);
    Time::HiRes::sleep(0.1);
}
plan skip_all => 'server never accepted a connection' unless $sock;
$sock->autoflush(1);

sub request {
    my ($line, $body) = @_;
    my $req = "$line HTTP/1.1\r\nHost: $host\r\n";
    $req .= "Content-Type: application/x-www-form-urlencoded\r\n"
          . 'Content-Length: ' . length($body) . "\r\n" if defined $body;
    print {$sock} $req, "\r\n", $body // '';
    my $head = '';
    while (defined(my $line = <$sock>)) {
        $head .= $line;
        last if $line eq "\r\n";
    }
    my ($len) = $head =~ /^Content-Length:\s*(\d+)/mi;
    return undef unless defined $len;
    my $got;
    read $sock, $got, $len;
    return $got;
}

my $REQUESTS = 2000;

for my $case ([ GET => sub { request('GET /x') } ],
              [ POST => sub { request('POST /x', 'value=date-diagnostic') } ]) {
    my ($name, $send) = @$case;
    $send->() for 1 .. 200;
    my $before = request('GET /count');
    my $ok = grep { ($send->() // '') eq 'date-diagnostic' } 1 .. $REQUESTS;
    my $after = request('GET /count');
    is $ok, $REQUESTS, "$name: $REQUESTS requests answered";
    cmp_ok $after - $before, '<', 50,
        "$name: live SVs do not grow with requests ($before before, $after after)";
}

close $sock;
done_testing;
