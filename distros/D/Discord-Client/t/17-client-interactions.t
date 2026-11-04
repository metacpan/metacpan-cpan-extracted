use v5.26;
use warnings;
use Test2::V1;
use JSON::PP;
use Future;
use lib 't/lib';
use TestDiscordREST qw(client response);
use TestDiscordGateway qw(rig ready_socket);
use Discord::Client;

sub setup {
    my (%gateway_options) = @_;
    my ( $rest, $http ) = client();
    my $rig = rig( loop => $rest->loop, %gateway_options );
    my $clock = $rig->{clock};
    my @errors;

    # Use the Gateway receipt clock for interaction deadlines as well as protocol timing.
    my $bot = Discord::Client->new(
        token => 'FAKE_GATEWAY_TOKEN',
        loop => $rest->loop,
        rest => $rest,
        gateway => $rig->{gateway},
        application_id => '456',
        interaction_options => { clock => sub { $clock->{now} }, delay => sub { $clock->delay( $_[0] ) } },
        on_error => sub { push @errors, $_[0] }
    );
    return ( $bot, $rest, $http, $rig, \@errors );
}

sub payload {
    my ( $id, %extra ) = @_;
    return {
        id => "$id",
        application_id => '456',
        token => 'FAKE_INTERACTION_TOKEN',
        type => 2,
        data => { name => 'ping', type => 1 },
        %extra
    };
}

T2->subtest(
    'Gateway slash command and button, without implicit sync',
    sub {
        my ( $bot, $rest, $http, $rig, $errors ) = setup();
        my $calls = 0;
        $bot->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply(
                    {
                        content => 'Pong!',
                        components => [
                            {
                                type => 1,
                                components => [
                                    {
                                        type => 2,
                                        style => 1,
                                        label => 'Press',
                                        custom_id => 'ping_button'
                                    }
                                ]
                            }
                        ]
                    }
                );
            }
        );
        $bot->component( ping_button => sub { $_[0]->reply( 'Button pressed', ephemeral => 1 ) } );
        T2->is( $http->count, 0, 'construct/declaration performs no REST' );

        # Startup opens the Gateway without deploying command declarations.
        my $started = $bot->start;
        my $websocket = ready_socket( $rig, interval => 60_000 );
        $rig->{clock}->run_deferred;
        T2->ok( $started->is_done, 'facade starts Gateway' );
        T2->is( $http->count, 0, 'startup never synchronizes commands' );

        # Receive the slash command through normal Gateway routing and acknowledge its reply.
        $websocket->emit( { op => 0, s => 43, t => 'INTERACTION_CREATE', d => payload(100) } );
        $rig->{clock}->run_deferred;
        T2->is( $calls, 1, 'slash handler called' );
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{data}{content},
            'Pong!', 'slash reply' );
        $http->respond( response( 204, undef ) );
        $websocket->emit(
            {
                op => 0,
                s => 44,
                t => 'INTERACTION_CREATE',
                d => payload(
                    101,
                    type => 3,
                    data => { custom_id => 'ping_button', component_type => 2 }
                )
            }
        );
        $rig->{clock}->run_deferred;
        my $button = JSON::PP->new->utf8->decode( $http->call->{request}->content );
        T2->is( $button->{data}{flags}, 64, 'component ephemeral response' );
        $http->respond( response( 204, undef ) );

        # Replay the original interaction after both replies to check duplicate protection.
        $websocket->emit( { op => 0, s => 45, t => 'INTERACTION_CREATE', d => payload(100) } );
        $rig->{clock}->run_deferred;
        T2->is( $calls, 1, 'Resume replay cannot invoke or reply twice' );
        T2->is( $http->count, 2, 'replay performs no HTTP' );
        T2->is( $bot->interactions->stats->{duplicates}, 1, 'replay diagnostic' );
        T2->is( scalar(@$errors), 0, 'no handler errors' );
        $bot->close->get;
        $rest->close;
        T2->is( $rig->{clock}->timer_count, 0, 'facade shutdown clears timers' );
    }
);

T2->subtest(
    'autocomplete and subcommand handlers send the expected responses',
    sub {
        my ( $bot, $rest, $http, $rig ) = setup();
        my $reply;

        # Register handlers as a bot would, then receive their events through the Gateway.
        $bot->command(
            search => description => 'Search',
            handler => sub { },
            options => [
                {
                    name => 'query',
                    description => 'Query',
                    type => 'string',
                    autocomplete => sub {
                        return Future->done( [ { name => 'Perl', value => 'perl' } ] );
                    }
                }
            ]
        );
        my $started = $bot->start;
        my $websocket = ready_socket( $rig, interval => 60_000 );
        $rig->{clock}->run_deferred;
        T2->ok( $started->is_done, 'client starts' );
        $websocket->emit(
            {
                op => 0,
                s => 43,
                t => 'INTERACTION_CREATE',
                d => payload(
                    200,
                    type => 4,
                    data => {
                        name => 'search',
                        type => 1,
                        options => [ { name => 'query', type => 3, value => 'p', focused => JSON::PP::true } ]
                    }
                )
            }
        );
        $rig->{clock}->run_deferred;
        T2->is(
            JSON::PP->new->utf8->decode( $http->call->{request}->content ),
            { type => 8, data => { choices => [ { name => 'Perl', value => 'perl' } ] } },
            'Future-based autocomplete result'
        );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'autocomplete work completes' );
        $bot->command(
            admin => description => 'Admin',
            options => [
                {
                    name => 'show',
                    description => 'Show',
                    type => 'subcommand',
                    handler => sub { return $reply = $_[0]->reply( $_[0]->option('value') ) },
                    options => [ { name => 'value', description => 'Value', type => 'string', required => 1 } ]
                }
            ]
        );
        $websocket->emit(
            {
                op => 0,
                s => 44,
                t => 'INTERACTION_CREATE',
                d => payload(
                    201,
                    data => {
                        name => 'admin',
                        type => 1,
                        options => [
                            {
                                name => 'show',
                                type => 1,
                                options => [ { name => 'value', type => 3, value => 'ok' } ]
                            }
                        ]
                    }
                )
            }
        );
        $rig->{clock}->run_deferred;
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{data}{content},
            'ok', 'nested handler receives option' );
        T2->isa_ok( $reply, 'Future' );
        T2->ok( !$reply->is_ready, 'reply waits for HTTP response' );
        $http->respond( response( 204, undef ) );
        T2->ok( $reply->is_done, 'subcommand reply completes' );
        T2->is( $bot->interactions->stats->{handled}, 2, 'client tracks both completed handlers' );
        T2->is( $bot->interactions->stats->{pending}, 0, 'no pending interaction work' );
        $bot->close;
        $rest->close;
    }
);

T2->subtest(
    'handler exceptions are sanitized and released at the response deadline',
    sub {
        my ( $bot, $rest, $http, $rig, $errors ) = setup();
        $bot->command(
            ping => description => 'Ping',
            handler => sub { die 'FAKE_INTERACTION_TOKEN secret' }
        );

        # Deliver a failing command through the same event path as a successful command.
        my $started = $bot->start;
        my $websocket = ready_socket( $rig, interval => 60_000 );
        $rig->{clock}->run_deferred;
        T2->ok( $started->is_done, 'client starts' );
        $websocket->emit( { op => 0, s => 43, t => 'INTERACTION_CREATE', d => payload(300) } );
        $rig->{clock}->run_deferred;
        T2->is( scalar(@$errors), 1, 'thrown error reported' );
        T2->unlike( join( ' ', @$errors ), qr/FAKE_INTERACTION_TOKEN/, 'error text sanitized' );
        T2->is( $bot->interactions->stats->{pending}, 1, 'unanswered interaction waits for its deadline' );
        $rig->{clock}->advance(3);
        T2->is( scalar(@$errors), 1, 'deadline does not report the same handler error again' );
        T2->is( $http->count, 0, 'failed handler sends no response' );
        T2->is( $bot->interactions->stats->{pending}, 0, 'failed work removed' );
        $bot->close;
        $rest->close;
    }
);

T2->subtest(
    'acknowledged background work allows heartbeats and later commands',
    sub {
        my ( $bot, $rest, $http, $rig, $errors ) = setup( max_handlers => 1 );
        my $work = Future->new;
        my ( $report, $ping );

        # Return the whole workflow so the client retains work beyond acknowledgement.
        $bot->command(
            report => description => 'Report',
            handler => sub {
                my ($interaction) = @_;
                return $report = $interaction->defer->then(
                    sub {
                        return $work;
                    }
                )->then(
                    sub {
                        return $interaction->reply('Report ready.');
                    }
                );
            }
        );
        $bot->command(
            ping => description => 'Ping',
            handler => sub {
                return $ping = $_[0]->reply('Pong!');
            }
        );
        my $started = $bot->start;
        my $socket = ready_socket($rig);
        $rig->{clock}->run_deferred;
        T2->ok( $started->is_done, 'client starts' );
        $socket->emit(
            {
                op => 0,
                s => 43,
                t => 'INTERACTION_CREATE',
                d => payload( 400, data => { name => 'report', type => 1 } )
            }
        );
        $rig->{clock}->run_deferred;
        $http->respond( response( 204, undef ) );
        T2->ok( !$report->is_ready, 'report remains pending after acknowledgement' );
        T2->is( $bot->interactions->stats->{pending}, 1, 'client tracks the report workflow' );

        # Slow command work must leave both the protocol and command delivery active.
        $rig->{clock}->advance(0.25);
        T2->is( $socket->{frames}[-1]{op}, 1, 'heartbeat is sent while report is pending' );
        $socket->emit( { op => 11 } );
        $socket->emit( { op => 0, s => 44, t => 'INTERACTION_CREATE', d => payload(401) } );
        $rig->{clock}->run_deferred;
        T2->is( $http->count, 2, 'later command sends a reply before the report finishes' );
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{data}{content},
            'Pong!', 'later command reaches its registered handler' );
        $http->respond( response( 204, undef ) );
        T2->ok( $ping->is_done, 'later command reply completes' );
        T2->ok( !$report->is_ready, 'later command does not finish the report' );

        # Complete the application Future and inspect the final deferred reply.
        $work->done;
        T2->is( $http->call->{request}->method, 'PATCH', 'report edits its deferred response' );
        T2->is(
            JSON::PP->new->utf8->decode( $http->call->{request}->content )->{content},
            'Report ready.',
            'report sends its final content'
        );
        $http->respond( response( 200, { id => '800' } ) );
        T2->ok( $report->is_done, 'returned report Future completes' );
        T2->is( $bot->interactions->stats->{pending}, 0, 'both command workflows are released' );
        T2->is( scalar(@$errors), 0, 'no client errors' );
        $bot->close->get;
        $rest->close->get;
        T2->is( $rig->{clock}->timer_count, 0, 'shutdown removes all timers' );
    }
);

T2->subtest(
    'READY state and command dispatch survive a full application event queue',
    sub {
        my ( $bot, $rest, $http, $rig, $errors ) = setup( max_events => 1 );
        my $calls = 0;
        my @notifications;
        $bot->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );
        $bot->on( READY => sub { push @notifications, 'READY' } );
        $bot->on( INTERACTION_CREATE => sub { push @notifications, 'INTERACTION_CREATE' } );
        my $started = $bot->start;
        my $websocket = $rig->{sockets}[0];
        $websocket->open;
        $websocket->emit( { op => 10, d => { heartbeat_interval => 60_000 } } );

        # Fill the application queue before READY without running deferred callbacks.
        $websocket->emit( { op => 0, s => 1, t => 'TEST', d => {} } );
        $websocket->emit(
            {
                op => 0,
                s => 2,
                t => 'READY',
                d => {
                    session_id => 'test',
                    resume_gateway_url => 'wss://resume.test/',
                    user => { id => '123' },
                    application => { id => '789' },
                }
            }
        );
        T2->ok( $started->is_done, 'startup succeeds while READY notification is dropped' );
        T2->is( $bot->user->{id}, '123', 'Client user is available before callbacks drain' );
        T2->is( $bot->commands->application_id, '789', 'READY still updates the application ID' );
        $websocket->emit( { op => 0, s => 3, t => 'INTERACTION_CREATE', d => payload(900) } );
        T2->is( $calls, 1, 'command admission bypasses the full application queue' );
        T2->is( JSON::PP->new->utf8->decode( $http->call->{request}->content )->{data}{content},
            'Pong', 'the initial reply starts immediately' );
        $http->respond( response( 204, undef ) );
        $rig->{clock}->run_deferred;
        T2->is( \@notifications, [], 'application notifications still respect queue limits' );
        T2->is( $rig->{gateway}->stats->{dropped_events}, 2, 'READY and interaction notifications are counted' );
        T2->is( $bot->interactions->stats->{handled}, 1, 'interaction completes once' );
        $bot->close->get;
        $rest->close->get;
        T2->is( $rig->{clock}->timer_count, 0, 'shutdown clears interaction and Gateway timers' );
    }
);

T2->subtest(
    'command dispatch survives occupied Gateway handler slots',
    sub {
        my ( $bot, $rest, $http, $rig, $errors ) = setup( max_events => 2, max_handlers => 1 );
        my $blocking = Future->new;
        $rig->{gateway}->on( BLOCK => sub { return $blocking } );
        my $calls = 0;
        $bot->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );
        my $started = $bot->start;
        my $websocket = ready_socket( $rig, interval => 60_000 );
        $rig->{clock}->run_deferred;

        # A direct Gateway listener occupies the only handler slot; its wildcard stays queued.
        $websocket->emit( { op => 0, s => 43, t => 'BLOCK', d => {} } );
        $rig->{clock}->run_deferred;
        $websocket->emit( { op => 0, s => 44, t => 'TEST', d => {} } );
        T2->is( $rig->{gateway}->stats->{active_handlers}, 1, 'Gateway listener is still pending' );
        T2->is( $rig->{gateway}->stats->{pending_events}, 2, 'event queue is full' );
        $websocket->emit( { op => 0, s => 45, t => 'INTERACTION_CREATE', d => payload(901) } );
        T2->is( $calls, 1, 'interaction starts despite occupied Gateway handler capacity' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled},
            1, 'command reply completes without draining event callbacks' );
        $bot->close->get;
        $rest->close->get;
        T2->ok( $blocking->is_cancelled, 'shutdown cancels the application listener' );
    }
);

T2->done_testing;
