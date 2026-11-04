use v5.26;
use warnings;
use Test2::V1;
use Discord::Client::Gateway::Session;

sub new_session {

    # Fix randomness so heartbeat jitter and reconnect delays are reproducible.
    return Discord::Client::Gateway::Session->new(
        token => 'FAKE_TEST_TOKEN',
        intents => [ 'GUILDS', 'GUILD_MESSAGES' ],
        random => sub { 0.25 },
    );
}

sub begin_handshake {
    my $session = new_session();

    # Drive the public session transition before delivering HELLO.
    $session->opened;
    $session->receive( { op => 10, d => { heartbeat_interval => 40000 } } );
    return $session;
}

sub ready_packet {
    return {
        op => 0,
        s => 42,
        t => 'READY',
        d => { session_id => 'session-1', resume_gateway_url => 'wss://resume.example.test' },
    };
}

sub ready_session {
    my $session = begin_handshake();
    $session->receive( ready_packet() );
    return $session;
}

T2->subtest(
    'opening a connection waits for HELLO before sending authentication',
    sub {
        my $session = new_session();

        # Opening a socket must not spend an Identify before Discord supplies HELLO.
        T2->is( $session->state, 'disconnected', 'a new session has no connection' );
        T2->is( $session->opened, [], 'opening alone emits no action' );
        T2->is( $session->state, 'awaiting_hello', 'authentication waits for HELLO' );
    }
);

T2->subtest(
    'HELLO schedules a jittered heartbeat and sends Identify',
    sub {
        my $session = new_session();
        $session->opened;

        # Negotiate the interval with fixed randomness so the initial jitter is exact.
        my $actions = $session->receive( { op => 10, d => { heartbeat_interval => 40000 } } );

        T2->is(
            $actions->[0],
            { action => 'heartbeat_schedule', first_delay_ms => 10000, interval_ms => 40000 },
            'the first heartbeat uses injected jitter and retains the server interval'
        );
        T2->is( $actions->[1]{payload}{op}, 2, 'the session identifies on its first connection' );
        T2->is( $actions->[1]{payload}{d}{intents}, 513, 'Identify combines the requested intents' );
        T2->is( $session->state, 'authenticating', 'the session now waits for READY' );
    }
);

T2->subtest(
    'READY delivers the event and retains the data needed to resume',
    sub {
        my $session = begin_handshake();
        my $packet = ready_packet();

        # Deliver READY and inspect both the emitted event and the retained resume identity.
        my $actions = $session->receive($packet);

        T2->is(
            $actions,
            [ { action => 'event', name => 'READY', data => $packet->{d} } ],
            'the driver receives the complete READY event'
        );
        T2->is( $session->state, 'ready', 'authentication is complete' );
        T2->ok( $session->can_resume, 'the session can resume a future connection' );
        T2->is( $session->sequence, 42, 'the last dispatch sequence is retained' );
    }
);

T2->subtest(
    'a heartbeat sends the current sequence and ACK clears the watchdog',
    sub {
        my $session = ready_session();

        # Issue a heartbeat against the most recent dispatch sequence.
        my $actions = $session->heartbeat_due;

        T2->is(
            $actions,
            [ { action => 'send', payload => { op => 1, d => 42 } } ],
            'the heartbeat contains the last dispatch sequence'
        );
        T2->ok( $session->heartbeat_pending, 'the heartbeat waits for acknowledgment' );

        # Acknowledge the beat before another interval can declare the socket unhealthy.
        $session->receive( { op => 11 } );
        T2->ok( !$session->heartbeat_pending, 'ACK clears the outstanding heartbeat' );
    }
);

T2->subtest(
    'a requested reconnect resumes the previous session after HELLO',
    sub {
        my $session = ready_session();

        # Ask the session to reconnect while its previous identity is still resumable.
        my $actions = $session->receive( { op => 7 } );

        T2->is(
            $actions,
            [ { action => 'reconnect', resume => 1, delay_ms => 0 } ],
            'the driver reconnects immediately with resume data'
        );

        # Negotiate a replacement socket and confirm Resume uses the saved sequence.
        $session->opened;
        $actions = $session->receive( { op => 10, d => { heartbeat_interval => 40000 } } );
        T2->is( $actions->[1]{payload}{op}, 6, 'the next connection sends Resume' );
        T2->is( $actions->[1]{payload}{d}{session_id}, 'session-1', 'Resume uses the previous session ID' );
        T2->is( $actions->[1]{payload}{d}{seq}, 42, 'Resume uses the previous dispatch sequence' );
        $session->receive( { op => 0, s => 44, t => 'RESUMED', d => {} } );
        T2->is( $session->state, 'ready', 'RESUMED restores the ready state' );
    }
);

T2->subtest(
    'an unknown dispatch is delivered without discarding its fields',
    sub {
        my $session = ready_session();

        # Future Discord events must pass through without losing unknown fields.
        my $actions =
            $session->receive( { op => 0, s => 45, t => 'NEW_UNKNOWN_DISPATCH', d => { future_field => 'ok' } } );

        T2->is(
            $actions,
            [ { action => 'event', name => 'NEW_UNKNOWN_DISPATCH', data => { future_field => 'ok' } } ],
            'the driver can deliver future event types and fields'
        );
    }
);

T2->subtest(
    'explicit shutdown stops the session and discards resume data',
    sub {
        my $session = ready_session();

        # An explicit stop must discard the identity that automatic reconnect would retain.
        $session->stop;

        T2->is( $session->state, 'stopped', 'the session is stopped' );
        T2->ok( !$session->can_resume, 'explicit shutdown clears resume data' );
    }
);

T2->done_testing;
