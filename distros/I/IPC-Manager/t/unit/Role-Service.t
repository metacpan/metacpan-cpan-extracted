use Test2::V0;
use Test2::IPC;

use POSIX();
use Time::HiRes qw/sleep/;

use IPC::Manager::Client::LocalMemory;
use IPC::Manager::Serializer::JSON;

my $SERIALIZER = 'IPC::Manager::Serializer::JSON';
my $PROTOCOL   = 'IPC::Manager::Client::LocalMemory';

# Create a minimal class that consumes the role
{
    package TestRoleService::Impl;
    use Object::HashBase qw{
        <name <orig_io <ipcm_info <watch_pids
        <redirect
    };
    use Role::Tiny::With;

    sub pid     { $_[0]->{pid} }
    sub set_pid { $_[0]->{pid} = $_[1] }

    sub handle_request {
        my ($self, $req, $msg) = @_;
        return "echo: $req->{request}";
    }

    with 'IPC::Manager::Role::Service';
}

subtest 'terminated / is_terminated / terminate' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    ok(!$svc->is_terminated, "not terminated initially");
    is($svc->terminated, undef, "terminated returns undef");

    $svc->terminate(42);
    ok($svc->is_terminated, "is_terminated after terminate");
    is($svc->terminated, 42, "terminated value");

    # Calling terminate again does not overwrite
    $svc->terminate(99);
    is($svc->terminated, 42, "terminate does not overwrite");
};

subtest 'peer_class and handle_class' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    is($svc->peer_class, 'IPC::Manager::Service::Peer', "peer_class");
    is($svc->handle_class, 'IPC::Manager::Service::Handle', "handle_class");
};

subtest 'defaults' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    is($svc->cycle, 0.2, "cycle default");
    is($svc->interval, 0.2, "interval default");
    is($svc->use_posix_exit, 0, "use_posix_exit default");
    is($svc->intercept_errors, 0, "intercept_errors default");
};

subtest 'clear_service_fields' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    $svc->{_TERMINATED} = 1;
    $svc->{_WORKERS} = {123 => 'foo'};
    $svc->clear_service_fields;
    ok(!exists $svc->{_TERMINATED}, "terminated cleared");
    ok(!exists $svc->{_WORKERS}, "workers cleared");
};

subtest 'register_worker and workers' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    $svc->register_worker('w1', 12345);
    is($svc->workers, {12345 => 'w1'}, "worker registered");
};

subtest 'reap_children returns non-worker pids and leaves $? untouched' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);

    my $pid = fork // die "fork: $!";
    if (!$pid) {
        POSIX::_exit(7);
    }

    my $before = 'sentinel';
    $? = 42;

    my $reaped;
    my $waited = 0;
    while ($waited < 5) {
        $reaped = $svc->reap_children;
        last if $reaped && exists $reaped->{$pid};
        sleep 0.05;
        $waited += 0.05;
    }

    is($?, 42, 'reap_children did not leak $?');

    ok($reaped && exists $reaped->{$pid}, "child pid $pid reaped into pids hash");
    is($reaped->{$pid} >> 8, 7, "reaped child exit code is 7");
};

subtest 'reap_children silently reaps registered workers' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);

    my $pid = fork // die "fork: $!";
    if (!$pid) {
        POSIX::_exit(0);
    }

    $svc->register_worker(w1 => $pid);

    my $reaped;
    my $waited = 0;
    while ($waited < 5) {
        $reaped = $svc->reap_children;
        last unless $svc->workers->{$pid};
        sleep 0.05;
        $waited += 0.05;
    }

    ok(!exists $svc->workers->{$pid}, "worker removed from workers hash after reap_children");
    ok(!exists $reaped->{$pid}, "worker pid not present in reap_children result");
};

subtest 'reap_children returns hashref when called with no children' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    my $reaped = $svc->reap_children;
    is(ref($reaped), 'HASH', "reap_children returns a hashref");
};

subtest 'try without intercept_errors' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    my $res = $svc->try(sub { 'hello' });
    is($res, {ok => 1, err => '', out => 'hello'}, "try returns ok result");
};

subtest 'try without intercept_errors propagates exceptions' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    like(
        dies { $svc->try(sub { die "boom\n" }) },
        qr/boom/,
        "exception propagated when intercept_errors is off",
    );
};

subtest 'in_correct_pid' => sub {
    my $svc = TestRoleService::Impl->new(name => 'x', ipcm_info => 'f', pid => $$);
    ok(lives { $svc->in_correct_pid }, "in correct pid");

    $svc->set_pid($$ + 99999);
    like(dies { $svc->in_correct_pid }, qr/Incorrect PID/, "wrong pid detected");
};

subtest 'peer_delta' => sub {
    my $route = $PROTOCOL->spawn();
    my $info = $SERIALIZER->serialize([$PROTOCOL, $SERIALIZER, $route]);
    my $svc = TestRoleService::Impl->new(name => 'svc1', ipcm_info => $info, pid => $$);

    my $delta1 = $svc->peer_delta;

    my $con = $PROTOCOL->connect('peer1', $SERIALIZER, $route);

    my $delta2 = $svc->peer_delta;
    ok($delta2, "delta detected after peer connect");
    is($delta2->{peer1}, 1, "peer1 is new");

    $con->disconnect;
    $svc->client->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'debug output' => sub {
    my $output = '';
    open(my $fh, '>', \$output) or die "open: $!";
    my $svc = TestRoleService::Impl->new(
        name     => 'dbg',
        ipcm_info => 'f',
        pid      => $$,
        orig_io  => {stderr => $fh},
    );

    $svc->debug("test message");
    like($output, qr/test message/, "debug writes to stderr");
};

subtest 'debug without orig_io writes to STDERR' => sub {
    my $svc = TestRoleService::Impl->new(name => 'dbg2', ipcm_info => 'f', pid => $$);
    ok(lives { $svc->debug("") }, "debug works without orig_io");
};

subtest 'send_response' => sub {
    my $route = $PROTOCOL->spawn();
    my $info = $SERIALIZER->serialize([$PROTOCOL, $SERIALIZER, $route]);

    my $svc = TestRoleService::Impl->new(name => 'sr_svc', ipcm_info => $info, pid => $$);
    my $con = $PROTOCOL->connect('sr_client', $SERIALIZER, $route);

    $svc->send_response('sr_client', 'req-123', 'the-answer');

    my @msgs = $con->get_messages;
    is(scalar @msgs, 1, "one response message");
    is($msgs[0]->content->{ipcm_response_id}, 'req-123', "response id");
    is($msgs[0]->content->{response}, 'the-answer', "response content");

    $con->disconnect;
    $svc->client->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'run_on_request_message' => sub {
    my $route = $PROTOCOL->spawn();
    my $info = $SERIALIZER->serialize([$PROTOCOL, $SERIALIZER, $route]);

    my $svc = TestRoleService::Impl->new(name => 'rr_svc', ipcm_info => $info, pid => $$);
    $svc->client;
    my $con = $PROTOCOL->connect('rr_client', $SERIALIZER, $route);

    $con->send_message(rr_svc => {ipcm_request_id => 'test-req-1', request => 'ping'});

    my @svc_msgs = $svc->client->get_messages;
    is(scalar @svc_msgs, 1, "service got one message");

    $svc->run_on_request_message($svc_msgs[0]);

    my @resp_msgs = $con->get_messages;
    is(scalar @resp_msgs, 1, "client got response");
    is($resp_msgs[0]->content->{response}, 'echo: ping', "correct response");

    $con->disconnect;
    $svc->client->disconnect;
    $PROTOCOL->unspawn($route);
};

subtest 'handle via role' => sub {
    my $route = $PROTOCOL->spawn();
    my $info = $SERIALIZER->serialize([$PROTOCOL, $SERIALIZER, $route]);

    my $svc = TestRoleService::Impl->new(name => 'h_svc', ipcm_info => $info, pid => $$);

    my $handle = $svc->handle(name => 'h_client');
    isa_ok($handle, ['IPC::Manager::Service::Handle']);
    is($handle->service_name, 'h_svc', "handle service_name");

    $svc->client->disconnect;
    $PROTOCOL->unspawn($route);
};

done_testing;
