use v5.26;
use warnings;
use Test2::V1;
use Future;
use Scalar::Util qw(weaken);
use lib 't/lib';
use TestDiscordREST qw(error);
use TestDiscordGateway qw(rig ready_socket);

T2->subtest(
    'handshake, heartbeat ACK watchdog and Resume',
    sub {
        my $fixture = rig();
        my $gateway = $fixture->{gateway};
        my @events;
        $gateway->on( '*' => sub { push @events, [ $_[0], $_[1], $_[3] ] } );
        T2->is( scalar( @{ $fixture->{rest}{calls} } ), 0, 'constructor has no network side effects' );

        # Drive discovery and authentication before running deferred application notifications.
        my $connected = $gateway->connect;
        T2->ok( !$connected->is_ready, 'connect waits for READY' );
        T2->is( $fixture->{rest}{calls}, [ [ 'GET', '/gateway/bot' ] ], 'discovers Gateway Bot metadata' );
        T2->like( $fixture->{sockets}[0]{url}, qr{^wss://gateway\.test/\?v=10&encoding=json$}, 'v10 JSON URL' );
        my $websocket = ready_socket($fixture);
        T2->ok( $connected->is_done, 'READY resolves connect' );
        T2->is( $gateway->state, 'ready', 'ready state' );
        T2->is( $websocket->{frames}[0]{op}, 2, 'Identify sent' );
        T2->is( $websocket->{frames}[0]{d}{intents}, 1, 'minimal intents' );
        T2->is( scalar(@events), 0, 'dispatch deferred away from protocol receive' );
        $fixture->{clock}->run_deferred;
        T2->is( $events[0][0], 'READY', 'READY handler dispatched' );
        $websocket->emit( { op => 0, s => 47, t => 'FUTURE_EVENT', d => { extra => 'ok' }, new_field => 'raw' } );
        $fixture->{clock}->run_deferred;
        T2->is( $events[-1][2]{new_field}, 'raw', 'full unknown payload fields retained' );

        # Measure a confirmed heartbeat before intentionally missing the next acknowledgement.
        $fixture->{clock}->advance(0.25);
        T2->is( $websocket->{frames}[-1], { op => 1, d => 47 }, 'jittered heartbeat uses latest sequence' );
        $fixture->{clock}->advance(0.05);
        $websocket->emit( { op => 11 } );
        T2->is(
            $gateway->stats->{heartbeat_latency},
            T2->float( 0.05, tolerance => 0.00001 ),
            'ACK latency measured'
        );
        $fixture->{clock}->advance(0.95);
        T2->is( $websocket->{frames}[-1]{op}, 1, 'periodic heartbeat' );
        $fixture->{clock}->advance(1);
        T2->is( $gateway->state, 'reconnecting', 'missing ACK reconnects' );
        T2->ok( $websocket->{aborted}, 'zombie socket terminated abnormally to preserve resume' );
        $fixture->{clock}->advance(0.625);
        T2->is( scalar( @{ $fixture->{sockets} } ), 2, 'reconnect backoff honored' );

        # The replacement socket must Resume with the last dispatch, without another Identify.
        my $resume = $fixture->{sockets}[1];
        T2->like( $resume->{url}, qr{^wss://resume\.test/}, 'resume URL used' );
        $resume->open;
        $resume->emit( { op => 10, d => { heartbeat_interval => 1000 } } );
        T2->is(
            $resume->{frames}[0],
            {
                op => 6,
                d => { token => 'FAKE_GATEWAY_TOKEN', session_id => 'session-test', seq => 47 }
            },
            'Resume sent'
        );
        $resume->emit( { op => 0, s => 48, t => 'RESUMED', d => {} } );
        T2->is( $gateway->state, 'ready', 'RESUMED restores ready state' );
        T2->is( scalar( @{ $fixture->{rest}{calls} } ), 1, 'Resume does not fetch or consume Identify metadata' );

        # Callbacks from the old socket cannot disturb the replacement session.
        $websocket->text('{stale invalid packet');
        T2->is( $gateway->state, 'ready', 'stale socket callbacks ignored' );
        $gateway->close->get;
        T2->is( $fixture->{clock}->timer_count, 0, 'shutdown leaves no timer' );
        T2->ok( $gateway->completion->is_done, 'completion resolves on graceful close' );
    }
);

T2->subtest(
    'slow or failed handlers do not stop heartbeat and later events',
    sub {
        my $fixture = rig( max_handlers => 1 );
        my $gateway = $fixture->{gateway};

        # Hold the sole handler slot, then queue a listener that throws a private exception.
        my $slow = Future->new;
        my $calls = 0;
        $gateway->on(
            TEST => sub {
                $calls++;
                return $slow;
            }
        );
        $gateway->on(
            LATER => sub {
                $calls++;
                die 'FAKE_GATEWAY_TOKEN handler secret';
            }
        );
        $gateway->connect;
        my $websocket = ready_socket($fixture);
        $websocket->emit( { op => 0, s => 43, t => 'TEST', d => {} } );
        $websocket->emit( { op => 0, s => 44, t => 'LATER', d => {} } );
        $fixture->{clock}->run_deferred;
        T2->is( $calls, 1, 'bounded handler concurrency' );

        # Protocol work continues while application capacity is occupied.
        $fixture->{clock}->advance(0.25);
        T2->is( $websocket->{frames}[-1]{op}, 1, 'heartbeat independent of pending Future' );
        $websocket->emit( { op => 11 } );

        # A failed Future releases the next listener and both errors must be sanitized.
        $slow->fail( 'FAKE_GATEWAY_TOKEN async failure', 'handler' );
        $fixture->{clock}->run_deferred;
        T2->is( $calls, 2, 'subsequent handler runs after failure' );
        T2->is( scalar( @{ $fixture->{errors} } ), 2, 'async and thrown handler errors reported' );
        T2->unlike( join( ' ', @{ $fixture->{errors} } ), qr/FAKE_GATEWAY_TOKEN/, 'handler errors sanitized' );
        T2->is( $gateway->state, 'ready', 'handler failures leave receive loop alive' );
        $gateway->close;
    }
);

T2->subtest(
    'serialized writes, cancellation, size and queue bounds',
    sub {
        my $fixture = rig( max_outgoing => 2 );
        my $gateway = $fixture->{gateway};
        $gateway->connect;
        my $websocket = ready_socket($fixture);

        # Hold the active write so queue admission and queued cancellation can be observed.
        $websocket->{block_writes} = 1;
        T2->is( error( $gateway->send( '01', undef ) )->category,
            'request', 'numeric-string heartbeat cannot bypass protocol ownership' );
        my $first_write = $gateway->send( 3, { status => 'online' } );
        my $second_write = $gateway->send( 3, { status => 'idle' } );
        my $full = $gateway->send( 3, { status => 'dnd' } );
        T2->is( error($full)->category, 'queue_full', 'write queue bounded' );
        T2->is( scalar( @{ $websocket->{frames} } ), 2, 'only first application write sent' );
        $second_write->cancel;
        $websocket->{writes}[-1]->done;
        T2->ok( $first_write->is_done && $second_write->is_cancelled, 'queued cancellation works' );
        T2->is( scalar( @{ $websocket->{frames} } ), 2, 'cancelled frame not sent' );

        # Reject oversized encoded payloads before changing the active transport write.
        my $huge = $gateway->send( 3, { text => "\x{2603}" x 5000 } );
        T2->is( error($huge)->category, 'request', 'payload size bounded' );
        T2->is( $websocket->{max_active}, 1, 'transport writes serialized' );

        # Cancelling delivery already in progress must replace the uncertain connection.
        my $cancelled = $gateway->send( 3, {} );
        $cancelled->cancel;
        T2->is( $gateway->state, 'reconnecting', 'ambiguous active cancellation resets connection' );
        $gateway->close;
        T2->is( $fixture->{clock}->timer_count, 0, 'pending reconnect cancelled' );
    }
);

T2->subtest(
    'fatal close and malformed data',
    sub {
        my $fixture = rig();
        my $gateway = $fixture->{gateway};
        $gateway->connect;
        my $websocket = ready_socket($fixture);

        # Malformed JSON reconnects without echoing the private frame contents.
        $websocket->text('{FAKE_GATEWAY_TOKEN invalid JSON');
        T2->is( $gateway->state, 'reconnecting', 'bad JSON reconnects safely' );
        T2->unlike( join( ' ', @{ $fixture->{errors} } ), qr/FAKE_GATEWAY_TOKEN/, 'malformed frame never echoed' );
        $fixture->{clock}->advance(0.625);
        my $next = $fixture->{sockets}[-1];
        $next->open;
        $next->emit( { op => 10, d => { heartbeat_interval => 1000 } } );

        # A subsequent authentication rejection must end all retries and timers.
        $next->remote_close(4004);
        T2->is( $gateway->state, 'closed', 'fatal close stops reconnect' );
        T2->is( error( $gateway->completion )->close_code, 4004, 'fatal code surfaced' );
        T2->is( $fixture->{clock}->timer_count, 0, 'fatal close clears timers' );
        $fixture->{clock}->advance(100);
        T2->is( scalar( @{ $fixture->{sockets} } ), 2, 'no fatal reconnect storm' );
    }
);

T2->subtest(
    'shutdown and handshake timeout before READY',
    sub {
        my $fixture = rig( connect_timeout => 2 );
        my $gateway = $fixture->{gateway};

        # Let startup time out, then cancel its still-pending readiness wait.
        my $connection_future = $gateway->connect;
        $fixture->{clock}->advance(2);
        T2->is( $gateway->state, 'reconnecting', 'connect/HELLO timeout has backoff' );
        $connection_future->cancel;
        T2->is( $gateway->state, 'closed', 'connect cancellation closes client' );
        T2->is( $fixture->{clock}->timer_count, 0, 'all timers cancelled' );
        T2->ok( $fixture->{sockets}[0]{connect}->is_cancelled, 'connect I/O cancelled' );
    }
);

T2->subtest(
    'outbound quota preserves heartbeat capacity',
    sub {
        my $fixture = rig();
        my $gateway = $fixture->{gateway};
        $gateway->connect;
        my $websocket = ready_socket( $fixture, interval => 45000 );

        # A server-requested heartbeat must pass queued application writes.
        $websocket->{on_send} = sub { $websocket->emit( { op => 11 } ) if $_[0]{op} == 1 };

        # Saturate application quota while automatically acknowledging protocol heartbeats.
        my @sent = map { $gateway->send( 3, { status => 'online' } ) } 1 .. 120;
        T2->is( scalar( @{ $websocket->{frames} } ),
            T2->number_le(116), 'application traffic reserves protocol capacity' );
        T2->ok( !$sent[-1]->is_ready, 'overflow waits for Gateway rate window' );
        $websocket->emit( { op => 1 } );
        T2->is( $websocket->{frames}[-1]{op}, 1, 'requested heartbeat passes queued application traffic' );
        $fixture->{clock}->advance(59.99);
        T2->ok( !$sent[-1]->is_ready, 'rolling window respected' );
        $fixture->{clock}->advance(0.01);
        T2->ok( $sent[-1]->is_done, 'queued application traffic resumes at reset' );
        T2->is( $gateway->state, 'ready', 'no heartbeat timeout under application load' );
        $gateway->close;
        T2->is( $fixture->{clock}->timer_count, 0, 'outbound timer removed' );
    }
);

T2->subtest(
    'Identify waiting does not stop heartbeat',
    sub {
        my $first = rig();
        my $g1 = $first->{gateway};
        $g1->connect;
        my $ws1 = ready_socket($first);
        $ws1->{on_send} = sub { $ws1->emit( { op => 11 } ) if $_[0]{op} == 1 };
        my $clock = $first->{clock};

        # Share the first Gateway's limiter and clock with a second connection.
        my $second = rig(
            identify_limiter => $g1->identify_limiter,
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) }
        );
        my $g2 = $second->{gateway};
        my $start = $g2->connect;
        my $ws2 = $second->{sockets}[0];
        $ws2->open;
        $ws2->{on_send} = sub { $ws2->emit( { op => 11 } ) if $_[0]{op} == 1 };
        $ws2->emit( { op => 10, d => { heartbeat_interval => 1000 } } );

        # The second socket must heartbeat while waiting for its Identify bucket cooldown.
        $clock->advance(4.99);
        T2->ok( !grep( $_->{op} == 2, @{ $ws2->{frames} } ), 'Identify waits for shared concurrency bucket' );
        T2->ok( scalar grep( $_->{op} == 1, @{ $ws2->{frames} } ), 'heartbeats run while waiting' );
        $clock->advance(0.01);
        T2->is( $ws2->{frames}[-1]{op}, 2, 'Identify dispatched after cooldown' );
        $ws2->emit(
            {
                op => 0,
                s => 1,
                t => 'READY',
                d => { session_id => 'two', resume_gateway_url => 'wss://resume.test' }
            }
        );
        T2->ok( $start->is_done, 'waiting connection reaches READY' );
        $g2->close;
        $g1->close;
        T2->is( $clock->timer_count, 0, 'shared scheduler and both heartbeat timers cleaned' );
    }
);

T2->subtest(
    'server reconnect, invalid session and repeated failures',
    sub {
        my $fixture = rig();
        my $gateway = $fixture->{gateway};
        $gateway->connect;
        my $websocket = ready_socket($fixture);

        # An explicit reconnect is immediate; later failures must restore bounded backoff.
        $websocket->emit( { op => 7 } );
        $fixture->{clock}->advance(0);
        T2->is( scalar( @{ $fixture->{sockets} } ), 2, 'opcode 7 attempts Resume immediately' );
        my $next = $fixture->{sockets}[-1];
        $next->{connect}->fail( 'PRIVATE failure', 'connect' );
        $fixture->{clock}->advance(1.24);
        T2->is( scalar( @{ $fixture->{sockets} } ), 2, 'subsequent connection failure has backoff' );
        $fixture->{clock}->advance(0.01);
        T2->is( scalar( @{ $fixture->{sockets} } ), 3, 'exponential backoff retries' );

        # Invalidate the resumed session and require a new Identify after both delays.
        my $third = $fixture->{sockets}[-1];
        $third->open;
        $third->emit( { op => 10, d => { heartbeat_interval => 1000 } } );
        $third->emit( { op => 9, d => 0 } );
        $fixture->{clock}->advance(2.49);
        T2->is( scalar( @{ $fixture->{sockets} } ), 3, 'invalid session and exponential backoff both honored' );
        $fixture->{clock}->advance(0.01);
        T2->is( scalar( @{ $fixture->{sockets} } ), 4, 'new session attempt made after required delay' );
        T2->like( $fixture->{sockets}[-1]{url},
            qr{^wss://gateway\.test/}, 'new Identify uses original Gateway URL' );
        my $fresh = $fixture->{sockets}[-1];
        $fresh->open;
        $fresh->emit( { op => 10, d => { heartbeat_interval => 60_000 } } );
        $fixture->{clock}->advance(1.25);
        T2->is( [ map { $_->{op} } @{ $fresh->{frames} } ],
            [2], 'non-resumable session sends Identify instead of Resume after the cooldown' );
        $gateway->close;
    }
);

T2->subtest(
    'event queue saturation drops a whole dispatch without stopping the driver',
    sub {
        my $fixture = rig( max_events => 1 );
        my $gateway = $fixture->{gateway};
        my @seen;
        $gateway->on( TEST => sub { push @seen, $_[0]{id} } );
        $gateway->connect;
        my $websocket = ready_socket($fixture);

        # Overflow a one-event queue without ending the Gateway lifetime.
        $websocket->emit( { op => 0, s => 43, t => 'TEST', d => { id => 43 } } );
        $websocket->emit( { op => 0, s => 44, t => 'TEST', d => { id => 44 } } );
        $websocket->emit( { op => 0, s => 45, t => 'TEST', d => { id => 45 } } );
        T2->is( $gateway->state, 'ready', 'overflow leaves the Gateway connected' );
        T2->ok( !$gateway->completion->is_ready, 'overflow does not end the Gateway lifetime' );
        T2->is( $gateway->stats->{pending_events}, 1, 'queued work stays bounded' );
        T2->is( $gateway->stats->{dropped_events}, 2, 'each rejected dispatch is counted' );
        T2->is( scalar( @{ $fixture->{errors} } ), 1, 'a saturation episode reports one error' );
        T2->is( $fixture->{errors}[0]->category, 'queue_full', 'overflow is reported as queue_full' );

        # After draining accepted work, later events must be admitted again.
        $fixture->{clock}->run_deferred;
        T2->is( \@seen, [43], 'already queued event is delivered' );
        T2->is( $gateway->stats->{pending_events}, 0, 'queue drains after overload' );
        $websocket->emit( { op => 0, s => 46, t => 'TEST', d => { id => 46 } } );
        $fixture->{clock}->run_deferred;
        T2->is( \@seen, [ 43, 46 ], 'later events are delivered after capacity returns' );
        $gateway->close;
    }
);

T2->subtest(
    'overflow never delivers only part of an event',
    sub {
        my $fixture = rig( max_events => 2 );
        my $gateway = $fixture->{gateway};
        my @seen;
        $gateway->on( FIRST => sub { push @seen, 'first' } );
        $gateway->on( MULTI => sub { push @seen, 'multi one' } );
        $gateway->on( MULTI => sub { push @seen, 'multi two' } );
        $gateway->connect;
        my $websocket = ready_socket($fixture);

        # Leave room for one callback but not the next event's complete pair of listeners.
        $websocket->emit( { op => 0, s => 43, t => 'FIRST', d => {} } );
        $websocket->emit( { op => 0, s => 44, t => 'MULTI', d => {} } );
        T2->is( $gateway->stats->{dropped_events}, 1, 'whole event is counted as dropped' );
        T2->is( $gateway->stats->{dropped_callbacks}, 2, 'both callbacks are counted as dropped' );
        $fixture->{clock}->run_deferred;
        T2->is( \@seen, ['first'], 'no callback from the dropped event ran' );

        # Once capacity returns, both listeners for a new event must run together.
        $websocket->emit( { op => 0, s => 45, t => 'MULTI', d => {} } );
        $fixture->{clock}->run_deferred;
        T2->is( \@seen, [ 'first', 'multi one', 'multi two' ], 'both callbacks run when the whole event fits' );
        $gateway->close;
    }
);

T2->subtest(
    'shared handler Future still counts each pending invocation',
    sub {
        my $fixture = rig( max_handlers => 2 );
        my $gateway = $fixture->{gateway};

        # Return the same pending Future from multiple logical invocations.
        my $shared = Future->new;
        my $calls = 0;
        $gateway->on(
            TEST => sub {
                $calls++;
                return $shared;
            }
        );
        $gateway->connect;
        my $websocket = ready_socket($fixture);
        $websocket->emit( { op => 0, s => $_, t => 'TEST', d => {} } ) for 43 .. 47;
        $fixture->{clock}->run_deferred;
        T2->is( $calls, 2, 'reused Future cannot bypass handler limit' );
        T2->is( $gateway->stats->{active_handlers}, 2, 'logical invocations tracked separately' );

        # Settling the shared work must release all its slots and drain queued invocations.
        $shared->done;
        $fixture->{clock}->run_deferred;
        T2->is( $calls, 5, 'remaining callbacks drain after shared work completes' );
        T2->is( $gateway->stats->{active_handlers}, 0, 'all invocation references released' );
        $gateway->close;
    }
);

T2->subtest(
    'repeated READY/disconnect cycles retain backoff until stable',
    sub {
        my $fixture = rig( stable_after => 1 );
        my $gateway = $fixture->{gateway};
        $gateway->connect;

        # A briefly ready session must retain its increasing reconnect backoff.
        ready_socket($fixture)->remote_close(1006);
        $fixture->{clock}->advance(0.625);
        my $second = $fixture->{sockets}[-1];
        $second->open;
        $second->emit( { op => 10, d => { heartbeat_interval => 1000 } } );
        $second->emit( { op => 0, s => 43, t => 'RESUMED', d => {} } );
        $second->remote_close(1006);
        $fixture->{clock}->advance(0.625);
        T2->is( scalar( @{ $fixture->{sockets} } ), 2, 'brief READY does not reset reconnect backoff' );
        $fixture->{clock}->advance(0.625);

        # Only a full stable period with acknowledged heartbeats resets the backoff.
        my $third = $fixture->{sockets}[-1];
        $third->open;
        $third->emit( { op => 10, d => { heartbeat_interval => 1000 } } );
        $third->{on_send} = sub { $third->emit( { op => 11 } ) if $_[0]{op} == 1 };
        $third->emit( { op => 0, s => 44, t => 'RESUMED', d => {} } );
        $fixture->{clock}->advance(1);
        $third->remote_close(1006);
        $fixture->{clock}->advance(0.625);
        T2->is( scalar( @{ $fixture->{sockets} } ), 4, 'stable connection resets backoff' );
        $gateway->close;
    }
);

T2->subtest(
    'repeated close awaits the same transport shutdown',
    sub {
        my $fixture = rig();
        my $gateway = $fixture->{gateway};
        $gateway->connect;
        my $websocket = ready_socket($fixture);

        # Keep transport shutdown pending to verify repeated close calls share completion.
        $websocket->{close_future} = Future->new;
        my $closing = $gateway->close;
        T2->ref_is( $gateway->close, $closing, 'close Future reused' );
        T2->ok( !$closing->is_ready && !$gateway->completion->is_ready, 'lifecycle waits for transport' );
        $websocket->{close_future}->done;
        T2->ok( $closing->is_done && $gateway->completion->is_done, 'shutdown completion observed' );
        T2->is( $fixture->{clock}->timer_count, 0, 'no retained shutdown timers' );
    }
);

T2->subtest(
    'connect during reconnect waits for the next session',
    sub {
        my $fixture = rig();
        my $gateway = $fixture->{gateway};
        $gateway->connect;
        ready_socket($fixture)->remote_close(1006);

        # A new readiness observer must wait for RESUMED, not reuse the previous READY result.
        my $again = $gateway->connect;
        T2->ok( !$again->is_ready, 'reconnect does not return the earlier READY result' );
        $fixture->{clock}->advance(0.625);
        my $websocket = $fixture->{sockets}[-1];
        $websocket->open;
        $websocket->emit( { op => 10, d => { heartbeat_interval => 1000 } } );
        $websocket->emit( { op => 0, s => 43, t => 'RESUMED', d => {} } );
        T2->ok( $again->is_done, 'new connect Future resolves on RESUMED' );
        $gateway->close;
    }
);

T2->subtest(
    'closing Gateway handlers cancel application work but preserve shutdown',
    sub {
        for my $return_close ( 0, 1 ) {

            # Exercise both possible pending returns from a closing handler.
            my $fixture = rig();
            my $gateway = $fixture->{gateway};
            my $work = Future->new;
            my $closing;
            $gateway->on(
                READY => sub {
                    $closing = $gateway->close;
                    return $return_close ? $closing : $work;
                }
            );
            my $started = $gateway->connect;
            my $websocket = ready_socket($fixture);
            my $transport_close = $websocket->{close_future} = Future->new;

            # The transport remains pending; only unrelated work is cancelled.
            $fixture->{clock}->run_deferred;
            T2->ok( $started->is_done, 'startup completed' );
            T2->ok( !$closing->is_ready, 'graceful shutdown remains pending' );
            T2->ok( $work->is_cancelled, 'returned application work is cancelled' ) unless $return_close;
            $transport_close->done unless $transport_close->is_ready;
            T2->ok( $closing->is_done, 'graceful shutdown completes' );
            $work->cancel unless $work->is_ready;
        }
    }
);

T2->done_testing;
