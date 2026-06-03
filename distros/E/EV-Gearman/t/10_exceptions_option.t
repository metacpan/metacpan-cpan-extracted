# `exceptions => 1` enables WORK_EXCEPTION delivery: when a sync worker
# dies, the client gets on_exception($msg) BEFORE the terminal
# WORK_FAIL.
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

my $cli = EV::Gearman->new(host => $host, port => $port, exceptions => 1);
my $wkr = EV::Gearman->new(host => $host, port => $port, exceptions => 1);

my $func = "exc_test_$$";
$wkr->register_function($func => sub { die "intentional: ".$_[0]->workload."\n" });
$wkr->work;

my @events;
my ($r, $e);
$cli->submit_job($func, "boom-payload", {
    on_exception => sub { push @events, ['exception', $_[0]] },
}, sub {
    ($r, $e) = @_;
    push @events, ['terminal', $r, $e];
    EV::break;
});

my $g = EV::timer 5, 0, sub { fail "timeout"; EV::break };
EV::run;

ok defined($e), 'terminal callback got an error';
is $r, undef, 'no result on fail';
is $e, 'exception', 'error string distinguishes exception from plain "job failed"';

is scalar @events, 2, 'two events delivered (exception + terminal)';
is $events[0][0], 'exception', 'on_exception fired first';
like $events[0][1], qr/intentional: boom-payload/,
    'exception body carries the die message';
is $events[1][0], 'terminal', 'terminal callback fired second';

done_testing;
