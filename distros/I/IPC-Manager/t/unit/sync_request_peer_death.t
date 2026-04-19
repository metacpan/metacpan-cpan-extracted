use Test2::V0;

use IPC::Manager::Service::Handle;

# Fail-safe: if the fix regresses and await_response hangs, die within
# 30s rather than hanging the harness forever.
local $SIG{ALRM} = sub { die "test timed out after 30s\n" };
alarm 30;

{
    package TestPeerDeath::MockClient;

    sub new {
        my ($class, %args) = @_;
        my $self = {
            alive    => 1,
            peer_pid => 99999,
            %args,
        };
        return bless $self, $class;
    }

    sub suspend_supported       { 0 }
    sub peer_exists             { $_[0]->{alive} ? 1 : 0 }
    sub peer_pid                { $_[0]->{peer_pid} }
    sub pid_is_running          { $_[0]->{alive} ? 1 : 0 }
    sub peer_active             { $_[0]->{alive} ? 1 : 0 }
    sub have_handles_for_select { 0 }
    sub handles_for_select      { () }
    sub get_messages            { () }
    sub send_message            { }
    sub disconnect              { }

    sub die_now { $_[0]->{alive} = 0 }
}

subtest 'await_response croaks when peer dies' => sub {
    my $client = TestPeerDeath::MockClient->new;

    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => $client,
        interval     => 0.01,
    );

    my $id = $h->send_request(peer1 => 'hello');

    # Simulate the peer dying mid-request
    $client->die_now;

    like(
        dies { $h->await_response($id) },
        qr/went away/,
        "await_response croaks when peer dies",
    );
};

subtest 'await_response croaks when peer had no pid at send time (unknown peer)' => sub {
    my $client = TestPeerDeath::MockClient->new(peer_pid => undef);

    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => $client,
        interval     => 0.01,
    );

    my $id = $h->send_request(nonexistent => 'hello');
    $client->die_now;

    like(
        dies { $h->await_response($id) },
        qr/went away/,
        "await_response croaks when no pid was captured and peer_active is false",
    );
};

alarm 0;
done_testing;
