use v5.26;
use warnings;
use Test2::V1;
use Future;
use IO::Async::Loop;
use lib 't/lib';
use TestDiscordREST qw(error client response);
use TestDiscordGateway qw(gateway_info);
use Discord::Client::Gateway::Shards;
use Discord::Client;

sub manager {
    my (%args) = @_;
    my $clock = bless { now => 0, timers => [], deferred => [] }, 'TestDiscordGateway::Clock';
    my $rest =
        bless { calls => [], responses => [ $args{info} // gateway_info( max_concurrency => 2 ) ] },
        'TestDiscordGateway::REST';
    my @sockets;

    # Share one clock and discovery response while recording each child socket separately.
    my %gateway_options = (
        token => 'FAKE_SHARD_TOKEN',
        rest => $rest,
        loop => IO::Async::Loop->new,
        clock => sub { $clock->{now} },
        delay => sub { $clock->delay( $_[0] ) },
        defer => sub { push @{ $clock->{deferred} }, $_[0] },
        random => sub { 0.25 },
        on_error => sub { },
        websocket_factory => sub {
            my $websocket = bless { options => {@_}, frames => [], writes => [], active => 0 },
                'TestDiscordGateway::WebSocket';
            push @sockets, $websocket;
            return $websocket;
        },
        %args
    );
    my $manager = Discord::Client::Gateway::Shards->new(%gateway_options);
    return ( $manager, $clock, $rest, \@sockets, \%gateway_options );
}

sub hello {
    my ($websocket) = @_;
    $websocket->open;

    # Acknowledge heartbeats so advancing the Identify clock does not create unrelated reconnects.
    $websocket->{on_send} = sub { $websocket->emit( { op => 11 } ) if $_[0]{op} == 1 };
    $websocket->emit( { op => 10, d => { heartbeat_interval => 10000 } } );
}

sub ready {
    my ( $websocket, $id ) = @_;
    $websocket->emit(
        {
            op => 0,
            s => 1,
            t => 'READY',
            d => { session_id => "s$id", resume_gateway_url => 'wss://resume.test/' }
        }
    );
}

sub identifies {
    [ map { $_->{d}{shard} } grep { $_->{op} == 2 } @{ $_[0]{frames} } ];
}

T2->subtest(
    'shared Identify schedule and readiness',
    sub {
        my ( $manager, $clock, $rest, $sockets ) = manager( shards => 3 );
        T2->is( scalar( @{ $rest->{calls} } ), 0, 'constructor performs no discovery' );
        my $start = $manager->connect;
        T2->is( scalar( @{ $rest->{calls} } ), 1, 'single discovery shared by all children' );

        # Different Identify buckets may start together; the third shard shares bucket zero.
        hello($_) for @$sockets;
        T2->is( identifies( $sockets->[0] ), [ [ 0, 3 ] ], 'shard zero identified' );
        T2->is( identifies( $sockets->[1] ), [ [ 1, 3 ] ], 'different bucket identified concurrently' );
        T2->is( identifies( $sockets->[2] ), [], 'same bucket waits' );
        ready( $sockets->[$_], $_ ) for 0, 1;
        T2->ok( !$start->is_ready, 'readiness requires every shard' );

        # Cross the five-second boundary before making the last shard ready.
        $clock->advance(4.99);
        T2->is( identifies( $sockets->[2] ), [], 'cooldown enforced' );
        $clock->advance(0.01);
        T2->is( identifies( $sockets->[2] ), [ [ 2, 3 ] ], 'waiting shard allowed at five seconds' );
        ready( $sockets->[2], 2 );
        $clock->run_deferred;
        T2->ok( $start->is_done, 'all READY resolves startup' );

        # Guild routing must retain the full precision of Discord snowflakes.
        T2->is( $manager->shard_for_guild('4194304'), 1, 'snowflake shard routing' );
        T2->is( $manager->shard_for_guild('18446744073709551615'), 0, 'uint64 routing retains precision' );
        T2->like(
            T2->dies( sub { $manager->shard_for_guild('18446744073709551616') } ),
            qr/exceeds uint64/,
            'overflow rejected for the correct reason'
        );
        local $@ = 'earlier caller exception';
        T2->ok( $manager->send( 3, { status => 'online' }, shard_id => 0 )->is_done,
            'direct send unaffected by caller exception state' );
        $manager->send( 3, { status => 'online' }, guild_id => '4194304' )->get;
        T2->is( $sockets->[1]{frames}[-1]{op}, 3, 'guild send targets correct shard' );
        $manager->broadcast( 3, { status => 'idle' } )->get;
        T2->is( $_->{frames}[-1]{d}{status}, 'idle', 'broadcast sent' ) for @$sockets;

        # A reconnecting child makes the aggregate unavailable until its session resumes.
        $sockets->[0]->emit( { op => 7 } );
        T2->is( $manager->state, 'reconnecting', 'manager reflects a reconnecting child' );
        my $again = $manager->connect;
        T2->ok( !$again->is_ready, 'connect during reconnect waits' );
        $clock->advance(0);
        hello( $sockets->[-1] );
        T2->is( $sockets->[-1]{frames}[-1]{op}, 6, 'child resumes without Identify' );
        $sockets->[-1]->emit( { op => 0, s => 2, t => 'RESUMED', d => {} } );
        $clock->run_deferred;
        T2->ok( $again->is_done, 'all sessions restored' );
        $manager->close->get;
        T2->is( $clock->timer_count, 0, 'all shard/limiter timers removed' );
        T2->ok( $manager->completion->is_done, 'lifetime finishes' );
    }
);

T2->subtest(
    'automatic count, fatal child and cancellation',
    sub {
        my ( $manager, $clock, $rest, $sockets ) = manager();
        my $start = $manager->connect;
        T2->is( scalar(@$sockets), 2, 'recommended count used' );
        $sockets->[0]->remote_close(4014);
        T2->ok( $start->is_failed && $manager->completion->is_failed, 'fatal shard fails startup and lifetime' );
        T2->is( $manager->state, 'closed', 'fatal failure closes all shards' );
        T2->is( $clock->timer_count, 0, 'fatal shutdown removes timers' );

        # Cancellation during discovery must stop the shared request before creating children.
        my $discovery = Future->new;
        ( $manager, $clock, $rest, $sockets ) = manager( info => $discovery );
        $start = $manager->connect;
        $start->cancel;
        T2->ok( $discovery->is_cancelled, 'startup cancellation cancels shared REST discovery' );
        T2->is( $manager->state, 'closed', 'cancelled manager cannot restart' );
        ( $manager, $clock ) = manager( shards => 3, max_shards => 2 );
        T2->is( error( $manager->connect )->category, 'request', 'configured capacity respected' );
        ( $manager, $clock ) = manager( intents => ['NO_SUCH_INTENT'] );
        T2->is( error( $manager->connect )->category,
            'request', 'bad child configuration becomes a Future failure' );
    }
);

T2->subtest(
    'shard listeners fail independently and preserve delivery order',
    sub {
        my @errors;
        my ( $manager, $clock, $rest, $sockets ) = manager(
            shards => 1,
            on_error => sub { push @errors, $_[0] }
        );
        my @seen;
        $manager->on(
            TEST => sub {
                push @seen, 'first';
                die 'FAKE_SHARD_TOKEN handler secret';
            }
        );
        $manager->on( TEST => sub { push @seen, 'second' } );
        $manager->connect;
        hello( $sockets->[0] );
        ready( $sockets->[0], 0 );
        $clock->run_deferred;
        $manager->on( '*' => sub { push @seen, "wildcard:$_[0]" } );
        $sockets->[0]->emit( { op => 0, s => 2, t => 'TEST', d => {} } );
        $clock->run_deferred;
        T2->is(
            \@seen,
            [ 'first', 'second', 'wildcard:TEST' ],
            'a thrown named listener does not skip later named or wildcard listeners'
        );
        T2->is( scalar(@errors), 1, 'failed listener is reported once' );
        T2->is( $errors[0]->category, 'handler', 'listener failure uses handler category' );
        T2->unlike( join( ' ', @errors ), qr/FAKE_SHARD_TOKEN/, 'handler exception is sanitized' );
        T2->is( $manager->state, 'ready', 'listener failure leaves shards connected' );
        $manager->close;
    }
);

T2->subtest(
    'invalid event names never enter shard listener state',
    sub {
        my ( $manager, $clock, $rest, $sockets ) = manager( shards => 1 );
        T2->like(
            T2->dies(
                sub {
                    $manager->on( '' => sub { } );
                }
            ),
            qr/Event and callback required/,
            'empty name rejected before connecting'
        );
        T2->is( $manager->state, 'idle', 'invalid registration cannot start a connection' );
        my $start = $manager->connect;
        hello( $sockets->[0] );
        ready( $sockets->[0], 0 );
        T2->ok( $start->is_done, 'startup still returns a successful Future' );
        T2->like(
            T2->dies(
                sub {
                    $manager->on( '' => sub { } );
                }
            ),
            qr/Event and callback required/,
            'empty name rejected after connecting'
        );
        T2->is( $manager->state, 'ready', 'invalid late registration cannot disturb the session' );
        my $seen = 0;
        $manager->on( TEST => sub { ++$seen } );
        $sockets->[0]->emit( { op => 0, s => 2, t => 'TEST', d => {} } );
        $clock->run_deferred;
        T2->is( $seen, 1, 'valid late listener still runs' );
        $manager->close;
    }
);

T2->subtest(
    'each shard listener occupies one child handler slot',
    sub {
        my ( $manager, $clock, $rest, $sockets ) = manager( shards => 1, max_handlers => 1 );
        my ( $first, $second ) = ( Future->new, Future->new );
        my @seen;
        $manager->on(
            TEST => sub {
                push @seen, 'first';
                return $first;
            }
        );
        $manager->on(
            TEST => sub {
                push @seen, 'second';
                return $second;
            }
        );
        $manager->connect;
        hello( $sockets->[0] );
        ready( $sockets->[0], 0 );
        $clock->run_deferred;
        $sockets->[0]->emit( { op => 0, s => 2, t => 'TEST', d => {} } );
        $clock->run_deferred;
        T2->is( \@seen, ['first'], 'second listener waits for capacity' );
        T2->is( $manager->shards->{0}->stats->{active_handlers}, 1, 'first Future uses one slot' );
        T2->is( $manager->shards->{0}->stats->{pending_events}, 1, 'second invocation remains bounded in queue' );
        $first->done;
        $clock->run_deferred;
        T2->is( \@seen, [ 'first', 'second' ], 'second listener runs when capacity returns' );
        T2->is( $manager->shards->{0}->stats->{active_handlers}, 1, 'second Future uses its own slot' );
        $manager->close;
        T2->ok( $second->is_cancelled, 'shutdown cancels active listener work' );
    }
);

T2->subtest(
    'reconnect readiness does not depend on queued event callbacks',
    sub {
        my ( $manager, $clock, $rest, $sockets ) = manager( shards => 1, max_events => 1 );
        $manager->on( RESUMED => sub { T2->fail('dropped RESUMED callback ran') } );
        $manager->on( RESUMED => sub { T2->fail('dropped RESUMED callback ran') } );
        $manager->connect;
        hello( $sockets->[0] );
        ready( $sockets->[0], 0 );
        $clock->run_deferred;
        $sockets->[0]->remote_close(1006);
        my $again = $manager->connect;
        T2->ok( !$again->is_ready, 'manager waits for reconnecting child' );
        $clock->advance(0.625);
        my $resumed = $sockets->[-1];
        hello($resumed);
        $resumed->emit( { op => 0, s => 2, t => 'RESUMED', d => {} } );
        T2->ok( $again->is_done, 'child readiness resolves manager despite dropped callbacks' );
        T2->is( $manager->shards->{0}->stats->{dropped_events},
            1, 'manager readiness does not depend on delivering an overloaded RESUMED event' );
        $manager->close;
    }
);

T2->subtest(
    'high-level facade creates and owns its shard manager',
    sub {
        my ( $unused, $clock, $rest, $sockets, $options ) = manager();
        my %gateway_options = %$options;
        $unused->close;
        my $bot = Discord::Client->new(
            token => 'FAKE_SHARD_TOKEN',
            rest => $rest,
            loop => $gateway_options{loop},
            shards => 'auto',
            gateway_options => \%gateway_options,
            cache => { types => ['message'] }
        );
        T2->isa_ok( $bot->gateway, 'Discord::Client::Gateway::Shards' );
        $bot->command( ping => description => 'Ping', handler => sub { $_[0]->reply('Pong') } );
        T2->is( scalar( @{ $rest->{calls} } ), 0, 'construction/commands remain local' );
        my $started = $bot->start;
        hello($_) for @$sockets;
        ready( $sockets->[$_], $_ ) for 0, 1;
        $clock->run_deferred;
        T2->ok( $started->is_done, 'bot startup waits for both shards' );
        T2->is( scalar( @{ $rest->{calls} } ), 1, 'bot startup only discovers Gateway' );
        my $seen;
        $bot->on( message_create => sub { $seen = $_[0]{id} } );
        $sockets->[1]->emit( { op => 0, s => 2, t => 'MESSAGE_CREATE', d => { id => '50', channel_id => '2' } } );
        $clock->run_deferred;
        T2->is( $seen, '50', 'events from a nonzero shard reach facade' );
        T2->is( $bot->cache->get( message => '50' )->{id}, '50', 'one cache observes all shards' );
        T2->is( $bot->model( user => { id => '123' } )->mention, '<@123>', 'facade exposes optional models' );
        $bot->close->get;
        T2->is( $clock->timer_count, 0, 'facade closes every shard' );
    }
);

T2->subtest(
    'Client state and interactions survive overloaded child queues',
    sub {
        my ( $manager, $clock, $discovery_rest, $sockets ) = manager( shards => 2, max_events => 1 );
        my ( $rest, $http ) = client();
        my $bot = Discord::Client->new(
            token => 'FAKE_SHARD_TOKEN',
            loop => $rest->loop,
            rest => $rest,
            gateway => $manager,
            cache => { types => ['message'] },
            interaction_options => { clock => sub { $clock->{now} }, delay => sub { $clock->delay( $_[0] ) } },
            on_error => sub { },
        );
        my $calls = 0;
        $bot->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                return $_[0]->reply('Pong');
            }
        );
        my $started = $bot->start;

        # Internal observers must attach to every child before any READY packet.
        for my $id ( 0, 1 ) {
            my $socket = $sockets->[$id];
            hello($socket);
            $socket->emit( { op => 0, s => 1, t => 'TEST', d => {} } );
            $socket->emit(
                {
                    op => 0,
                    s => 2,
                    t => 'READY',
                    d => {
                        session_id => "overloaded-$id",
                        resume_gateway_url => 'wss://resume.test/',
                        user => { id => '123' },
                        application => { id => '456' },
                    }
                }
            );
        }
        T2->ok( $started->is_done, 'all children become ready despite full notification queues' );
        T2->is( $bot->user->{id}, '123', 'READY reaches Client state' );
        T2->is( $bot->commands->application_id, '456', 'application metadata reaches the registry' );

        # A nonzero shard updates cache and dispatches commands even when notifications drop.
        $sockets->[1]->emit( { op => 0, s => 3, t => 'MESSAGE_CREATE', d => { id => '50', channel_id => '2' } } );
        T2->is( $bot->cache->get( message => '50' )->{id}, '50', 'cache observes a dropped notification' );
        $sockets->[1]->emit(
            {
                op => 0,
                s => 4,
                t => 'INTERACTION_CREATE',
                d => {
                    id => '902',
                    application_id => '456',
                    token => 'FAKE_INTERACTION_TOKEN',
                    type => 2,
                    data => { name => 'ping', type => 1 },
                }
            }
        );
        T2->is( $calls, 1, 'command from nonzero shard executes' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'command finishes without application callbacks' );
        $bot->close->get;
        $rest->close->get;
        T2->is( $clock->timer_count, 0, 'all child resources close' );
    }
);

T2->done_testing;
