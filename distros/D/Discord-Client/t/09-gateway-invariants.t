use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use Discord::Client::Gateway::Session;

sub ready {
    my $session = Discord::Client::Gateway::Session->new(
        token => 'FAKE',
        random => sub { 0.25 }
    );
    $session->opened;
    $session->receive( { op => 10, d => { heartbeat_interval => 1000 } } );
    $session->receive(
        {
            op => 0,
            s => 42,
            t => 'READY',
            d => { session_id => 'abc', resume_gateway_url => 'wss://resume.test' }
        }
    );
    return $session;
}

T2->subtest(
    'malformed packets leave resume state intact',
    sub {
        # Vary one malformed protocol field at a time while starting from valid resume state.
        my @invalid_packets = (
            { name => 'undefined packet', packet => undef, error => qr/packet must be a hashref/ },
            { name => 'array packet', packet => [], error => qr/packet must be a hashref/ },
            { name => 'text packet', packet => 'text', error => qr/packet must be a hashref/ },
            { name => 'missing opcode', packet => {}, error => qr/opcode missing or invalid/ },
            {
                name => 'opcode reference',
                packet => { op => [] },
                error => qr/opcode missing or invalid/
            },
            {
                name => 'negative opcode',
                packet => { op => -1 },
                error => qr/opcode missing or invalid/
            },
            {
                name => 'negative sequence',
                packet => { op => 0, s => -1, t => 'EVENT' },
                error => qr/sequence is invalid/
            },
            {
                name => 'sequence reference',
                packet => { op => 0, s => [], t => 'EVENT' },
                error => qr/sequence is invalid/
            },
            {
                name => 'missing sequence',
                packet => { op => 0, s => undef, t => 'EVENT' },
                error => qr/sequence is invalid/
            },
            {
                name => 'empty event name',
                packet => { op => 0, s => 99, t => '' },
                error => qr/missing event name/
            },
            {
                name => 'READY missing resume data',
                packet => { op => 0, s => 99, t => 'READY', d => {} },
                error => qr/READY requires session_id and resume_gateway_url/
            },
            {
                name => 'READY session ID reference',
                packet => {
                    op => 0,
                    s => 99,
                    t => 'READY',
                    d => { session_id => [], resume_gateway_url => 'wss://resume.test' }
                },
                error => qr/READY requires/
            },
            {
                name => 'READY insecure resume URL',
                packet => {
                    op => 0,
                    s => 99,
                    t => 'READY',
                    d => { session_id => 'x', resume_gateway_url => 'http://bad' }
                },
                error => qr/READY requires/
            },
            {
                name => 'INVALID_SESSION object',
                packet => { op => 9, d => {} },
                error => qr/requires a boolean/
            },
            {
                name => 'INVALID_SESSION truthy string',
                packet => { op => 9, d => 'truthy' },
                error => qr/requires a boolean/
            },
        );

        # Each failure must leave the previous sequence, identity and readiness intact.
        for my $case (@invalid_packets) {
            T2->subtest(
                $case->{name},
                sub {
                    my $session = ready();
                    T2->like( T2->dies( sub { $session->receive( $case->{packet} ) } ),
                        $case->{error}, 'the error identifies the malformed field' );
                    T2->is( $session->sequence, 42, 'the last valid sequence is preserved' );
                    T2->is( $session->session_id, 'abc', 'resume session data is preserved' );
                    T2->is( $session->state, 'ready', 'the valid session remains ready' );
                }
            );
        }
    }
);

T2->subtest(
    'invalid jitter cannot partially authenticate',
    sub {
        # Exercise non-finite and out-of-range injected randomness before handshake mutation.
        my @invalid_jitter = (
            { name => 'negative value', value => -1 },
            { name => 'excluded upper bound', value => 1 },
            { name => 'undefined value', value => undef },
            { name => 'not a finite number', value => 'NaN' },
            { name => 'reference value', value => [] },
        );
        for my $case (@invalid_jitter) {
            my $value = $case->{value};
            my $session = Discord::Client::Gateway::Session->new(
                token => 'FAKE',
                random => sub { $value }
            );
            $session->opened;
            T2->like(
                T2->dies( sub { $session->receive( { op => 10, d => { heartbeat_interval => 1000 } } ) } ),
                qr/random generator/,
                "$case->{name} is rejected"
            );
            T2->is( $session->state, 'awaiting_hello', 'handshake remains unmodified' );
            T2->is( $session->heartbeat_interval_ms, undef, 'no partial timer interval' );
        }
    }
);

T2->subtest(
    'deterministic heartbeat sequences and JSON booleans',
    sub {
        my $session = ready();

        # Advance dispatch sequences and acknowledge every beat to isolate sequence tracking.
        for my $sequence ( 43 .. 48 ) {
            $session->receive( { op => 0, s => $sequence, t => 'FUTURE_EVENT', d => { new => $sequence } } );
            T2->is( $session->heartbeat_due->[0]{payload}{d}, $sequence, 'heartbeat uses latest dispatch' );
            $session->receive( { op => 11 } );
        }
        T2->ok( !$session->heartbeat_pending, 'ACK clears watchdog' );

        # A decoded JSON false must invalidate the session just like a numeric false.
        my $actions = $session->receive( { op => 9, d => JSON::PP::false } );
        T2->ok( !$actions->[0]{resume} && !$session->can_resume, 'JSON false invalidates session' );
    }
);

T2->subtest(
    'invalid HELLO intervals preserve the handshake and allow a valid retry',
    sub {
        my @cases = (
            { name => 'missing interval', value => undef },
            { name => 'zero interval', value => 0 },
            { name => 'negative interval', value => -1 },
            { name => 'fractional interval', value => 0.5 },
            { name => 'non-numeric interval', value => 'soon' },
            { name => 'reference interval', value => [] },
        );
        for my $case (@cases) {
            T2->subtest(
                $case->{name},
                sub {
                    my $session = Discord::Client::Gateway::Session->new(
                        token => 'FAKE',
                        random => sub { 0.25 }
                    );
                    $session->opened;

                    # Invalid input must not leave timers or authentication partially configured.
                    T2->like(
                        T2->dies(
                            sub {
                                $session->receive(
                                    {
                                        op => 10,
                                        d => { heartbeat_interval => $case->{value} },
                                    }
                                );
                            }
                        ),
                        qr/invalid heartbeat interval/,
                        'HELLO is rejected for the expected reason'
                    );
                    T2->is( $session->state, 'awaiting_hello', 'handshake remains available' );
                    T2->is( $session->heartbeat_interval_ms, undef, 'no interval is installed' );

                    # After rejecting bad input, the same session must still accept a valid HELLO.
                    my $actions = $session->receive( { op => 10, d => { heartbeat_interval => 1000 } } );
                    T2->is(
                        $actions->[0],
                        {
                            action => 'heartbeat_schedule',
                            first_delay_ms => 250,
                            interval_ms => 1000,
                        },
                        'a subsequent valid HELLO schedules the expected heartbeat'
                    );
                    T2->is( $actions->[1]{payload}{op}, 2, 'authentication starts after valid input' );
                }
            );
        }
    }
);

T2->subtest(
    'shard payload and fatal session cleanup',
    sub {
        # Shard identity belongs in Identify, while fatal closure must discard resume state.
        my $session = Discord::Client::Gateway::Session->new(
            token => 'FAKE',
            shard => [ 1, 2 ],
            random => sub { 0 }
        );
        $session->opened;
        T2->is(
            $session->receive( { op => 10, d => { heartbeat_interval => 1000 } } )->[1]{payload}{d}{shard},
            [ 1, 2 ],
            'Identify carries shard'
        );
        $session = ready();
        $session->closed(4004);
        T2->ok( !$session->can_resume, 'fatal close clears credentials for resume' );
    }
);

T2->done_testing;
