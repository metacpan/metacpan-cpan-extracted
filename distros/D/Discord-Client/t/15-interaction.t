use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use Future;
use lib 't/lib';
use TestDiscordREST qw(client response error);
use Discord::Client::Interaction;

sub context {
    my (%args) = @_;
    my ( $rest, $http, $clock ) = client();

    # Provide a valid command envelope while allowing each scenario to replace selected fields.
    my $payload = {
        id => '123',
        application_id => '456',
        token => 'FAKE_INTERACTION_TOKEN',
        type => 2,
        data => { name => 'ping', type => 1 },
        user => { id => '18446744073709551615' },
        %{ $args{payload} // {} }
    };
    delete $args{payload};
    my $interaction = Discord::Client::Interaction->new(
        payload => $payload,
        rest => $rest,
        loop => $rest->loop,
        clock => sub { $clock->{now} },
        delay => sub { $clock->delay( $_[0] ) },
        %args
    );
    return ( $interaction, $rest, $http, $clock );
}

T2->subtest(
    'reply reservation and followup lifecycle',
    sub {
        my ( $interaction, $rest, $http, $clock ) = context();
        T2->is( $http->count, 0, 'context construction performs no HTTP' );

        # Reserve the single initial response before the transport confirms delivery.
        my $response_future = $interaction->reply( 'Pong!', ephemeral => 1 );
        T2->is( $interaction->state, 'responding', 'initial reply reserved before response' );
        T2->is( error( $interaction->reply('duplicate') )->category, 'state', 'concurrent duplicate rejected' );
        T2->is( $http->count, 1, 'only one initial request' );
        T2->is(
            $http->call->{request}->uri->path,
            '/api/v10/interactions/123/FAKE_INTERACTION_TOKEN/callback',
            'callback route'
        );
        T2->ok( !defined( $http->call->{request}->header('Authorization') ), 'token-only authorization' );
        T2->is(
            JSON::PP->new->utf8->decode( $http->call->{request}->content ),
            { type => 4, data => { content => 'Pong!', flags => 64 } },
            'reply payload'
        );
        $http->respond( response( 204, undef ) );
        T2->ok( $response_future->is_done && $interaction->acknowledgement->is_done, 'confirmed acknowledgement' );
        T2->is( $interaction->state, 'replied', 'replied state' );
        T2->is( $clock->timer_count, 0, 'initial timer cancelled' );

        # Confirmed acknowledgement enables webhook followups and original-message edits.
        my $followup = $interaction->followup( 'More', ephemeral => 1 );
        T2->is(
            $http->call->{request}->uri->path,
            '/api/v10/webhooks/456/FAKE_INTERACTION_TOKEN',
            'followup route'
        );
        T2->is( $http->call->{request}->uri->query, 'wait=true', 'followup requests returned message' );
        $http->respond( response( 200, { id => '999' } ) );
        T2->is( $followup->get->{id}, '999', 'followup result retained' );
        my $edit = $interaction->edit_original('edited');
        T2->is( $http->call->{request}->method, 'PATCH', 'edit method' );
        $http->respond( response( 200, { content => 'edited' } ) );
        T2->ok( $edit->is_done, 'original edit' );

        # A closed context must reject further token-based operations.
        $interaction->close;
        T2->is( error( $interaction->followup('closed') )->category, 'shutdown', 'closed context rejects I/O' );
        $rest->close;
    }
);

T2->subtest(
    'defer then reply edits the original exactly once',
    sub {
        my ( $interaction, $rest, $http ) = context();

        # Fix ephemeral visibility in the initial deferral before completing its message.
        my $defer = $interaction->defer( ephemeral => 1 );
        T2->is(
            JSON::PP->new->utf8->decode( $http->call->{request}->content ),
            { type => 5, data => { flags => 64 } },
            'deferred visibility'
        );
        $http->respond( response( 204, undef ) );
        T2->is( $interaction->state, 'deferred', 'deferred state' );
        T2->is( error( $interaction->reply( 'result', ephemeral => 0 ) )->category,
            'request', 'deferred visibility cannot change' );

        # Completion edits the original exactly once, including while its PATCH is pending.
        my $result = $interaction->reply('result');
        T2->is( $http->call->{request}->method, 'PATCH', 'deferred reply is an edit' );
        T2->is( error( $interaction->reply('duplicate') )->category, 'state', 'concurrent final reply prevented' );
        $http->respond( response( 200, { content => 'result' } ) );
        T2->ok( $result->is_done, 'final reply succeeds' );
        T2->is( error( $interaction->reply('duplicate') )->category, 'state', 'second final reply prevented' );
        $interaction->close;
        $rest->close;
    }
);

T2->subtest(
    'deadline includes queue/transport waiting and late dispatch',
    sub {
        # A payload received too long ago must fail before sending any request.
        my ( $interaction, $rest, $http, $clock ) = context();

        # Let transport waiting consume the initial three-second deadline.
        my $response_future = $interaction->reply('slow');
        my $io = $http->call->{future};
        $clock->advance(3);
        T2->is( error($response_future)->category, 'deadline', 'pending initial request fails at deadline' );
        T2->ok( $io->is_cancelled, 'HTTP cancellation propagated' );
        T2->is( error( $interaction->reply('retry') )->category,
            'deadline', 'late reply cannot retry ambiguously' );
        T2->is( $http->count, 1, 'no second initial POST' );
        $interaction->close;
        $rest->close;
        ( $interaction, $rest, $http, $clock ) = context( received_at => -4 );
        T2->is( error( $interaction->reply('late') )->category,
            'deadline', 'delayed event dispatch retains receive deadline' );
        T2->is( $http->count, 0, 'expired event performs no HTTP' );
        $interaction->close;
        $rest->close;
    }
);

T2->subtest(
    'token expires after fifteen minutes',
    sub {
        my ( $interaction, $rest, $http, $clock ) = context();
        $interaction->defer;
        $http->respond( response( 204, undef ) );

        # Check the last usable instant and then cross the token expiry boundary.
        $clock->advance(899.9);
        my $response_future = $interaction->followup('last');
        $http->respond( response( 200, {} ) );
        T2->ok( $response_future->is_done, 'followup within token window' );
        $clock->advance(0.1);
        T2->is( error( $interaction->followup('expired') )->category, 'expired', 'expired token guarded' );
        T2->is( $http->count, 2, 'no expired network request' );
        $interaction->close;
        $rest->close;
    }
);

T2->subtest(
    'options, resolved entities, components and autocomplete',
    sub {
        # Select a nested command and resolve a large string ID without additional I/O.
        my ( $interaction, $rest, $http ) = context(
            payload => {
                data => {
                    name => 'admin',
                    type => 1,
                    options => [
                        {
                            name => 'users',
                            type => 2,
                            options => [
                                {
                                    name => 'lookup',
                                    type => 1,
                                    options => [ { name => 'user', type => 6, value => '18446744073709551615' } ]
                                }
                            ]
                        }
                    ],
                    resolved => { users => { '18446744073709551615' => { id => '18446744073709551615' } } }
                }
            }
        );
        T2->is( $interaction->command_path, [ 'users', 'lookup' ], 'nested command path' );
        T2->is( $interaction->option('user'), '18446744073709551615', 'snowflake option remains a string' );
        T2->is( $interaction->resolved( 'users', $interaction->option('user') )->{id},
            '18446744073709551615', 'resolved entity' );
        $interaction->close;
        $rest->close;
        ( $interaction, $rest, $http ) = context(
            payload => {
                type => 3,
                data => { custom_id => 'select', component_type => 3, values => [ 'a', 'b' ] }
            }
        );

        # Component selections use their native values and may defer a message update.
        T2->is( $interaction->values, [ 'a', 'b' ], 'select values' );
        $interaction->defer( update => 1 );
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{type},
            6, 'component defer update' );
        $http->respond( response( 204, undef ) );
        $interaction->close;
        $rest->close;
        ( $interaction, $rest, $http ) = context(
            payload => {
                type => 4,
                data => {
                    name => 'search',
                    type => 1,
                    options => [ { name => 'query', type => 3, value => 'p', focused => JSON::PP::true } ]
                }
            }
        );

        # Autocomplete uses choices rather than a normal message response.
        T2->is( $interaction->focused->{value}, 'p', 'focused value' );
        T2->is( error( $interaction->reply('invalid') )->category,
            'state', 'autocomplete cannot send normal reply' );
        $interaction->autocomplete( [ { name => 'Perl', value => 'perl' } ] );
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{type}, 8,
            'autocomplete callback' );
        $http->respond( response( 204, undef ) );
        $interaction->close;
        $rest->close;
    }
);

T2->subtest(
    'a failed initial response is not replayed',
    sub {
        my ( $interaction, $rest, $http ) = context();

        # An ambiguous timeout must remain non-retryable and omit private transport details.
        my $response_future = $interaction->reply('first');
        $http->call->{future}->fail( 'FAKE_INTERACTION_TOKEN failed', 'timeout' );
        T2->is( error($response_future)->category, 'timeout', 'transport error categorized' );
        T2->unlike(
            join( ' ', $response_future->failure ),
            qr/FAKE_INTERACTION_TOKEN/,
            'transport exception sanitized'
        );
        T2->is( error( $interaction->reply('again') )->category, 'state', 'ambiguous initial POST not replayed' );
        $interaction->close;
        $rest->close;
    }
);

T2->subtest(
    'cancelling an initial reply cancels I/O without allowing another reply',
    sub {
        my ( $interaction, $rest, $http, $clock ) = context();
        my $reply = $interaction->reply('first');
        my $request = $http->call->{future};

        # Cancellation cannot prove that Discord did not receive the first callback.
        $reply->cancel;
        T2->ok( $reply->is_cancelled, 'the caller reply Future is cancelled' );
        T2->ok( $request->is_cancelled, 'cancellation reaches the HTTP operation' );
        T2->is( error( $interaction->reply('again') )->category,
            'state', 'another initial reply remains forbidden' );
        T2->is( $http->count, 1, 'no ambiguous duplicate callback is sent' );
        T2->is( $clock->timer_count, 0, 'the initial response timer is released' );
        $interaction->close->get;
        $rest->close->get;
    }
);

T2->done_testing;
