use Test2::V0;

use Time::HiRes qw/time/;
use IPC::Manager::Service::Handle;

# Fail-safe so a regression doesn't hang the harness.
local $SIG{ALRM} = sub { die "test timed out after 30s\n" };
alarm 30;

{
    package TestTimeout::MockClient;

    # Use our own pid so the real kill(0, $pid) in await_response always
    # reports the peer as alive; that isolates these tests to the timeout
    # behavior specifically.
    sub new {
        my ($class, %args) = @_;
        return bless {peer_pid => $$, %args}, $class;
    }

    sub suspend_supported       { 0 }
    sub peer_exists             { 1 }
    sub peer_pid                { $_[0]->{peer_pid} }
    sub pid_is_running          { 1 }
    sub peer_active             { 1 }
    sub have_handles_for_select { 0 }
    sub handles_for_select      { () }
    sub get_messages            { () }
    sub send_message            { }
    sub disconnect              { }
}

subtest 'sync_request with timeout croaks when peer is alive but never responds' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => TestTimeout::MockClient->new,
        interval     => 0.05,
    );

    my $start = time;
    my $err = dies { $h->sync_request(peer1 => 'hello', 0.5) };
    my $elapsed = time - $start;

    like($err, qr/timed out/, "croaks with timeout message");
    ok($elapsed >= 0.4, "waited at least close to the timeout (got ${elapsed}s)");
    ok($elapsed < 5,    "did not wait much past the timeout (got ${elapsed}s)");
};

subtest 'await_response with timeout croaks when peer is alive but never responds' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => TestTimeout::MockClient->new,
        interval     => 0.05,
    );

    my $id = $h->send_request(peer1 => 'hello');
    like(
        dies { $h->await_response($id, 0.3) },
        qr/timed out/,
        "await_response croaks with timeout message",
    );
};

subtest 'sync_request without timeout still blocks (smoke)' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        client       => TestTimeout::MockClient->new,
        interval     => 0.05,
    );

    # Run in an alarm-guarded eval so we can verify it DID block (no timeout
    # was provided) without letting the test itself hang.
    my $err;
    {
        local $SIG{ALRM} = sub { die "local-smoke-alarm\n" };
        alarm 1;
        $err = dies { $h->sync_request(peer1 => 'hello') };
        alarm 30;    # restore the outer fail-safe
    }

    like($err, qr/local-smoke-alarm/, "blocks when no timeout is given");
};

alarm 0;
done_testing;
