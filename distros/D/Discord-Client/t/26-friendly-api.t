use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use Future;
use lib 't/lib';
use TestDiscordREST qw(client response);
use TestDiscordGateway qw(rig ready_socket);
use TestDiscordExamples qw(load_example);
use Discord::Client;
use Discord::Client::Interaction;
use Discord::Client::UI qw(row button text_input modal);

sub setup {
    my ( $rest, $http, $clock ) = client();
    my $gateway = rig( loop => $rest->loop );
    my @errors;
    my $bot = Discord::Client->new(
        rest => $rest,
        loop => $rest->loop,
        gateway => $gateway->{gateway},
        on_error => sub { push @errors, $_[0] },
    );

    # Complete startup through Gateway frames before returning an actionable client fixture.
    my $started = $bot->start;
    my $socket = ready_socket($gateway);
    $gateway->{clock}->run_deferred;
    $started->get;
    return ( $bot, $rest, $http, $gateway, $socket, \@errors );
}

sub message_data {
    return {
        id => '900',
        channel_id => '321',
        content => '!ping',
        author => { id => '234', username => 'tester', bot => JSON::PP::false },
        unknown_field => { value => 'retained' },
    };
}

sub dispatch_message {
    my ( $gateway, $socket, $data, $sequence ) = @_;
    $socket->emit( { op => 0, s => $sequence // 43, t => 'MESSAGE_CREATE', d => $data } );
    $gateway->{clock}->run_deferred;
}

T2->subtest(
    'message handlers receive an actionable snapshot and raw events remain available',
    sub {
        my ( $bot, $rest, $http, $gateway, $socket, $errors ) = setup();
        my ( $message, $received_bot, $raw_event );

        # The high-level handler returns its reply Future for ordinary SDK tracking.
        T2->ref_is(
            $bot->on_message(
                sub {
                    ( $message, $received_bot ) = @_;
                    return $message->reply('Pong!');
                }
            ),
            $bot,
            'registration returns the client'
        );
        $bot->on( MESSAGE_CREATE => sub { ($raw_event) = @_ } );
        dispatch_message( $gateway, $socket, message_data() );

        T2->isa_ok( $message, 'Discord::Client::Model::Message' );
        T2->ref_is( $received_bot, $bot, 'client is available to the handler' );
        T2->is( $message->author->username, 'tester', 'author is a User snapshot' );
        T2->is( $message->channel->id, '321', 'channel is a reference without a fetch' );
        T2->is( $http->count, 1, 'reply needs only one request and no cache' );
        T2->like( $http->call->{request}->uri->path, qr{/channels/321/messages$}, 'reply targets message channel' );
        my $reply = JSON::PP->new->utf8->decode( $http->call->{request}->content );
        T2->is( $reply->{content}, 'Pong!', 'reply content' );
        T2->is( $reply->{message_reference}{message_id}, '900', 'reply references the received message' );
        T2->is( $raw_event->{unknown_field}, { value => 'retained' }, 'raw event retains unknown fields' );
        $raw_event->{content} = 'changed by raw handler';
        T2->is( $message->content, '!ping', 'snapshot is isolated from raw event mutation' );
        T2->is( $bot->stats->{callbacks}, 1, 'pending returned Future is tracked' );
        $http->respond( response( 200, { id => '901', channel_id => '321', content => 'Pong!' } ) );
        T2->is( $bot->stats->{callbacks}, 0, 'completed reply releases handler capacity' );

        # Channel references share the client's REST transport without hidden I/O.
        my $sent = $message->channel->send('Hello channel');
        T2->is( $http->count, 2, 'channel sends directly without a preliminary fetch' );
        $http->respond( response( 200, { id => '902', channel_id => '321', content => 'Hello channel' } ) );
        T2->is( $sent->get->content, 'Hello channel', 'send returns a Message snapshot' );
        T2->is( scalar(@$errors), 0, 'successful handlers report no errors' );
        $bot->close->get;
        $rest->close->get;
    }
);

T2->subtest(
    'message handler failures are isolated and shutdown cancels pending work',
    sub {
        my ( $bot, $rest, $http, $gateway, $socket, $errors ) = setup();
        my $calls = 0;
        my $pending = Future->new;

        # A failing handler must not prevent the next listener from seeing the event.
        $bot->on_message( sub { die 'private handler details' } );
        $bot->on_message(
            sub {
                ++$calls;
                return $pending;
            }
        );
        dispatch_message( $gateway, $socket, message_data() );
        T2->is( $calls, 1, 'next listener still runs' );
        T2->is( $errors->[0]->category, 'handler', 'failure reaches the existing error hook' );
        T2->unlike( $errors->[0]->message, qr/private handler details/, 'error excludes arbitrary exception text' );
        T2->is( $http->count, 0, 'registration and wrapping perform no HTTP' );
        $bot->close->get;
        T2->ok( $pending->is_cancelled, 'shutdown cancels returned handler Future' );
        $rest->close->get;

        # Failed Futures follow the same failure isolation path as raw listeners.
        ( $bot, $rest, $http, $gateway, $socket, $errors ) = setup();
        $bot->on_message( sub { return Future->fail( 'private details', 'example' ) } );
        dispatch_message( $gateway, $socket, message_data() );
        T2->is( $errors->[0]->category, 'handler', 'failed Future reaches error hook' );
        T2->is( $bot->stats->{callbacks}, 0, 'failed Future releases capacity' );
        $bot->close->get;
        $rest->close->get;
    }
);

T2->subtest(
    'actual message example ignores bots and unrelated messages, and replies to ping',
    sub {
        my ( $rest, $http ) = client();
        my $gateway = rig( loop => $rest->loop );
        my $bot = load_example(
            'examples/messages.pl',
            rest => $rest,
            loop => $rest->loop,
            gateway => $gateway->{gateway}
        );
        my $started = $bot->start;
        my $socket = ready_socket($gateway);
        $gateway->{clock}->run_deferred;
        $started->get;

        # Neither another bot nor unrelated content should generate a response.
        my $data = message_data();
        $data->{author}{bot} = JSON::PP::true;
        dispatch_message( $gateway, $socket, $data, 43 );
        $data = message_data();
        $data->{content} = 'hello';
        dispatch_message( $gateway, $socket, $data, 44 );
        T2->is( $http->count, 0, 'ignored messages produce no HTTP requests' );

        dispatch_message( $gateway, $socket, message_data(), 45 );
        T2->is( $http->count, 1, 'human ping triggers one reply' );
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{content},
            'Pong!', 'example reply' );
        $http->respond( response( 200, { id => '901', channel_id => '321', content => 'Pong!' } ) );
        $bot->close->get;
        $rest->close->get;
    }
);

T2->subtest(
    'UI declarations encode Discord styles, layouts and genuine JSON booleans',
    sub {
        # A Perl boolean must serialize as JSON boolean, rather than the number one.
        my $controls = row( button( 'confirm', label => 'Confirm', style => 'success', disabled => 1 ) );
        my $json = JSON::PP->new->encode($controls);
        T2->like( $json, qr/"disabled":true/, 'disabled is a JSON boolean' );
        T2->is( $controls->{components}[0]{style}, 3, 'named success style' );
        my $form = modal(
            'form',
            title => 'Feedback',
            fields =>
                [ text_input( 'note', label => 'Note', style => 'paragraph', required => 0, max_length => 100 ), ]
        );
        T2->is( $form->{components}[0]{type}, 18, 'modal uses Label layout' );
        T2->like( JSON::PP->new->encode($form), qr/"required":false/, 'optional input is a JSON boolean' );
        T2->is( $form->{components}[0]{component}{style}, 2, 'paragraph style' );

        # Caller-supplied native select JSON remains usable inside an Action Row.
        my $select = { type => 3, custom_id => 'color', options => [ { label => 'Blue', value => 'blue' } ] };
        T2->is( row($select)->{components}, [$select], 'row accepts a native select' );
    }
);

T2->subtest(
    'invalid UI declarations fail locally before any response can be sent',
    sub {
        my $field = text_input( 'note', label => 'Note' );
        for my $case (
            [ 'empty button ID', sub { button( '', label => 'Press' ) }, qr/Button ID/ ],
            [ 'oversized label', sub { button( 'id', label => 'x' x 81 ) }, qr/Button label/ ],
            [ 'unknown style', sub { button( 'id', label => 'Press', style => 'blue' ) }, qr/style/ ],
            [
                'incompatible URL',
                sub { button( 'id', label => 'Press', url => 'https:\/\/example.com' ) },
                qr/native JSON/
            ],
            [ 'empty row', sub { row() }, qr/action row/ ],
            [
                'six buttons',
                sub {
                    row( map { button( "id$_", label => 'Press' ) } 1 .. 6 );
                },
                qr/action row/
            ],
            [
                'mixed select and button',
                sub { row( { type => 3 }, button( 'id', label => 'Press' ) ) },
                qr/select menu/
            ],
            [ 'text input in message', sub { row( { type => 4 } ) }, qr/component/ ],
            [
                'inverted input bounds',
                sub { text_input( 'id', label => 'Note', min_length => 5, max_length => 4 ) },
                qr/min_length/
            ],
            [ 'empty modal', sub { modal( 'id', title => 'Form', fields => [] ) }, qr/fields/ ],
            [
                'duplicate fields',
                sub { modal( 'id', title => 'Form', fields => [ $field, $field ] ) },
                qr/Duplicate/
            ],
            )
        {
            my ( $name, $declare, $reason ) = @$case;
            T2->like( T2->dies($declare), $reason, "$name rejected with a useful reason" );
        }
    }
);

T2->subtest(
    'named modal fields handle Labels and legacy rows without altering raw input',
    sub {
        my $clock = bless { now => 0, timers => [] }, 'TestDiscordREST::Clock';
        my $raw = {
            id => '100',
            application_id => '456',
            token => 'FAKE_FIELD_TOKEN',
            type => 5,
            data => {
                custom_id => 'form',
                components => [
                    { type => 18, component => { type => 4, custom_id => 'empty', value => '' } },
                    { type => 1, components => [ { type => 4, custom_id => 'legacy', value => 'old form' } ] },
                    { type => 18, component => { type => 3, custom_id => 'selection', values => ['blue'] } },
                    { type => 99, unknown => 'retained' },
                ]
            },
        };
        my $context = Discord::Client::Interaction->new(
            payload => $raw,
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) }
        );

        # Empty text differs from a missing input, and unwrapped input stays accessible.
        T2->is( $context->field('empty'), '', 'empty string preserved' );
        T2->is( $context->field('legacy'), 'old form', 'legacy Action Row input found' );
        T2->is( $context->field('missing'), undef, 'missing input returns undef' );
        T2->is( $context->field('selection'), undef, 'select values are not mistaken for text' );
        T2->is( $context->raw->{data}{components}[3]{unknown}, 'retained', 'unknown fields preserved' );
        $context->close;
        $raw->{type} = 2;
        $context = Discord::Client::Interaction->new(
            payload => $raw,
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) }
        );
        T2->is( $context->field('empty'), undef, 'non-modal interaction has no text fields' );
        $context->close;
    }
);

T2->done_testing;
