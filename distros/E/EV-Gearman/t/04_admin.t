use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
unless ($probe) {
    plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)";
}
close $probe;

sub run_with_timeout {
    my ($t, $why) = @_;
    my $w = EV::timer $t, 0, sub { fail("timeout: $why"); EV::break };
    EV::run;
}

my $g = EV::Gearman->new(host => $host, port => $port);

# version (single-line)
my ($v, $e);
$g->server_version(sub { ($v, $e) = @_; EV::break });
run_with_timeout 3, 'version';
ok defined($v) && length($v) > 0, "version: $v";

# status (multi-line) — lines are tab-separated FUNC TOTAL RUNNING WORKERS
my ($status, $serr);
$g->server_status(sub { ($status, $serr) = @_; EV::break });
run_with_timeout 3, 'status';
ok defined($status), 'got status';

# workers (multi-line)
my ($workers, $werr);
$g->server_workers(sub { ($workers, $werr) = @_; EV::break });
run_with_timeout 3, 'workers';
ok defined($workers), 'got workers';

# raw admin call
my ($raw, $rerr);
$g->admin('version', sub { ($raw, $rerr) = @_; EV::break });
run_with_timeout 3, 'raw version';
ok defined($raw), 'raw version reply';

done_testing;
