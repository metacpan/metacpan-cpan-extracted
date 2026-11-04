use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use Future;
use Crypt::PK::Ed25519;
use lib 't/lib';
use TestDiscordREST qw(client response);
use TestDiscordGateway qw(rig ready_socket);
use TestDiscordExamples qw(load_example);

my $next_id = 100;

sub payload {
    my ( $name, %extra ) = @_;
    return {
        id => '' . ++$next_id,
        application_id => '456',
        token => 'FAKE_EXAMPLE_TOKEN',
        type => 2,
        guild_id => '789',
        channel_id => '321',
        data => { name => $name, type => 1 },
        %extra,
    };
}

sub setup {
    my ($example) = @_;
    my ( $rest, $http, $rest_clock ) = client();
    my $gateway = rig( loop => $rest->loop );
    my $clock = $gateway->{clock};
    my @errors;

    # Gateway receipt and interaction deadlines use the same controlled clock.
    my $bot = load_example(
        "examples/$example.pl",
        rest => $rest,
        loop => $rest->loop,
        gateway => $gateway->{gateway},
        application_id => '456',
        interaction_options => {
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) },
        },
        on_error => sub { push @errors, $_[0] },
    );
    T2->is( $http->count, 0, "$example declares handlers without network I/O" );

    # Complete a real Client startup without opening an external connection.
    my $started = $bot->start;
    my $socket = ready_socket( $gateway, interval => 60_000 );
    $gateway->{clock}->run_deferred;
    T2->ok( $started->is_done, "$example starts its Gateway" );
    T2->is( $http->count, 0, 'startup leaves command deployment explicit' );
    return {
        bot => $bot,
        rest => $rest,
        http => $http,
        clock => $clock,
        errors => \@errors,
        rest_clock => $rest_clock,
        gateway => $gateway,
        socket => $socket,
        sequence => 42,
    };
}

sub deliver {
    my ( $fixture, $interaction ) = @_;

    # Simulate an incoming Discord frame, keeping Client event routing in the test.
    $fixture->{socket}->emit(
        {
            op => 0,
            s => ++$fixture->{sequence},
            t => 'INTERACTION_CREATE',
            d => $interaction,
        }
    );
    $fixture->{gateway}{clock}->run_deferred;
}

sub response_body {
    my ($http) = @_;
    return JSON::PP->new->utf8->decode( $http->call->{request}->content );
}

sub close_clients {
    my ($fixture) = @_;
    T2->is( scalar( @{ $fixture->{errors} } ), 0, 'no handler errors' );

    # Close the facade and caller-owned REST client before checking both timer registries.
    $fixture->{bot}->close->get;
    $fixture->{rest}->close->get;
    T2->is( $fixture->{clock}->timer_count, 0, 'no interaction or Gateway timers after shutdown' );
    T2->is( $fixture->{rest_clock}->timer_count, 0, 'no REST timers after shutdown' );
}

T2->subtest(
    'minimal ping example replies without UI or deployment',
    sub {
        my $fixture = setup('ping');
        my ( $bot, $http ) = @{$fixture}{qw(bot http)};

        # The smallest example declares only the command that the reader runs.
        T2->is( [ map { $_->{name} } @{ $bot->commands->definitions } ], ['ping'], 'one command' );
        deliver( $fixture, payload('ping') );
        T2->is( response_body($http), { type => 4, data => { content => 'Pong!' } }, 'plain reply' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'reply completes' );
        close_clients($fixture);
    }
);

T2->subtest(
    'named greeting handler receives a required argument without enabling mentions',
    sub {
        my $fixture = setup('commands');
        my ( $bot, $http ) = @{$fixture}{qw(bot http)};
        deliver(
            $fixture,
            payload(
                'greet',
                data => {
                    name => 'greet',
                    type => 1,
                    options => [ { name => 'name', type => 3, value => '@everyone' } ],
                }
            )
        );

        # User input is displayed as text, without turning it into a Discord mention.
        T2->is( response_body($http)->{data}{content}, 'Hello, @everyone!', 'argument reaches handler' );
        T2->is( response_body($http)->{data}{allowed_mentions}, { parse => [] }, 'mentions disabled' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'greeting completes' );
        close_clients($fixture);
    }
);

T2->subtest(
    'button helper and component handler work together',
    sub {
        my $fixture = setup('components');
        my ( $bot, $http ) = @{$fixture}{qw(bot http)};
        deliver( $fixture, payload('button') );

        # Verify the generated wire payload, then deliver the matching click.
        T2->is( response_body($http)->{data}{components}[0]{type}, 1, 'message contains an Action Row' );
        T2->is( response_body($http)->{data}{components}[0]{components}[0]{custom_id}, 'hello', 'button ID' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'command completes' );

        deliver(
            $fixture,
            payload(
                '',
                type => 3,
                data => {
                    custom_id => 'hello',
                    component_type => 2,
                }
            )
        );
        T2->is(
            response_body($http),
            { type => 4, data => { content => 'Hello!', flags => 64 } },
            'button replies privately'
        );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 2, 'click completes' );
        close_clients($fixture);
    }
);

T2->subtest(
    'form helper and named field lookup work together',
    sub {
        my $fixture = setup('modal');
        my ( $bot, $http ) = @{$fixture}{qw(bot http)};
        deliver( $fixture, payload('feedback') );

        # Opening the current Label-based modal is the command acknowledgement.
        T2->is( response_body($http)->{type}, 9, 'modal callback type' );
        my $field = response_body($http)->{data}{components}[0];
        T2->is( $field->{type}, 18, 'input is wrapped in a Label' );
        T2->is( $field->{component}{style}, 2, 'paragraph style uses the documented numeric value' );
        T2->is( $field->{component}{custom_id}, 'note', 'input name survives serialization' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'modal opens' );

        deliver(
            $fixture,
            payload(
                '',
                type => 5,
                data => {
                    custom_id => 'feedback_form',
                    components => [
                        {
                            type => 18,
                            id => 1,
                            component => { type => 4, id => 2, custom_id => 'note', value => '@everyone' },
                        }
                    ],
                }
            )
        );
        T2->is(
            response_body($http)->{data}{content},
            'Thanks for your feedback: @everyone',
            'form value reaches handler'
        );
        T2->is( response_body($http)->{data}{flags}, 64, 'feedback is private' );
        T2->is( response_body($http)->{data}{allowed_mentions}, { parse => [] }, 'mentions disabled' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 2, 'submission completes' );
        close_clients($fixture);
    }
);

T2->subtest(
    'channel listing defers before REST and refuses use outside a server',
    sub {
        my $fixture = setup('channels');
        my ( $bot, $http ) = @{$fixture}{qw(bot http)};
        deliver( $fixture, payload('channels') );

        # A slow REST request must start only after the initial acknowledgement succeeds.
        T2->is( response_body($http)->{type}, 5, 'reply deferred' );
        T2->is( $http->count, 1, 'no early channel request' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{pending}, 1, 'acknowledged handler waits for channel results' );
        T2->like( $http->call->{request}->uri->path, qr{/guilds/789/channels$}, 'current guild requested' );
        $http->respond( response( 200, [ { id => '321', name => 'general' }, { id => '322', name => 'help' } ] ) );
        T2->is( response_body($http)->{content}, 'Channels: general, help', 'model names displayed' );
        T2->is( response_body($http)->{allowed_mentions}, { parse => [] }, 'channel names cannot mention' );
        $http->respond( response( 200, { id => '800' } ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'channel listing completes' );

        # A DM gets a useful reply without requesting a guild or leaving the handler pending.
        my $previous_calls = $http->count;
        deliver( $fixture, payload( 'channels', guild_id => undef ) );
        T2->is( response_body($http)->{data}{content}, 'Use this command in a server.', 'DM explanation' );
        T2->is( $http->count, $previous_calls + 1, 'only one response request' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 2, 'DM response completes' );
        close_clients($fixture);
    }
);

T2->subtest(
    'Future and optional async/await examples complete work and cancel it on shutdown',
    sub {
        my $has_async_await = eval {
            require Future::AsyncAwait;
            1;
        };
        for my $example ( 'workflow', 'workflow-await' ) {
            T2->subtest(
                $example,
                sub {
                    T2->skip_all('Install optional Future::AsyncAwait to exercise this example')
                        if $example eq 'workflow-await' && !$has_async_await;
                    my $fixture = setup($example);
                    my ( $bot, $http, $clock ) = @{$fixture}{qw(bot http clock)};
                    my $waiting;
                    no warnings 'redefine';
                    local *IO::Async::Loop::delay_future = sub {
                        my ( $loop, %options ) = @_;
                        return $waiting = $clock->delay( $options{after} );
                    };

                    # Both implementations acknowledge, yield, then edit the deferred original.
                    deliver( $fixture, payload('report') );
                    T2->is( response_body($http), { type => 5, data => { flags => 64 } }, 'private deferral' );
                    $http->respond( response( 204, undef ) );
                    T2->is( $http->count, 1, 'work yields before replying' );
                    T2->is( $bot->interactions->stats->{pending}, 1, 'handler stays active after deferral' );
                    $clock->advance(1);
                    T2->is( $http->call->{request}->method, 'PATCH', 'deferred reply edits original' );
                    T2->is( response_body($http)->{content}, 'Your report is ready.', 'same completion text' );
                    $http->respond( response( 200, { id => '800' } ) );
                    T2->is( $bot->interactions->stats->{handled}, 1, 'workflow completes' );
                    T2->is( $bot->interactions->stats->{pending}, 0, 'completed workflow releases its slot' );

                    # Shut down during a second report, after its initial acknowledgement.
                    deliver( $fixture, payload('report') );
                    $http->respond( response( 204, undef ) );
                    T2->ok( !$waiting->is_ready, 'next report is still waiting' );
                    T2->is( $bot->interactions->stats->{pending}, 1, 'client retains the active workflow' );
                    my $calls_before_close = $http->count;
                    $bot->close->get;
                    T2->ok( $waiting->is_cancelled, 'shutdown cancels the waiting Future' );
                    T2->is( $bot->interactions->stats->{pending}, 0, 'shutdown releases the handler' );
                    $clock->advance(30);
                    T2->is( $http->count, $calls_before_close,
                        'cancelled workflow never edits the deferred reply' );
                    close_clients($fixture);
                }
            );
        }
    }
);

T2->subtest(
    'deployment script loads the example and explicitly syncs only the selected guild',
    sub {
        my ( $rest, $http ) = client();
        my $gateway = rig( loop => $rest->loop );
        my $constructor = Discord::Client->can('new');
        my $bot;

        # The script's normal get() calls wait on a real Future; fake HTTP resolves inline.
        no warnings 'redefine';
        local *TestDiscordREST::HTTP::do_request = sub {
            my ( $transport, %arguments ) = @_;
            push @{ $transport->{calls} }, \%arguments;
            return Future->done( response( 200, [] ) );
        };
        local *Discord::Client::new = sub {
            my ( $class, %arguments ) = @_;
            return $bot = $constructor->(
                $class, %arguments,
                rest => $rest,
                gateway => $gateway->{gateway},
                loop => $rest->loop,
                application_id => '456'
            );
        };
        local @ARGV = ('examples/ping.pl');
        local $ENV{TEST_GUILD_ID} = '789';

        T2->try_ok(
            sub {
                do './examples/sync-commands.pl';
                die $@ if $@;
            },
            'deployment script completes'
        );
        T2->is( $http->count, 1, 'one explicit deployment; no Gateway discovery' );
        T2->is( $http->call->{request}->method, 'PUT', 'bulk command replacement' );
        T2->like( $http->call->{request}->uri->path, qr{/applications/456/guilds/789/commands$}, 'guild scope' );
        T2->is( response_body($http)->[0]{name}, 'ping', 'uses the example declaration' );
        T2->ok( $bot->completion->is_ready, 'deployment closes its Gateway resources' );
        $rest->close->get;
    }
);

T2->subtest(
    'PSGI example replies to signed ping and rejects tampering',
    sub {
        my $signer = Crypt::PK::Ed25519->new->generate_key;
        local $ENV{DISCORD_PUBLIC_KEY} = unpack( 'H*', $signer->export_key_raw('public') );
        my $app = do './examples/http-interactions.psgi';
        T2->ref_ok( $app, 'CODE', 'example supplies a PSGI application' );

        for my $case ( [ { type => 1 }, 1 ], [ payload('ping'), 4 ] ) {

            # Sign exactly the bytes delivered to the actual PSGI application.
            my $body = JSON::PP->new->utf8->encode( $case->[0] );
            my $timestamp = '' . time;
            my $signature = unpack( 'H*', $signer->sign_message( $timestamp . $body ) );
            open my $input, '<', \$body or die 'scalar input';
            my $env = {
                REQUEST_METHOD => 'POST',
                CONTENT_LENGTH => length($body),
                'psgi.input' => $input,
                'psgi.streaming' => 0,
                HTTP_X_SIGNATURE_TIMESTAMP => $timestamp,
                HTTP_X_SIGNATURE_ED25519 => $signature,
            };
            my $response = $app->($env);
            T2->is( $response->[0], 200, 'signed request accepted' );
            my $reply = JSON::PP->new->utf8->decode( $response->[2][0] );
            T2->is( $reply->{type}, $case->[1], 'correct response type' );
            T2->is( $reply->{data}{content}, 'Pong!', 'ping reply' ) if $case->[1] == 4;

            my $tampered = $body . ' ';
            open $input, '<', \$tampered or die 'scalar input';
            T2->is( $app->( { %$env, CONTENT_LENGTH => length($tampered), 'psgi.input' => $input } )->[0],
                401, 'unsigned modification rejected' );
        }
    }
);

T2->done_testing;
