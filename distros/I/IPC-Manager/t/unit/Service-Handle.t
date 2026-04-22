use Test2::V0;

use IPC::Manager::Service::Handle;

subtest 'init requires service_name and ipcm_info' => sub {
    like(
        dies { IPC::Manager::Service::Handle->new(ipcm_info => 'x') },
        qr/'service_name' is a required/,
        "requires service_name",
    );
    like(
        dies { IPC::Manager::Service::Handle->new(service_name => 'x') },
        qr/'ipcm_info' is a required/,
        "requires ipcm_info",
    );
};

subtest 'basic construction' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );
    is($h->service_name, 'my-svc', "service_name");
    ok($h->name, "name auto-generated");
};

subtest 'custom name' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
        name         => 'custom-handle',
    );
    is($h->name, 'custom-handle', "custom name");
};

subtest 'default interval' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );
    is($h->interval, 0.2, "default interval is 0.2");
};

subtest 'messages returns empty when no buffer' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );
    my @msgs = $h->messages;
    is(scalar @msgs, 0, "no messages");
};

subtest 'messages drains buffer' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );

    # Inject messages directly into the buffer for testing
    require IPC::Manager::Message;
    my $msg = IPC::Manager::Message->new(from => 'a', to => 'b', content => 'hi');
    $h->{buffer} = [$msg];

    my @msgs = $h->messages;
    is(scalar @msgs, 1, "one message");
    is($msgs[0]->content, 'hi', "content");

    # Buffer is now empty
    my @msgs2 = $h->messages;
    is(scalar @msgs2, 0, "buffer drained");
};

subtest 'have_pending_responses initially false' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );
    ok(!$h->have_pending_responses, "no pending responses initially");
};

subtest 'child_pid undef by default' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );
    is($h->child_pid, undef, "child_pid is undef when not spawned via ipcm_service");
};

subtest 'child_pid set via _set_child_pid' => sub {
    my $h = IPC::Manager::Service::Handle->new(
        service_name => 'my-svc',
        ipcm_info    => 'fake_info',
    );
    $h->_set_child_pid(4242);
    is($h->child_pid, 4242, "child_pid reflects value stamped by ipcm_service");
};

done_testing;
