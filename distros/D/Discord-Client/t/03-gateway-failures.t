use v5.26;
use warnings;
use Test2::V1;
use Discord::Client::Gateway::Session;

sub ready_session {
    my $session = Discord::Client::Gateway::Session->new( token => 'FAKE', random => sub { 0.5 } );

    # Establish resumable state through a complete handshake before testing failures.
    $session->opened;
    $session->receive( { op => 10, d => { heartbeat_interval => 1000 } } );
    $session->receive(
        {
            op => 0,
            s => 99,
            t => 'READY',
            d => { session_id => 'abc', resume_gateway_url => 'wss://resume.example.test' }
        }
    );
    return $session;
}

T2->subtest(
    'a missing heartbeat ACK requests an immediate reconnect with resume data',
    sub {
        my $session = ready_session();
        $session->heartbeat_due;

        # Leave the first beat unacknowledged and let the next interval detect the failure.
        my $actions = $session->heartbeat_due;

        T2->is(
            $actions,
            [ { action => 'reconnect', resume => 1, delay_ms => 0 } ],
            'the next heartbeat detects the missing ACK'
        );
    }
);

T2->subtest(
    'a non-resumable invalid session is discarded before reidentifying',
    sub {
        my $session = ready_session();

        # Force a fresh session while retaining the mandated random reconnect delay.
        my $actions = $session->receive( { op => 9, d => 0 } );

        T2->is(
            $actions,
            [ { action => 'reconnect', resume => 0, delay_ms => 3000 } ],
            'the driver reidentifies after the injected random delay'
        );
        T2->ok( !$session->can_resume, 'the invalid session cannot be reused' );
    }
);

T2->subtest(
    'a resumable invalid session preserves data while waiting to reconnect',
    sub {
        my $session = ready_session();

        # Exercise the same delay with a session Discord permits us to resume.
        my $actions = $session->receive( { op => 9, d => 1 } );

        T2->is(
            $actions,
            [ { action => 'reconnect', resume => 1, delay_ms => 3000 } ],
            'the driver resumes after the injected random delay'
        );
    }
);

# Configuration and authentication close codes terminate instead of reconnecting.
for my $code ( 4004, 4010, 4011, 4012, 4013, 4014 ) {
    T2->subtest(
        "fatal close code $code stops the session without reconnecting",
        sub {
            my $session = ready_session();

            my $actions = $session->closed($code);

            T2->is(
                $actions,
                [ { action => 'fatal', close_code => $code } ],
                'the driver receives a fatal close action'
            );
            T2->is( $session->state, 'stopped', 'the session stops after a fatal close' );
        }
    );
}

# These recoverable closes reconnect with a fresh Identify rather than stale state.
for my $code ( 1000, 1001, 4007, 4009 ) {
    T2->subtest(
        "close code $code requires a new Identify",
        sub {
            my $session = ready_session();

            my $actions = $session->closed($code);

            T2->is(
                $actions,
                [ { action => 'reconnect', resume => 0, delay_ms => 0 } ],
                'the driver reconnects without the old resume data'
            );
        }
    );
}

T2->subtest(
    'an abnormal close resumes the previous session',
    sub {
        my $session = ready_session();

        # An interrupted socket alone does not invalidate the session identity.
        my $actions = $session->closed(1006);

        T2->is(
            $actions,
            [ { action => 'reconnect', resume => 1, delay_ms => 0 } ],
            'an interrupted connection retains its resume data'
        );
    }
);

T2->subtest(
    'an unknown opcode remains available to the driver',
    sub {
        my $session = ready_session();

        # Preserve future opcodes for consumers instead of treating them as parser errors.
        my $actions = $session->receive( { op => 99, d => { x => 1 } } );

        T2->is(
            $actions,
            [ { action => 'opcode', op => 99, data => { x => 1 } } ],
            'the unrecognized opcode and payload are preserved'
        );
    }
);

T2->subtest(
    'HELLO is rejected after authentication without changing the session',
    sub {
        my $session = ready_session();

        # An invalid transition must not overwrite an already authenticated session.
        T2->like(
            T2->dies( sub { $session->receive( { op => 10, d => { heartbeat_interval => 1000 } } ) } ),
            qr/HELLO received outside handshake/,
            'the error identifies the unexpected HELLO'
        );
        T2->is( $session->state, 'ready', 'the authenticated session remains ready' );
        T2->is( $session->sequence, 99, 'the previous dispatch sequence is preserved' );
    }
);

T2->subtest(
    'a malformed HELLO leaves the initial handshake unchanged',
    sub {
        my $session = Discord::Client::Gateway::Session->new( token => 'FAKE' );
        $session->opened;

        # Reject malformed handshake data before installing heartbeat state.
        T2->like(
            T2->dies( sub { $session->receive( { op => 10, d => undef } ) } ),
            qr/HELLO payload must be a hashref/,
            'the error identifies the missing payload'
        );
        T2->is( $session->state, 'awaiting_hello', 'the session still waits for a valid HELLO' );
        T2->is( $session->heartbeat_interval_ms, undef, 'the malformed HELLO installs no heartbeat' );
    }
);

T2->done_testing;
