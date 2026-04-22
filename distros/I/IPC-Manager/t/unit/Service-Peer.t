use Test2::V0;

use IPC::Manager::Service::Peer;

subtest 'requires name' => sub {
    like(
        dies {
            IPC::Manager::Service::Peer->new(
                service => bless({pid => $$}, 'FakeSvc'),
            )
        },
        qr/'name' is required/,
        "dies without name",
    );
};

subtest 'requires service' => sub {
    like(
        dies { IPC::Manager::Service::Peer->new(name => 'x') },
        qr/'service' is required/,
        "dies without service",
    );
};

subtest 'service must be in current process' => sub {
    my $fake_svc = bless({pid => $$ + 1}, 'FakeSvc');
    no warnings 'once';
    *FakeSvc::pid = sub { $_[0]->{pid} };

    like(
        dies {
            IPC::Manager::Service::Peer->new(
                name    => 'x',
                service => $fake_svc,
            )
        },
        qr/must be the current process/,
        "dies when service pid doesn't match",
    );
};

subtest 'construction weakens service ref' => sub {
    my $fake_svc = bless({pid => $$}, 'FakeSvc2');
    no warnings 'once';
    *FakeSvc2::pid = sub { $_[0]->{pid} };

    my $peer = IPC::Manager::Service::Peer->new(
        name    => 'test-peer',
        service => $fake_svc,
    );

    is($peer->name, 'test-peer', "name");
    ok($peer->service, "service present");

    # Verify weakening
    $fake_svc = undef;
    ok(!$peer->service, "service ref was weakened");
};

subtest 'child_pid undef by default; set via _set_child_pid' => sub {
    my $fake_svc = bless({pid => $$}, 'FakeSvc3');
    no warnings 'once';
    *FakeSvc3::pid = sub { $_[0]->{pid} };

    my $peer = IPC::Manager::Service::Peer->new(
        name    => 'p',
        service => $fake_svc,
    );

    is($peer->child_pid, undef, "child_pid undef by default");
    $peer->_set_child_pid(9999);
    is($peer->child_pid, 9999, "child_pid set via _set_child_pid");
};

done_testing;
