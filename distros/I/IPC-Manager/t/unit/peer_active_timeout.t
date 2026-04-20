use Test2::V0;

use Time::HiRes qw/time/;
use IPC::Manager::Client;

local $SIG{ALRM} = sub { die "test timed out after 30s\n" };
alarm 30;

{
    package TestPeerReady::MockClient;
    use parent -norequire, 'IPC::Manager::Client';

    # Instance-level toggles so tests can flip state mid-call via SIGALRM.
    sub new {
        my ($class, %args) = @_;
        my $self = {
            alive    => 0,
            peer_pid => $$,     # use our own pid so pid_is_running returns 1
            pid      => $$,     # satisfy pid_check in disconnect
            want_peer_change_handles => 0,
            %args,
        };
        return bless $self, $class;
    }

    sub peer_pid                     { $_[0]->{alive} ? $_[0]->{peer_pid} : 0 }
    sub have_handles_for_peer_change { $_[0]->{want_peer_change_handles} }
    sub handles_for_peer_change      { () }
    sub reset_handles_for_peer_change { }
    sub disconnect                   { }
    sub write_stats                  { }
    sub activate_peer                { $_[0]->{alive} = 1 }
}

subtest 'no timeout = one-shot behavior (backward compat)' => sub {
    my $c = TestPeerReady::MockClient->new;
    is($c->peer_active('foo'), 0, "inactive one-shot returns 0");

    $c->activate_peer;
    is($c->peer_active('foo'), 1, "active one-shot returns 1");
};

subtest 'positive timeout: returns immediately when peer is already active' => sub {
    my $c = TestPeerReady::MockClient->new(alive => 1);

    my $start = time;
    my $got = $c->peer_active('foo', 5);
    my $elapsed = time - $start;

    ok($got, "returns truthy when peer is active");
    ok($elapsed < 0.5, "returned quickly (${elapsed}s)");
};

subtest 'positive timeout: returns 0 after timeout when peer never becomes active' => sub {
    my $c = TestPeerReady::MockClient->new;    # inactive

    my $start = time;
    my $got = $c->peer_active('foo', 0.3);
    my $elapsed = time - $start;

    ok(!$got, "returned false after timeout");
    ok($elapsed >= 0.25, "waited close to full timeout (${elapsed}s)");
    ok($elapsed < 3,     "did not wait much past timeout (${elapsed}s)");
};

subtest 'timeout 0 = block forever until peer becomes active' => sub {
    my $c = TestPeerReady::MockClient->new;

    # Arrange for the peer to flip to active via SIGALRM in ~0.4s.
    local $SIG{ALRM} = sub { $c->activate_peer };
    Time::HiRes::alarm(0.4);

    my $start = time;
    my $got = $c->peer_active('foo', 0);
    my $elapsed = time - $start;

    alarm 30;    # restore outer fail-safe

    ok($got, "eventually returned true once the peer became active");
    ok($elapsed >= 0.3, "waited until the peer became active (${elapsed}s)");
    ok($elapsed < 5,    "did not hang past the activation event (${elapsed}s)");
};

subtest 'polling path: uses IO::Select when client has peer-change handles' => sub {
    pipe(my ($rh, $wh)) or die "pipe: $!";

    my $c = TestPeerReady::MockClient->new(
        want_peer_change_handles => 1,
    );

    # Override to return the pipe read end.
    no warnings 'redefine';
    local *TestPeerReady::MockClient::handles_for_peer_change = sub { $rh };

    # Make the read end ready for reading: a write wakes IO::Select up.
    syswrite($wh, "x") or die "syswrite: $!";

    # Peer is already active — this should return right away regardless,
    # but the main point is verifying the IO::Select path does not
    # deadlock or produce errors when have_handles_for_peer_change is
    # true.
    $c->activate_peer;
    my $start = time;
    my $got = $c->peer_active('foo', 2);
    my $elapsed = time - $start;

    ok($got, "peer reported active through the IO::Select path");
    ok($elapsed < 1, "returned promptly (${elapsed}s)");
};

subtest 'Service::Handle::ready($timeout) plumbs through to peer_active' => sub {
    require IPC::Manager::Service::Handle;

    my $c = TestPeerReady::MockClient->new;
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'svc',
        ipcm_info    => 'fake',
        client       => $c,
    );

    is($h->ready, 0, "no timeout = one-shot, returns 0 when peer inactive");

    my $start = time;
    my $got   = $h->ready(0.2);
    my $elapsed = time - $start;
    is($got, 0, "ready(timeout) returns 0 after timeout when peer never comes up");
    ok($elapsed >= 0.15, "waited approximately the timeout (${elapsed}s)");

    $c->activate_peer;
    ok($h->ready, "one-shot returns 1 now that peer is active");
    ok($h->ready(0.2), "ready(timeout) also returns 1 when peer is active");
};

subtest 'Service::Peer::ready($timeout) plumbs through to peer_active' => sub {
    require IPC::Manager::Service::Peer;

    # Service::Peer needs a service object with ->client and ->pid.
    my $c = TestPeerReady::MockClient->new;

    package TestPeerReady::FakeService;
    sub new { my ($c, $cl) = @_; bless { client => $cl, pid => $$ }, $c }
    sub client { $_[0]->{client} }
    sub pid    { $_[0]->{pid} }

    package main;

    my $svc = TestPeerReady::FakeService->new($c);
    my $peer = IPC::Manager::Service::Peer->new(
        name    => 'svc',
        service => $svc,
    );

    is($peer->ready, 0, "no timeout = one-shot, returns 0 when peer inactive");

    my $start = time;
    my $got   = $peer->ready(0.2);
    my $elapsed = time - $start;
    is($got, 0, "ready(timeout) returns 0 after timeout when peer never comes up");
    ok($elapsed >= 0.15, "waited approximately the timeout (${elapsed}s)");

    $c->activate_peer;
    ok($peer->ready,      "one-shot returns 1 now that peer is active");
    ok($peer->ready(0.2), "ready(timeout) also returns 1 when peer is active");
};

done_testing;
