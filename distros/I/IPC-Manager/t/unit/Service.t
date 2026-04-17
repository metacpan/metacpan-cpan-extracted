use Test2::V0;

use IPC::Manager::Service;

subtest 'init with on_all' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'test-svc',
        ipcm_info => 'fake_info',
        on_all    => sub { },
    );
    isa_ok($svc, ['IPC::Manager::Service']);
    is($svc->name, 'test-svc', "name");
};

subtest 'init requires handle_request or on_all' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name      => 'bad',
                ipcm_info => 'fake',
            )
        },
        qr/handle_request/,
        "dies without handle_request or on_all",
    );
};

subtest 'init with handle_request' => sub {
    my $svc = IPC::Manager::Service->new(
        name           => 'req-svc',
        ipcm_info      => 'fake',
        handle_request => sub { return 'ok' },
    );
    ok($svc, "constructed with handle_request");
};

subtest 'handle_request must be coderef' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name           => 'bad2',
                ipcm_info      => 'fake',
                handle_request => 'not_a_coderef',
            )
        },
        qr/must be a coderef/,
        "non-coderef handle_request rejected",
    );
};

subtest 'handle_response must be coderef' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name            => 'bad3',
                ipcm_info       => 'fake',
                handle_request  => sub { },
                handle_response => 'not_a_coderef',
            )
        },
        qr/must be a coderef/,
        "non-coderef handle_response rejected",
    );
};

subtest 'on_sig must be hashref' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name      => 'bad4',
                ipcm_info => 'fake',
                on_all    => sub { },
                on_sig    => 'not_a_hash',
            )
        },
        qr/must be a hashref/,
        "non-hashref on_sig rejected",
    );
};

subtest 'on_sig signal handlers must be coderefs' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name      => 'bad5',
                ipcm_info => 'fake',
                on_all    => sub { },
                on_sig    => {HUP => 'not_a_coderef'},
            )
        },
        qr/coderefs/,
        "non-coderef signal handler rejected",
    );
};

subtest 'action callbacks must be coderefs' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name       => 'bad6',
                ipcm_info  => 'fake',
                on_all     => sub { },
                on_cleanup => 'not_a_coderef',
            )
        },
        qr/coderefs/,
        "non-coderef on_cleanup rejected",
    );
};

subtest 'signals_to_grab' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'sig-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
        on_sig    => {HUP => sub { }, TERM => sub { }},
    );
    my @sigs = sort $svc->signals_to_grab;
    is(\@sigs, ['HUP', 'TERM'], "signals_to_grab returns on_sig keys");
};

subtest 'push/remove/clear/run action callbacks' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'cb-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
    );

    my $called = 0;
    my $cb = sub { $called++ };

    $svc->push_on_interval($cb);
    $svc->run_on_interval;
    is($called, 1, "callback called via run_on_interval");

    $svc->remove_on_interval($cb);
    $svc->run_on_interval;
    is($called, 1, "callback not called after remove");

    $svc->push_on_interval($cb);
    $svc->clear_on_interval;
    $svc->run_on_interval;
    is($called, 1, "callback not called after clear");
};

subtest 'unshift action callback' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'us-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
    );

    my @order;
    $svc->push_on_start(sub { push @order, 'first' });
    $svc->unshift_on_start(sub { push @order, 'second' });

    $svc->run_on_start;
    is(\@order, ['second', 'first'], "unshift prepends");
};

subtest 'run_should_end' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'end-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
    );

    ok(!$svc->run_should_end, "should_end false with no callbacks");

    $svc->push_should_end(sub { 0 });
    ok(!$svc->run_should_end, "should_end false when callbacks return false");

    $svc->push_should_end(sub { 1 });
    ok($svc->run_should_end, "should_end true when any callback returns true");
};

subtest 'on_pid push/remove/clear/run' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'onpid-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
    );

    my @got;
    my $cb = sub { my ($self, $pid, $exit) = @_; push @got, [$pid, $exit]; };

    $svc->push_on_pid($cb);
    $svc->run_on_pid(4242, 256);
    is(\@got, [[4242, 256]], "on_pid callback invoked with pid and exit");

    $svc->remove_on_pid($cb);
    $svc->run_on_pid(1, 0);
    is(\@got, [[4242, 256]], "on_pid callback not invoked after remove");

    $svc->push_on_pid($cb);
    $svc->clear_on_pid;
    $svc->run_on_pid(2, 0);
    is(\@got, [[4242, 256]], "on_pid callback not invoked after clear");
};

subtest 'on_pid accepts array of callbacks in constructor' => sub {
    my @order;
    my $svc = IPC::Manager::Service->new(
        name      => 'onpid-arr',
        ipcm_info => 'fake',
        on_all    => sub { },
        on_pid    => [
            sub { push @order, ['a', $_[1], $_[2]] },
            sub { push @order, ['b', $_[1], $_[2]] },
        ],
    );

    $svc->run_on_pid(99, 512);
    is(\@order, [['a', 99, 512], ['b', 99, 512]], "both on_pid callbacks invoked in order");
};

subtest 'on_pid rejects non-coderef' => sub {
    like(
        dies {
            IPC::Manager::Service->new(
                name      => 'bad-onpid',
                ipcm_info => 'fake',
                on_all    => sub { },
                on_pid    => 'not_a_coderef',
            )
        },
        qr/coderefs/,
        "non-coderef on_pid rejected",
    );
};

subtest 'on_sig push/remove/clear/run' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'onsig-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
    );

    my $called = 0;
    my $cb = sub { $called++ };

    $svc->push_on_sig('HUP', $cb);
    $svc->run_on_sig('HUP');
    is($called, 1, "on_sig HUP called");

    $svc->remove_on_sig('HUP', $cb);
    $svc->run_on_sig('HUP');
    is($called, 1, "on_sig HUP not called after remove");

    $svc->push_on_sig('HUP', $cb);
    $svc->clear_on_sig('HUP');
    $svc->run_on_sig('HUP');
    is($called, 1, "on_sig HUP not called after clear");
};

subtest 'defaults' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'def-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
    );

    is($svc->cycle, 0.2, "default cycle");
    is($svc->interval, 0.2, "default interval");
};

subtest 'custom cycle and interval' => sub {
    my $svc = IPC::Manager::Service->new(
        name      => 'custom-svc',
        ipcm_info => 'fake',
        on_all    => sub { },
        cycle     => 0.5,
        interval  => 1.0,
    );

    is($svc->cycle, 0.5, "custom cycle");
    is($svc->interval, 1.0, "custom interval");
};

subtest 'on_all with array of callbacks' => sub {
    my @order;
    my $svc = IPC::Manager::Service->new(
        name      => 'arr-svc',
        ipcm_info => 'fake',
        on_all    => [sub { push @order, 'a' }, sub { push @order, 'b' }],
    );

    $svc->run_on_all;
    is(\@order, ['a', 'b'], "multiple on_all callbacks run in order");
};

done_testing;
