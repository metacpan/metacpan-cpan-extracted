# A long-idle async worker / client should not be torn down by the
# OS while waiting for a slow job. Exercises TCP keepalive path —
# without it, NATs / load balancers can drop idle connections.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

# Quick smoke: keepalive option flips socket options without croaking
# and survives a short idle round-trip. We can't actually verify the
# kernel sent KEEPIDLE probes without packet capture; this is a
# regression test for the option-plumbing path.
my $cli = EV::Gearman->new(
    host => $host, port => $port, keepalive => 30,
);
my $wkr = EV::Gearman->new(
    host => $host, port => $port, keepalive => 30,
);
my $func = "ka_$$";

my @timers;   # retain the timer watchers across the callback return
$wkr->register_function($func => { async => 1 }, sub {
    my $job = shift;
    push @timers, EV::timer 1.0, 0, sub { $job->complete("kept-alive") };
});
$wkr->work;

is $cli->keepalive, 30, 'client keepalive set';
is $wkr->keepalive, 30, 'worker keepalive set';

my ($r, $e);
$cli->submit_job($func, "go", sub { ($r, $e) = @_; EV::break });
my $g = EV::timer 5, 0, sub { fail "ka timeout"; EV::break };
EV::run;

is $r, 'kept-alive', 'job completed under keepalive';
is $e, undef,        'no error';

# Setter at runtime
$cli->keepalive(60);
is $cli->keepalive, 60, 'keepalive runtime setter takes effect';
$cli->keepalive(0);
is $cli->keepalive, 0, 'keepalive can be cleared';

done_testing;
