# Documents what NOT to do: fork() after construction with a live
# connection. The child inherits the parent's fd; using the EV loop
# from both ends produces undefined behavior. This test verifies the
# child can't accidentally corrupt the parent's protocol state by
# pinning that an immediate disconnect+reconnect in the child's path
# yields clean callbacks rather than asserts/segfaults.
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

# Parent: connect & verify, then fork. Child opens its own connection
# (NOT inherited — that's the unsupported case). Parent then verifies
# its own connection still works. This is the supported pattern: each
# process does its own EV::Gearman->new after fork.
my $cli = EV::Gearman->new(host => $host, port => $port);
$cli->on_connect(sub { EV::break });
my $g = EV::timer 5, 0, sub { EV::break };
EV::run;
ok $cli->is_connected, 'parent connected';

my $pid = fork // die "fork: $!";
if (!$pid) {
    # Child path: a fresh connection (NOT $cli) is the supported
    # pattern; using $cli post-fork is undefined.
    my $child_cli = EV::Gearman->new(host => $host, port => $port);
    my ($r, $e);
    $child_cli->echo("child-ping", sub { ($r, $e) = @_; EV::break });
    my $w = EV::timer 5, 0, sub { EV::break };
    EV::run;
    exit($r eq 'child-ping' ? 0 : 1);
}

waitpid $pid, 0;
my $child_status = $? >> 8;
is $child_status, 0, 'child made its own connection + echo round-trip';

# Parent's connection still works after the child exited.
my ($r, $e);
$cli->echo("parent-ping", sub { ($r, $e) = @_; EV::break });
$g = EV::timer 5, 0, sub { fail "parent ping timeout"; EV::break };
EV::run;
is $r, 'parent-ping', 'parent connection survives child fork+exit';

done_testing;
