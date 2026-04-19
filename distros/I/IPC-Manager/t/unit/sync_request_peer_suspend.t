use Test2::V0;

use IPC::Manager::Service::Handle;

local $SIG{ALRM} = sub { die "test timed out after 30s\n" };
alarm 30;

{
    package TestSuspend::SuspendableClient;

    # Mimics a protocol that supports suspend/reconnect.  Tests control
    # peer state via alive / registered flags.  peer_exists stays true
    # until the peer is fully unregistered, mirroring Base::FS.

    sub new {
        my ($class, %args) = @_;
        my $self = {
            suspend_supported => 1,
            alive             => 1,         # pidfile present + pid running
            registered        => 1,         # path/row present
            peer_pid          => 99999,
            %args,
        };
        return bless $self, $class;
    }

    sub suspend_supported       { $_[0]->{suspend_supported} }
    sub peer_exists             { $_[0]->{registered} }
    sub peer_pid                { $_[0]->{alive} ? $_[0]->{peer_pid} : 0 }
    sub pid_is_running          { $_[0]->{alive} ? 1 : 0 }
    sub peer_active             { $_[0]->{alive} ? 1 : 0 }
    sub have_handles_for_select { 0 }
    sub handles_for_select      { () }
    sub get_messages            { () }
    sub send_message            { }
    sub disconnect              { }

    sub suspend_peer    { $_[0]->{alive} = 0 }
    sub unregister_peer { $_[0]->{alive} = 0; $_[0]->{registered} = 0 }
    sub resume_peer_as  { $_[0]->{alive} = 1; $_[0]->{peer_pid} = $_[1] }
}

# await_response has no timeout parameter yet in this commit; we assert the
# "keeps waiting" cases by setting a short local alarm and verifying that
# the ALRM handler's die — not a 'went away' croak — is what terminated
# the call.
sub await_waits {
    my ($h, $id) = @_;

    my $err;
    {
        local $SIG{ALRM} = sub { die "local-wait-alarm\n" };
        alarm 1;
        $err = dies { $h->await_response($id) };
        alarm 30;    # restore outer fail-safe
    }
    return $err;
}

subtest 'suspend_supported: peer suspending does NOT croak — liveness check tolerates a missing pid while the peer is still registered' => sub {
    my $client = TestSuspend::SuspendableClient->new;
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => $client,
        interval     => 0.01,
    );

    my $id = $h->send_request(peer1 => 'hi');

    # Peer suspends (clean): pidfile removed, registration stays.
    $client->suspend_peer;

    my $err = await_waits($h, $id);
    like($err,    qr/local-wait-alarm/, "kept waiting through suspend (interrupted by alarm, not by a croak)");
    unlike($err,  qr/went away/,        "did not croak 'peer went away' during suspend");
};

subtest 'suspend_supported: peer unregistering fully DOES croak' => sub {
    my $client = TestSuspend::SuspendableClient->new;
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => $client,
        interval     => 0.01,
    );

    my $id = $h->send_request(peer1 => 'hi');

    # Peer vanishes from the bus entirely.
    $client->unregister_peer;

    like(
        dies { $h->await_response($id) },
        qr/went away/,
        "croaks when peer is fully unregistered",
    );
};

subtest 'suspend_supported: peer restarts under a new pid — still waitable' => sub {
    my $client = TestSuspend::SuspendableClient->new(peer_pid => 1001);
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => $client,
        interval     => 0.01,
    );

    my $id = $h->send_request(peer1 => 'hi');

    # Old instance dies, new instance reconnects under the same name with
    # a different pid.  Registration never dropped below the service loop's
    # resolution.
    $client->resume_peer_as(2002);

    my $err = await_waits($h, $id);
    like($err,    qr/local-wait-alarm/, "kept waiting across a pid change (interrupted by alarm, not by a croak)");
    unlike($err,  qr/went away/,        "did not croak 'peer went away' across a pid change");
};

alarm 0;
done_testing;
