package IPC::Manager::Test;
use strict;
use warnings;

use Carp qw/croak confess/;
use File::Spec;
use File::Temp;
use Time::HiRes;
use POSIX();
use Test2::V1 -ip;
use Test2::IPC;
use IPC::Manager::Serializer::JSON;
use IPC::Manager qw/ipcm_service ipcm_worker ipcm_connect ipcm_reconnect ipcm_spawn ipcm_default_protocol/;

sub run_all {
    my $class  = shift;
    my %params = @_;

    my $protocol = $params{protocol} or croak "'protocol' is required";
    ipcm_default_protocol($protocol);

    local $SIG{ALRM} = sub { confess("Test timed out after 180 seconds") };
    alarm 180;

    for my $test ($class->tests) {
        my $pid = fork // die "Could not fork: $!";
        if ($pid) {
            waitpid($pid, 0);
            next;
        }

        my $ok  = eval { subtest $test => $class->can($test); 1 };
        my $err = $@;
        warn $err unless $ok;
        exit($ok ? 0 : 255);
    }

    alarm 0;
}

sub tests {
    my $class = shift;

    my $stash = do { no strict 'refs'; \%{"$class\::"} };

    my @out;

    for my $sym (sort keys %$stash) {
        next unless $sym =~ m/^test_/;
        next unless $class->can($sym);

        push @out => $sym;
    }

    return @out;
}

sub test_simple_service {
    my $parent_pid = $$;

    my $got_req = 0;
    my $handle  = ipcm_service foo => sub {
        my $self = shift;
        my ($activity) = @_;

        return if $activity->{interval} && keys(%$activity) == 1;

        if (my $msgs = $activity->{messages}) {
            for my $msg (@$msgs) {
                my $c = $msg->content;

                if (ref($c) eq 'HASH') {
                    if ($c->{ipcm_request_id}) {
                        $got_req = 1;
                        is($msg->content->{request}, "${parent_pid} blah?", "Got request from parent pid");
                        $self->send_response($msg->from, $c->{ipcm_request_id}, "$$ blah!");
                    }
                    elsif ($c->{terminate}) {
                        ok($got_req, "$$ Got the request!");
                    }
                }
            }
        }
    };

    my $service_pid = $handle->service_pid;

    my $got_resp = 0;
    $handle->send_request(
        foo => "$$ blah?",
        sub {
            my ($resp, $msg) = @_;
            $got_resp = 1;
            is($msg->content->{response}, "${service_pid} blah!", "Got expected response");
        }
    );

    $handle->await_all_responses;

    ok($got_resp, "Got response!");

    $handle = undef;
}

sub test_generic {
    my $guard = ipcm_spawn(do_sanity_check => 1);
    my $info  = "$guard";

    isa_ok($guard, ['IPC::Manager::Spawn'], "Got a spawn object");
    is($info, $guard->info, "Stringifies");
    like(
        IPC::Manager::Serializer::JSON->deserialize($info),
        [ipcm_default_protocol(), "IPC::Manager::Serializer::JSON", $guard->route],
        "Got a useful info string"
    );
    note("Info: $info");

    my $con1 = ipcm_connect('con1' => $info);
    my $con2 = ipcm_connect('con2' => $info);
    note("Con: $con1");

    isa_ok($con1, ['IPC::Manager::Client'], "Got a connection (con1)");
    isa_ok($con2, ['IPC::Manager::Client'], "Got a connection (con2)");

    like([$con1->get_messages], [], "No messages");
    like([$con2->get_messages], [], "No messages");

    $con1->send_message(con2 => {hi   => 'there'});
    $con2->send_message(con1 => {ahoy => 'matey'});

    like(
        [$con1->get_messages],
        [{
            id      => T(),
            stamp   => T(),
            from    => 'con2',
            to      => 'con1',
            content => {ahoy => 'matey'},
        }],
        "Got message sent from con2 to con1"
    );

    like(
        [$con2->get_messages],
        [{
            id      => T(),
            stamp   => T(),
            from    => 'con1',
            to      => 'con2',
            content => {hi => 'there'},
        }],
        "Got message sent from con1 to con2"
    );

    like([$con1->get_messages], [], "No messages");
    like([$con2->get_messages], [], "No messages");

    $con1->send_message(con2 => "string message!");
    like(
        [$con2->get_messages],
        [{
            id      => T(),
            stamp   => T(),
            from    => 'con1',
            to      => 'con2',
            content => "string message!",
        }],
        "Got message sent from con1 to con2"
    );

    my $con3 = ipcm_connect('con3' => $info);

    $con3->broadcast({mass => 'message'});

    like(
        [$con1->get_messages],
        [{
            id      => T(),
            stamp   => T(),
            from    => 'con3',
            to      => 'con1',
            content => {mass => 'message'},
        }],
        "Got broadcast (3 -> 1)"
    );

    like(
        [$con2->get_messages],
        [{
            id      => T(),
            stamp   => T(),
            from    => 'con3',
            to      => 'con2',
            content => {mass => 'message'},
        }],
        "Got broadcast (3 -> 2)"
    );

    like(
        [$con3->get_messages],
        [],
        "No broadcast (3 -> 3)"
    );

    $con3->broadcast({mass => 'message2'});
    $con3->broadcast({mass => 'message3'});

    # Non-blocking sockets may not deliver all datagrams instantly,
    # so poll until we have the expected count.
    my (@con1_msgs, @con2_msgs);
    my $deadline = Time::HiRes::time() + 5;
    until (@con1_msgs >= 2 && @con2_msgs >= 2) {
        push @con1_msgs => $con1->get_messages;
        push @con2_msgs => $con2->get_messages;
        last if Time::HiRes::time() > $deadline;
        Time::HiRes::sleep(0.05) unless @con1_msgs >= 2 && @con2_msgs >= 2;
    }
    is(\@con1_msgs, [T(), T()], "Got 2 more");
    is(\@con2_msgs, [T(), T()], "Got 2 more");

    $con1->send_message(con2 => 'woosh, I am invisible');

    my $stats = {};
    for my $con ($con1, $con2, $con3) {
        $con->write_stats;
        $stats->{$con->id} = $con->read_stats;
    }

    is(
        $stats,
        {
            'con1' => {
                'read' => {'con2' => 1, 'con3' => 3},
                'sent' => {'con2' => 3},
            },
            'con2' => {
                'read' => {'con1' => 2, 'con3' => 3},
                'sent' => {'con1' => 1},
            },
            'con3' => {
                'read' => {},
                'sent' => {'con1' => 3, 'con2' => 3},
            }
        },
        "Got expected stats"
    );

    is(
        warnings { $guard = undef },
        [
            match qr/Messages waiting at disconnect for con2/,
            match qr/Messages sent vs received mismatch:.*1 con1 -> con2/s,
        ],
        "Got warnings"
    );
    ok(!-e $info, "Info does not exist on the filesystem");
}

sub test_nested_services {
    my $parent_pid = $$;

    my $outer_handle = ipcm_service(
        'outer_svc',
        class    => 'IPC::Manager::Service',
        on_start => sub {
            my $self = shift;

            # Start a nested inner service in void context (same ipcm bus).
            # ipcm_service detects we are inside a service and reuses the
            # existing ipcm_info; the peer is retrieved later via $self->peer.
            ipcm_service 'inner_svc' => sub {
                my ($inner_self, $activity) = @_;

                return if $activity->{interval} && keys(%$activity) == 1;

                if (my $msgs = $activity->{messages}) {
                    for my $msg (@$msgs) {
                        my $c = $msg->content;
                        if (ref($c) eq 'HASH' && $c->{ipcm_request_id}) {
                            $inner_self->send_response(
                                $msg->from,
                                $c->{ipcm_request_id},
                                "inner: $c->{request}",
                            );
                        }
                    }
                }
            };

            # Void-context ipcm_service does not wait for the service to be
            # ready, so spin here before returning from on_start.  Without
            # this, a request from the test process could arrive before
            # inner_svc has connected to the bus, causing a stall.
            sleep 0.025 until $self->peer('inner_svc')->ready;
        },

        # Receive a request from the test process, forward it to the nested
        # inner service, and defer the response until the inner service replies.
        handle_request => sub {
            my ($self, $req, $msg) = @_;

            my $orig_id   = $req->{ipcm_request_id};
            my $orig_from = $msg->from;

            $self->peer('inner_svc')->send_request(
                $req->{request},
                sub {
                    my ($resp, $resp_msg) = @_;
                    $self->send_response($orig_from, $orig_id, "outer: $resp->{response}");
                }
            );

            return ();    # Deferred - will respond via callback above
        },

        # IPC::Manager::Service's handle_response calls the user-supplied
        # callback instead of the role's response-tracking machinery, so we
        # have to dispatch _RESPONSE_HANDLER callbacks ourselves.
        handle_response => sub {
            my ($self, $resp, $msg) = @_;
            my $id = $resp->{ipcm_response_id};
            if (my $handler = delete $self->{_RESPONSE_HANDLER}->{$id}) {
                $handler->($resp, $msg);
            }
        },
    );

    my $outer_svc_pid = $outer_handle->service_pid;
    isnt($outer_svc_pid, $parent_pid, "Outer service runs in a different process");

    my $got_resp = 0;
    $outer_handle->send_request(
        outer_svc => "hello",
        sub {
            my ($resp, $msg) = @_;
            $got_resp = 1;
            is($resp->{response}, "outer: inner: hello", "Got chained response through nested services");
        }
    );

    $outer_handle->await_all_responses;

    ok($got_resp, "Got response from nested service chain");

    $outer_handle = undef;
}

sub test_exec_service {
    my $parent_pid = $$;

    # Build -I flags so the exec'd process can find our libs
    my @inc_flags = map { "-I$_" } grep { !ref($_) } @INC;

    my $got_resp = 0;
    my $handle = ipcm_service(
        'exec_svc',
        class => 'IPC::Manager::Service::Echo',
        exec  => {cmd => \@inc_flags},
    );

    my $service_pid = $handle->service_pid;
    isnt($service_pid, $parent_pid, "Exec service runs in a different process");

    $handle->send_request(
        exec_svc => "ping",
        sub {
            my ($resp, $msg) = @_;
            $got_resp = 1;
            is($resp->{response}, "echo: ping", "Got expected response from exec'd service");
        },
    );

    $handle->await_all_responses;

    ok($got_resp, "Got response from exec'd service");

    $handle = undef;
}

sub test_workers {
    my $parent_pid = $$;

    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $marker_file   = File::Spec->catfile($marker_dir, 'worker_ran');
    my $longpid_file  = File::Spec->catfile($marker_dir, 'long_worker_pid');
    my $killed_file   = File::Spec->catfile($marker_dir, 'long_worker_killed');

    my $handle = ipcm_service(
        'worker_svc',
        class    => 'IPC::Manager::Service',
        on_start => sub {
            my $self = shift;

            # Worker that does a short task and exits
            ipcm_worker short_worker => sub {
                open my $fh, '>', $marker_file or die "open: $!";
                print $fh "$$\n";
                close $fh;
                return 0;
            };

            # Worker that runs until killed
            ipcm_worker long_worker => sub {
                my $kfile = $killed_file;
                $SIG{TERM} = sub {
                    open my $kfh, '>', $kfile or die "open: $!";
                    print $kfh "$$\n";
                    close $kfh;
                    exit 0;
                };

                open my $fh, '>', $longpid_file or die "open: $!";
                print $fh "$$\n";
                close $fh;

                sleep 1 while 1;
                return 0;
            };
        },

        handle_request => sub {
            my ($self, $req, $msg) = @_;

            if ($req->{request} eq 'worker_count') {
                my $workers = $self->workers // {};
                return scalar keys %$workers;
            }

            return undef;
        },
    );

    my $service_pid = $handle->service_pid;
    isnt($service_pid, $parent_pid, "Worker service runs in a different process");

    # Wait for the short worker to finish and write its marker
    my $waited = 0;
    until (-e $marker_file || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $marker_file, "Short worker ran and wrote marker file");

    # Wait for the long worker to write its pid
    $waited = 0;
    until (-e $longpid_file || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $longpid_file, "Long worker wrote pid file");

    open(my $fh, '<', $longpid_file) or die "open: $!";
    chomp(my $long_worker_pid = <$fh>);
    close($fh);
    ok($long_worker_pid, "Got long worker pid");

    # Verify the long worker is still running
    ok(kill(0, $long_worker_pid), "Long worker is running before shutdown");

    # Ask the service how many workers are registered (long_worker should
    # still be there; short_worker may or may not have been reaped yet)
    my $got_count = 0;
    $handle->send_request(
        worker_svc => 'worker_count',
        sub {
            my ($resp, $msg) = @_;
            $got_count = $resp->{response};
        },
    );
    $handle->await_all_responses;
    ok($got_count >= 1, "Service has at least 1 registered worker (got $got_count)");

    # Drop the handle — triggers shutdown which sends terminate, then the
    # service's DESTROY calls terminate_workers to kill lingering workers.
    $handle = undef;

    # Wait for the killed marker file to appear
    my $tries = 0;
    until (-e $killed_file || $tries >= 50) {
        Time::HiRes::sleep(0.1);
        $tries++;
    }
    ok(-e $killed_file, "Long worker received TERM signal during shutdown");
}

sub test_suspend_and_reconnect {
    my $proto = ipcm_default_protocol();

    return skip_all "suspend/reconnect not supported by $proto"
        unless $proto->suspend_supported;

    my $guard = ipcm_spawn(guard => 0);
    my $info  = "$guard";

    my $con1 = ipcm_connect('sr1' => $info);
    my $con2 = ipcm_connect('sr2' => $info);

    # Send a message, then suspend con2
    $con1->send_message(sr2 => {before => 'suspend'});
    $con2->suspend;

    # con2 is now suspended — send another message while it's away
    $con1->send_message(sr2 => {during => 'suspend'});

    # Reconnect
    my $con2b = ipcm_reconnect('sr2' => $info);
    ok($con2b, "Reconnected as sr2");

    # Should receive both messages
    my @msgs = $con2b->get_messages;
    is(scalar @msgs, 2, "Got both messages after reconnect");
    my @contents = map { $_->content } @msgs;
    like(\@contents, [{before => 'suspend'}, {during => 'suspend'}], "Messages preserved across suspend");

    $con1->disconnect;
    $con2b->disconnect;
    $guard->unspawn;
}

sub test_sync_request {
    my $handle = ipcm_service(
        'sync_svc',
        class          => 'IPC::Manager::Service',
        handle_request => sub {
            my ($self, $req, $msg) = @_;
            return "sync_echo: $req->{request}";
        },
    );

    my $resp = $handle->sync_request(sync_svc => "hello_sync");
    is($resp->{response}, "sync_echo: hello_sync", "sync_request returned correct response");

    $handle = undef;
}

sub test_multiple_requests {
    my $handle = ipcm_service(
        'multi_svc',
        class          => 'IPC::Manager::Service',
        handle_request => sub {
            my ($self, $req, $msg) = @_;
            return "reply_$req->{request}";
        },
    );

    my @got;
    for my $i (1 .. 5) {
        $handle->send_request(
            multi_svc => "req_$i",
            sub {
                my ($resp, $msg) = @_;
                push @got, $resp->{response};
            },
        );
    }

    $handle->await_all_responses;

    is(scalar @got, 5, "Got all 5 responses");
    is([sort @got], [sort map { "reply_req_$_" } 1..5], "All responses correct");

    $handle = undef;
}

sub test_handle_messages_buffer {
    my $handle = ipcm_service(
        'buf_svc',
        class          => 'IPC::Manager::Service',
        handle_request => sub {
            my ($self, $req, $msg) = @_;

            # Send a non-response message back alongside the response
            $self->client->send_message(
                $msg->from,
                {notification => "event_$req->{request}"},
            );

            return "ack";
        },
    );

    my $resp = $handle->sync_request(buf_svc => "ping");
    is($resp->{response}, "ack", "Got response");

    # The notification should be in the handle's message buffer
    my @buffered = $handle->messages;
    is(scalar @buffered, 1, "One buffered non-response message");
    is($buffered[0]->content->{notification}, "event_ping", "Notification content correct");

    # Buffer is drained
    my @again = $handle->messages;
    is(scalar @again, 0, "Buffer empty after drain");

    $handle = undef;
}

sub test_service_callbacks {
    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $interval_file  = File::Spec->catfile($marker_dir, 'interval_ran');
    my $peer_file      = File::Spec->catfile($marker_dir, 'peer_delta');
    my $cleanup_file   = File::Spec->catfile($marker_dir, 'cleanup_ran');
    my $should_end_req = File::Spec->catfile($marker_dir, 'should_end');

    my $handle = ipcm_service(
        'cb_svc',
        class    => 'IPC::Manager::Service',
        interval => 0.1,

        on_interval => sub {
            my $self = shift;
            unless (-e $interval_file) {
                open my $fh, '>', $interval_file or die "open: $!";
                print $fh "$$\n";
                close $fh;
            }
        },

        on_peer_delta => sub {
            my ($self, $delta) = @_;
            open my $fh, '>>', $peer_file or die "open: $!";
            for my $peer (sort keys %$delta) {
                print $fh "$peer:$delta->{$peer}\n";
            }
            close $fh;
        },

        on_cleanup => sub {
            my $self = shift;
            open my $fh, '>', $cleanup_file or die "open: $!";
            print $fh "$$\n";
            close $fh;
        },

        should_end => sub {
            my $self = shift;
            return -e $should_end_req ? 1 : 0;
        },

        handle_request => sub {
            my ($self, $req, $msg) = @_;
            return "ok";
        },
    );

    # Wait for on_interval to fire
    my $waited = 0;
    until (-e $interval_file || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $interval_file, "on_interval callback fired");

    # Trigger peer_delta by connecting a new client to the same bus
    my $extra = ipcm_connect('extra_peer' => $handle->ipcm_info);
    # Let the service notice
    Time::HiRes::sleep(0.5);
    $extra->disconnect;
    Time::HiRes::sleep(0.5);
    ok(-e $peer_file, "on_peer_delta callback fired");

    # Trigger should_end
    open my $fh, '>', $should_end_req or die "open: $!";
    close $fh;

    # Wait for cleanup file (service should end and run cleanup)
    $waited = 0;
    until (-e $cleanup_file || $waited > 10) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $cleanup_file, "on_cleanup callback fired after should_end");

    $handle = undef;
}

sub test_service_signal_handling {
    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $sig_file = File::Spec->catfile($marker_dir, 'got_signal');

    my $handle = ipcm_service(
        'sig_svc',
        class  => 'IPC::Manager::Service',
        on_sig => {
            USR1 => sub {
                my $self = shift;
                open my $fh, '>', $sig_file or die "open: $!";
                print $fh "$$\n";
                close $fh;
            },
        },
        handle_request => sub {
            my ($self, $req, $msg) = @_;
            return "ok";
        },
    );

    my $svc_pid = $handle->service_pid;
    ok($svc_pid, "Got service pid");

    # Send USR1 to the service
    kill('USR1', $svc_pid);

    my $waited = 0;
    until (-e $sig_file || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $sig_file, "Signal handler ran after USR1");

    $handle = undef;
}

sub test_peer_active {
    my $guard = ipcm_spawn();
    my $info  = "$guard";

    my $con1 = ipcm_connect('pa1' => $info);
    my $con2 = ipcm_connect('pa2' => $info);

    ok($con1->peer_active('pa2'), "pa2 is active");
    ok($con2->peer_active('pa1'), "pa1 is active");

    ok(!$con1->peer_active('nonexistent'), "nonexistent peer is not active");

    $con1->disconnect;
    $con2->disconnect;
    $guard = undef;
}

sub test_disconnect_with_handler {
    my $guard = ipcm_spawn();
    my $info  = "$guard";

    my $con1 = ipcm_connect('dh1' => $info);
    my $con2 = ipcm_connect('dh2' => $info);

    # Send messages that will be waiting when con2 disconnects
    $con1->send_message(dh2 => {msg => 'waiting_1'});
    $con1->send_message(dh2 => {msg => 'waiting_2'});

    # Disconnect with a handler callback — messages should be passed to it
    # instead of producing a warning.
    my @handled;
    $con2->disconnect(sub {
        my ($self, $msgs) = @_;
        push @handled, @$msgs;
    });

    is(scalar @handled, 2, "Handler received 2 pending messages");
    my @contents = map { $_->content->{msg} } sort { $a->stamp <=> $b->stamp } @handled;
    is(\@contents, ['waiting_1', 'waiting_2'], "Handler got correct message contents");

    $con1->disconnect;
    $guard = undef;
}

sub test_try_message {
    my $guard = ipcm_spawn();
    my $info  = "$guard";

    my $con1 = ipcm_connect('tm1' => $info);
    my $con2 = ipcm_connect('tm2' => $info);

    # Success path — scalar context
    my $ok = $con1->try_message(tm2 => {data => 'hello'});
    ok($ok, "try_message returns true on success (scalar)");

    # Success path — list context
    my ($ok2, $err) = $con1->try_message(tm2 => {data => 'world'});
    ok($ok2, "try_message returns true on success (list)");
    ok(!$err, "no error on success (list)");

    # Verify messages arrived
    my @msgs = $con2->get_messages;
    is(scalar @msgs, 2, "Both try_message calls delivered");

    # Failure path — peer doesn't exist
    my ($ok3, $err3) = $con1->try_message(nonexistent => 'nope');
    ok(!$ok3, "try_message returns false for missing peer");
    ok($err3, "error returned for missing peer");

    $con1->disconnect;
    $con2->disconnect;
    $guard = undef;
}

sub test_general_messages_to_service {
    # Sends a plain message (not a request or response) to a service and
    # verifies run_on_general_message is invoked.
    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $general_file = File::Spec->catfile($marker_dir, 'general_msg');

    my $handle = ipcm_service(
        'gen_svc',
        class => 'IPC::Manager::Service',

        on_general_message => sub {
            my ($self, $msg) = @_;
            my $c = $msg->content;
            return unless ref($c) eq 'HASH' && defined $c->{text};
            open my $fh, '>>', $general_file or die "open: $!";
            print $fh $c->{text}, "\n";
            close $fh;
        },

        handle_request => sub {
            my ($self, $req, $msg) = @_;
            return "ok";
        },
    );

    # Send a plain (non-request) message directly via the handle's client
    $handle->client->send_message(gen_svc => {text => 'plain_hello'});

    my $waited = 0;
    until (-e $general_file || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $general_file, "on_general_message callback fired");

    if (-e $general_file) {
        open my $fh, '<', $general_file or die "open: $!";
        chomp(my $line = <$fh>);
        close $fh;
        is($line, 'plain_hello', "General message content correct");
    }

    $handle = undef;
}

sub test_intercept_errors {
    # Verifies that a service with intercept_errors => 1 catches exceptions
    # in multiple callback types instead of dying, and continues processing.
    # Also verifies that a crashing handle_request sends an error response.

    local *STDERR = *STDOUT;

    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $interval_survived  = File::Spec->catfile($marker_dir, 'interval_ok');
    my $general_survived   = File::Spec->catfile($marker_dir, 'general_ok');
    my $peer_delta_survived = File::Spec->catfile($marker_dir, 'peer_delta_ok');

    my $interval_count = 0;
    my $handle = ipcm_service(
        'ie_svc',
        class                => 'IPC::Manager::Service',
        intercept_errors     => 1,
        expose_error_details => 1,
        interval             => 0.1,

        on_interval => sub {
            my $self = shift;
            $interval_count++;
            # Throw on the first call; subsequent calls write the marker
            if ($interval_count == 1) {
                die "interval boom\n";
            }
            unless (-e $interval_survived) {
                open my $fh, '>', $interval_survived or die "open: $!";
                close $fh;
            }
        },

        on_general_message => sub {
            my ($self, $msg) = @_;
            my $c = $msg->content;
            return unless ref($c) eq 'HASH';
            if ($c->{action} && $c->{action} eq 'crash') {
                die "general_message boom\n";
            }
        },

        on_peer_delta => sub {
            my ($self, $delta) = @_;
            # Always throw — service should survive
            die "peer_delta boom\n";
        },

        handle_request => sub {
            my ($self, $req, $msg) = @_;
            die "request boom\n" if $req->{request} eq 'crash';
            return "ok";
        },
    );

    # 1) on_interval: first call throws, second should still fire
    my $waited = 0;
    until (-e $interval_survived || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $interval_survived, "on_interval survived exception and kept firing");

    # 2) on_peer_delta: connect a peer — triggers an exception, but service
    #    should keep running
    my $extra = ipcm_connect('ie_extra' => $handle->ipcm_info);
    Time::HiRes::sleep(0.5);
    $extra->disconnect;
    Time::HiRes::sleep(0.3);

    # Verify service is still alive after peer_delta exception
    my $resp = $handle->sync_request(ie_svc => 'ping');
    is($resp->{response}, 'ok', "Service survived on_peer_delta exception");

    # 3) on_general_message: send a plain message that throws
    $handle->client->send_message(ie_svc => {action => 'crash'});
    Time::HiRes::sleep(0.5);

    # Verify service is still alive after general_message exception
    my $resp2 = $handle->sync_request(ie_svc => 'ping');
    is($resp2->{response}, 'ok', "Service survived on_general_message exception");

    # 4) handle_request: send a request that throws — should get an error response
    my $err_resp = $handle->sync_request(ie_svc => 'crash');
    ok($err_resp->{ipcm_error}, "Got error response from crashing request");
    like($err_resp->{ipcm_error}, qr/request boom/, "Error response contains exception details");
    ok(!defined $err_resp->{response}, "Response is undef on error");

    # 5) Service still works after all the exceptions
    my $resp3 = $handle->sync_request(ie_svc => 'ping');
    is($resp3->{response}, 'ok', "Service still alive after all intercepted errors");

    $handle = undef;
}

sub test_watch_pids {
    # Verifies that a service terminates when a watched PID exits.
    # Uses watch_pids => [$$] by watching the parent.  The parent forks a
    # temporary child to own the IPC bus while the service runs; the parent
    # then exits that scope so the service sees the pid die.

    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $cleanup_file = File::Spec->catfile($marker_dir, 'wp_cleanup');
    my $ready_file   = File::Spec->catfile($marker_dir, 'wp_ready');

    # Fork a child that acts as the watched process.  It starts the service
    # with watch_pids pointing at itself, verifies the service works, then
    # exits — causing the service to detect the pid death.
    my $child = fork // die "fork: $!";
    if ($child == 0) {
        my $handle = ipcm_service(
            'wp_svc',
            class      => 'IPC::Manager::Service',
            watch_pids => [$$],

            on_cleanup => sub {
                my $self = shift;
                open my $fh, '>', $cleanup_file or die "open: $!";
                print $fh "$$\n";
                close $fh;
            },

            handle_request => sub {
                my ($self, $req, $msg) = @_;
                return "ok";
            },
        );

        my $resp = $handle->sync_request(wp_svc => 'ping');
        # Signal parent we are ready
        open my $fh, '>', $ready_file or die "open: $!";
        print $fh "$resp->{response}\n";
        close $fh;

        # Exit — the service watches our pid and should terminate
        exit(0);
    }

    # Wait for child to signal readiness
    my $waited = 0;
    until (-e $ready_file || $waited > 10) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $ready_file, "Child started service and sent request");

    if (-e $ready_file) {
        open my $fh, '<', $ready_file or die "open: $!";
        chomp(my $resp = <$fh>);
        close $fh;
        is($resp, 'ok', "Service responded before watched pid died");
    }

    # Reap the child (whose exit triggers the service's watch_pids)
    waitpid($child, 0);

    # Wait for service to notice and run cleanup
    $waited = 0;
    until (-e $cleanup_file || $waited > 10) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $cleanup_file, "Service exited after watched pid terminated");
}

sub test_spawn_terminate_with_signal {
    # Tests that Spawn::terminate sends the configured signal to service
    # processes.  The signal is sent before the terminate broadcast so the
    # service's on_sig handler has a chance to run before the event loop ends.
    my $marker_dir = File::Temp::tempdir(CLEANUP => 1);
    my $sig_file = File::Spec->catfile($marker_dir, 'got_usr1');

    my $handle = ipcm_service(
        'sigterm_svc',
        class  => 'IPC::Manager::Service',
        on_sig => {
            USR1 => sub {
                my $self = shift;
                open my $fh, '>', $sig_file or die "open: $!";
                print $fh "$$\n";
                close $fh;
            },
        },
        handle_request => sub {
            my ($self, $req, $msg) = @_;
            return "ok";
        },
    );

    # Verify service is running
    my $resp = $handle->sync_request(sigterm_svc => 'ping');
    is($resp->{response}, 'ok', "Service running before signal test");

    # Set the signal on the spawn so shutdown sends USR1 to all peers
    # before the terminate broadcast.
    $handle->{spawn}->{signal} = 'USR1';

    # Drop the handle — triggers shutdown which sends USR1 then broadcasts terminate
    $handle = undef;

    my $waited = 0;
    until (-e $sig_file || $waited > 5) {
        Time::HiRes::sleep(0.1);
        $waited += 0.1;
    }
    ok(-e $sig_file, "Service received signal from Spawn::terminate");
}

sub test_cleave {
    my $guard = ipcm_spawn(guard => 0);
    my $info  = "$guard";

    my $original_pid = $guard->pid;
    is($original_pid, $$, "Spawn pid is ours before cleave");

    my $cleave_result = $guard->cleave;

    if ($cleave_result) {
        # Parent — cleave_result is the new owner PID
        ok($cleave_result != $$, "Cleave returned new PID to parent");
        isnt($guard->pid, $$, "Spawn ownership transferred");

        # Connect, send a message, verify the bus still works
        my $con = ipcm_connect('cleave_test' => $info);
        ok($con, "Can connect to bus after cleave");
        $con->disconnect;

        # Kill the cleaved process and clean up
        kill('TERM', $cleave_result);
        waitpid($cleave_result, 0);

        $guard->unspawn;
    }
    else {
        # Child (new owner) — just exit.  Don't unspawn; the parent
        # still needs the route to verify the bus works.
        exit(0);
    }
}

sub test_request_error_generic {
    my $handle = ipcm_service(
        'err_generic_svc',
        class          => 'IPC::Manager::Service',
        handle_request => sub {
            my ($self, $req, $msg) = @_;
            die "secret internal failure\n" if $req->{request} eq 'crash';
            return "ok";
        },
    );

    # Normal request works
    my $resp = $handle->sync_request(err_generic_svc => 'hello');
    is($resp->{response}, 'ok', "Normal request succeeds");
    ok(!$resp->{ipcm_error}, "No error on normal request");

    # Crashing request returns a generic error (default: expose_error_details off)
    my $err_resp = $handle->sync_request(err_generic_svc => 'crash');
    ok($err_resp->{ipcm_error}, "Error response has ipcm_error flag");
    is($err_resp->{ipcm_error}, 'Internal service error', "Error message is generic");
    unlike($err_resp->{ipcm_error}, qr/secret/, "Internal details not exposed");
    ok(!defined $err_resp->{response}, "Response is undef on error");

    # Service is still alive after the error
    my $resp2 = $handle->sync_request(err_generic_svc => 'hello');
    is($resp2->{response}, 'ok', "Service still works after error");

    $handle = undef;
}

sub test_request_error_detailed {
    my $handle = ipcm_service(
        'err_detail_svc',
        class                => 'IPC::Manager::Service',
        expose_error_details => 1,
        handle_request       => sub {
            my ($self, $req, $msg) = @_;
            die "detailed failure info\n" if $req->{request} eq 'crash';
            return "ok";
        },
    );

    # Crashing request returns the actual exception text
    my $err_resp = $handle->sync_request(err_detail_svc => 'crash');
    ok($err_resp->{ipcm_error}, "Error response has ipcm_error flag");
    like($err_resp->{ipcm_error}, qr/detailed failure info/, "Error exposes exception details");
    ok(!defined $err_resp->{response}, "Response is undef on error");

    # Service is still alive
    my $resp = $handle->sync_request(err_detail_svc => 'hello');
    is($resp->{response}, 'ok', "Service still works after detailed error");

    $handle = undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Test - Reusable protocol-agnostic test suite for IPC::Manager

=head1 DESCRIPTION

This module provides a set of standard tests that verify the correctness of
an L<IPC::Manager> protocol implementation.  Each test is an ordinary method
whose name begins with C<test_>; they are discovered automatically by
C<tests()> and executed by C<run_all()>.

Protocol test files typically look like:

    use Test2::V1 -ipP;
    use Test2::IPC;
    use IPC::Manager::Test;
    IPC::Manager::Test->run_all(protocol => 'AtomicPipe');
    done_testing;

=head1 METHODS

=over 4

=item IPC::Manager::Test->run_all(protocol => $PROTOCOL)

Run every C<test_*> method as an isolated subtest.  Each test is forked into
its own process so that failures and resource leaks cannot affect sibling
tests.  C<protocol> is required and is set as the default protocol via
C<ipcm_default_protocol> before any test runs.

=item @names = IPC::Manager::Test->tests

Returns a sorted list of all C<test_*> method names defined on the class (or
a subclass).  Used internally by C<run_all>.

=item IPC::Manager::Test->test_generic

Tests the low-level IPC bus: spawning a store, connecting multiple clients,
sending point-to-point and broadcast messages, verifying message contents and
ordering, and checking that per-client statistics are accurate on disconnect.

=item IPC::Manager::Test->test_simple_service

Tests C<ipcm_service> at the single-service level: starts a named service,
sends a request to it from the parent process, verifies the service echoes a
response back with the correct content, and confirms that both sides observed
the exchange.

=item IPC::Manager::Test->test_nested_services

Tests the nested-service code path where C<ipcm_service> is called from
B<inside> a running service.  An outer service starts an inner service during
its C<on_start> callback, then acts as a transparent proxy: each request
received from the test process is forwarded to the inner service, and the
inner service's response is returned to the caller with an identifying prefix.
The test verifies the full two-hop request/response chain.

=item IPC::Manager::Test->test_exec_service

Tests the C<exec> code path of C<ipcm_service>.  Instead of running the
service in a forked child, the child calls C<exec()> to start a fresh Perl
interpreter that loads L<IPC::Manager::Service::State> and deserialises the
service parameters from C<@ARGV>.  The test starts
L<IPC::Manager::Service::Echo> via exec, sends a request, and verifies
the echoed response.

=item IPC::Manager::Test->test_workers

Tests the C<ipcm_worker> facility.  A service spawns two workers during
C<on_start>: a short-lived worker that writes a marker file and exits, and a
long-lived worker that sleeps indefinitely.  The test verifies that both
workers run, that the service tracks them via C<workers()>, and that
C<terminate_workers()> kills the long-lived worker when the service shuts
down.

=item IPC::Manager::Test->test_suspend_and_reconnect

Tests the suspend/reconnect lifecycle.  A client suspends (preserving its
slot on the bus), messages are sent to it while it is away, and then it
reconnects and verifies that both the pre-suspend and during-suspend messages
are received.  Skipped for protocols that do not support reconnect (e.g.
AtomicPipe).

=item IPC::Manager::Test->test_sync_request

Tests synchronous (blocking) request/response via C<< $handle->sync_request >>.
Sends a single request and verifies the returned response without using
callbacks.

=item IPC::Manager::Test->test_multiple_requests

Sends five concurrent requests to a service using callback-based
C<send_request>, awaits all responses with C<await_all_responses>, and
verifies that every response arrived with the correct content.

=item IPC::Manager::Test->test_handle_messages_buffer

Tests the Handle's non-response message buffer.  A service sends both a
response and a plain (non-response) notification for the same request.
The test verifies the response is delivered via the callback and the
notification lands in C<< $handle->messages >>.

=item IPC::Manager::Test->test_service_callbacks

Exercises the C<on_interval>, C<on_peer_delta>, C<on_cleanup>, and
C<should_end> service callbacks in a single service.  Verifies that
C<on_interval> fires periodically, C<on_peer_delta> fires when a new peer
connects, C<should_end> terminates the service when its condition becomes
true, and C<on_cleanup> runs during shutdown.

=item IPC::Manager::Test->test_service_signal_handling

Tests the C<on_sig> callback by starting a service that intercepts C<SIGUSR1>,
sending the signal from the test process, and verifying the handler ran.

=item IPC::Manager::Test->test_peer_active

Tests C<< $client->peer_active >> by connecting two clients and verifying each
sees the other as active.  Also verifies that a nonexistent peer name returns
false.

=item IPC::Manager::Test->test_disconnect_with_handler

Tests the disconnect handler callback.  Sends messages to a client then
disconnects it with a handler; verifies the handler receives the pending
messages instead of producing a warning.

=item IPC::Manager::Test->test_try_message

Tests C<try_message> in both scalar and list context for both the success
path (message delivered) and the failure path (nonexistent peer).

=item IPC::Manager::Test->test_general_messages_to_service

Sends a plain (non-request, non-response) message to a service and verifies
that C<on_general_message> is invoked with the correct content.

=item IPC::Manager::Test->test_intercept_errors

Starts a service with C<< intercept_errors => 1 >>, sends a request that
triggers an exception in the handler, then sends a second request to verify
the service survived and continued processing.

=item IPC::Manager::Test->test_watch_pids

Tests the C<watch_pids> mechanism.  A child process starts a service that
watches the child's own PID.  The child exits, and the test verifies that
the service detected the death and ran its cleanup callback.

=item IPC::Manager::Test->test_spawn_terminate_with_signal

Tests that C<< Spawn::terminate >> sends a signal to service processes when
the spawn has a signal configured.  Verifies the service's C<on_sig> handler
fires for the delivered signal.

=item IPC::Manager::Test->test_cleave

Tests C<< Spawn::cleave >> by double-forking ownership of the IPC bus away
from the current process.  Verifies the parent receives the new owner's PID,
spawn ownership transfers, and the bus remains functional.

=back

=item IPC::Manager::Test->test_request_error_generic

Tests that an exception in C<handle_request> sends an error response with
C<ipcm_error> set to a generic message (C<"Internal service error">) and
C<response> set to undef.  Verifies the service continues operating after
the error.  This is the default behaviour (C<expose_error_details> off).

=item IPC::Manager::Test->test_request_error_detailed

Tests that with C<< expose_error_details => 1 >> an exception in
C<handle_request> sends an error response whose C<ipcm_error> contains the
actual exception text.  Verifies the service continues operating.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
