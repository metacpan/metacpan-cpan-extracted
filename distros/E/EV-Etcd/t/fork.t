#!/usr/bin/env perl
# The fork contract from the CAVEATS POD: a child can use etcd unless the
# parent held a client when it forked; then the child's new() croaks, and
# dropping an inherited client warns without touching the parent's gRPC.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use IO::Socket::INET;
use POSIX ();

BEGIN { eval { require EV }; plan skip_all => 'EV required' if $@ }
use EV;
use EV::Etcd;

my $endpoint = '127.0.0.1:2379';

sub put_ok {
    my ($client) = @_;
    my $ok;
    $client->put("/test_fork_$$", 'v', sub { $ok = !$_[1]; EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    return $ok;
}

# Exit status of $code run in a child; a hang ends in SIGALRM
sub in_child {
    my ($code) = @_;
    my $pid = fork;
    defined $pid or BAIL_OUT("fork failed: $!");
    unless ($pid) {
        alarm 15;
        my $ok = eval { $code->() };
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid $pid, 0;
    return $?;
}

# A fork waits at most 2s for gRPC to finish shutting down, and a child that
# still finds it running refuses it (exit 3). A slow machine may need a few
# forks; macOS keeps gRPC running for good; without the drain on destroy it
# never comes down and every fork is refused
sub fork_after_drop_ok {
    my ($name) = @_;
    for (1 .. 8) {
        my $status = in_child(sub {
            my $c = eval { EV::Etcd->new(endpoints => [$endpoint], timeout => 3) };
            POSIX::_exit(3) if !$c && $@ =~ /was still running when it forked/;
            die $@ unless $c;
            put_ok($c) or warn "child put failed\n";
        });
        return is($status, 0, $name) unless $status == 3 << 8;
        return pass("$name (macOS keeps gRPC running)") if $^O eq 'darwin';
        sleep 1;
    }
    fail("$name: gRPC never finished shutting down");
}

# Probed without EV::Etcd, so the first test runs in a process that never
# started gRPC and a regression there fails instead of skipping
plan skip_all => "etcd not available on $endpoint"
    unless IO::Socket::INET->new(PeerAddr => $endpoint, Timeout => 2);

is(in_child(sub { put_ok(EV::Etcd->new(endpoints => [$endpoint], timeout => 3)) }), 0,
    'child can use etcd when the parent loaded the module but made no client');

{
    my $c = EV::Etcd->new(endpoints => [$endpoint]);
    ok(put_ok($c), 'parent client works before fork');
}
fork_after_drop_ok('child can use etcd when the parent dropped its client before fork');

# Dropping the client must drain its cancelled calls, or gRPC stays alive;
# the alarm turns a hang in that drain into a failure
{
    alarm 30;
    my $c = EV::Etcd->new(endpoints => [$endpoint]);
    my $w = $c->watch("/test_fork_$$/inflight", sub {});
    $c->put("/test_fork_$$/inflight/$_", 'v', sub {}) for 1 .. 20;
}
alarm 0;
fork_after_drop_ok('child can use etcd when the parent dropped a client with calls in flight');

my $client = EV::Etcd->new(endpoints => [$endpoint]);
ok(put_ok($client), 'parent client works');

is(in_child(sub {
    my $c = eval { EV::Etcd->new(endpoints => [$endpoint]) };
    !$c && $@ =~ /forked this one while holding a client/;
}), 0, 'child of a parent holding a client croaks in new()');
ok(put_ok($client), 'parent client still works after that child');

is(in_child(sub {
    !eval { $client->put("/test_fork_$$", 'child', sub {}); 1 }
        && $@ =~ /cannot be used in forked child/;
}), 0, 'child calling a method on an inherited client croaks');

my $watch = $client->watch("/test_fork_$$/w", sub {});
is(in_child(sub {
    !eval { $watch->cancel(sub {}); 1 } && $@ =~ /cannot be used in forked child/;
}), 0, 'child cancelling an inherited watch croaks');
is(in_child(sub {
    undef $client;
    !eval { $watch->cancel(sub {}); 1 } && $@ =~ /cannot be used in forked child/;
}), 0, 'child cancelling an inherited watch after dropping client croaks');
ok(put_ok($client), 'parent client still works after those children');

{
    # Inherited timers must not fire in a child that runs the loop: the lease
    # renewal would write to the parent's keepalive stream, the health check
    # would rotate the parent's channel copy
    my ($lease, $ka_err, $renewals);
    $client->lease_grant(3, sub { $lease = $_[0] && $_[0]{id}; EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($lease, 'lease granted');
    my $ka = $client->lease_keepalive($lease, sub {
        my ($resp, $err) = @_;
        $err ? ($ka_err = $err) : $renewals++;
    });
    my $hc = EV::Etcd->new(endpoints => ["127.0.0.1:1", $endpoint], health_interval => 0.1);
    ok(put_ok($hc) || put_ok($hc), 'health-checked client reaches etcd');
    undef $t;

    # With nothing of its own armed, the child's loop returns at once unless
    # inherited watchers are still armed
    my $status = in_child(sub {
        alarm 3;
        EV::run;
        1;
    });
    is($status, 0, 'inherited clients leave no armed watchers in the child');

    $renewals = 0;
    my $wait = EV::timer(2.5, 0, sub { EV::break });
    EV::run;
    ok($renewals, 'parent keepalive still renews after the child ran');
    is($ka_err, undef, 'parent keepalive stream unharmed');
    ok(put_ok($hc), 'health-checked parent client still works');
    $ka->cancel(sub {});
    $client->lease_revoke($lease, sub { EV::break });
    my $tr = EV::timer(3, 0, sub { EV::break });
    EV::run;
}

{
    my $pid = fork;
    defined $pid or BAIL_OUT("fork failed: $!");
    if ($pid == 0) {
        local $SIG{__WARN__} = sub {};
        undef $client;
        exit 0;
    }
    waitpid $pid, 0;
    is($? & 0x7f, 0, 'child dropping an inherited client did not die from a signal');
    is($? >> 8, 0, 'child dropping an inherited client exited 0');
}
ok(put_ok($client), 'parent client still works after the child dropped it');

$client->delete("/test_fork_$$", { prefix => 1 }, sub { EV::break });
my $td = EV::timer(2, 0, sub { EV::break });
EV::run;

done_testing();
