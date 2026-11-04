use v5.26;
use warnings;
use Test2::V1;
use Scalar::Util qw(weaken);
use JSON::PP;
use IO::Async::Loop;
use Crypt::PK::Ed25519;
use lib 't/lib';
use TestDiscordREST qw(client response error);
use TestDiscordGateway qw(rig ready_socket);
use Discord::Client;
use Discord::Client::Commands;
use Discord::Client::Interactions;
use Discord::Client::HTTPInteractions;

sub payload {
    my ( $id, %extra ) = @_;
    return {
        id => "$id",
        application_id => '456',
        token => 'FAKE_LIFECYCLE_TOKEN',
        type => 2,
        data => { name => 'ping', type => 1 },
        %extra
    };
}

T2->subtest(
    'dispatcher work/replay bounds, cancellation and late delivery',
    sub {
        my $clock = bless { now => 0, timers => [] }, 'TestDiscordREST::Clock';
        my $commands = Discord::Client::Commands->new;
        my $calls = 0;
        my $work;
        $commands->define(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                $_[0]->defer;
                return $work = Future->new;
            }
        );
        my $dispatcher = Discord::Client::Interactions->new(
            commands => $commands,
            max_pending => 1,
            max_seen => 2,
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) },
            on_error => sub { }
        );

        # An acknowledged but unfinished handler still consumes an active-work slot.
        my %inline = ( initial_sender => sub { Future->done } );
        my $one = $dispatcher->handle( payload(1), %inline );
        T2->ok( !$one->is_ready, 'acknowledged background handler still occupies work slot' );
        T2->is( error( $dispatcher->handle( payload(2), %inline ) )->category,
            'queue_full', 'active work bound enforced' );
        T2->is( $calls, 1, 'rejected work has no handler side effects' );

        # Cancellation releases active work while retaining the replay record.
        $one->cancel;
        T2->ok( $work->is_cancelled, 'caller cancellation reaches handler' );
        T2->is( $dispatcher->stats->{pending}, 0, 'cancelled work released' );
        $commands->define(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                $_[0]->reply('Pong');
            }
        );
        $dispatcher->handle( payload(2), %inline )->get;
        T2->is( error( $dispatcher->handle( payload(3), %inline ) )->category,
            'queue_full', 'replay storage bound independent of active handlers' );

        # Replay capacity becomes available at expiry, but already-late input cannot run.
        $clock->advance(900);
        $dispatcher->handle( payload(3), %inline )->get;
        T2->is( $calls, 3, 'expired replay records release capacity' );
        my $late = $dispatcher->handle( payload(4), %inline, received_at => $clock->{now} - 3 );
        T2->is( error($late)->category, 'deadline', 'queue time counts toward initial deadline' );
        T2->is( $calls, 3, 'expired interaction never invokes application handler' );
        $dispatcher->close->get;
        $commands->close;
        T2->is( $clock->timer_count, 0, 'dispatcher has no outstanding timers' );
        T2->like(
            T2->dies(
                sub {
                    $commands->component( 'late', sub { } );
                }
            ),
            qr/registry is closed/,
            'closed registry rejects component additions'
        );
    }
);

T2->subtest(
    'dispatcher keeps running IDs protected beyond the retention period',
    sub {
        my $clock = bless { now => 0, timers => [] }, 'TestDiscordREST::Clock';
        my $commands = Discord::Client::Commands->new;
        my $work = Future->new;
        my $calls = 0;
        $commands->define(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                $_[0]->defer;
                return $work;
            }
        );
        my $dispatcher = Discord::Client::Interactions->new(
            commands => $commands,
            max_seen => 1,
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) },
            on_error => sub { },
        );
        my %inline = ( initial_sender => sub { Future->done } );
        my $first = $dispatcher->handle( payload(5), %inline );

        # Initial acknowledgement finishes, but side effects can outlive the default TTL.
        $clock->advance(901);
        T2->ref_is( $dispatcher->handle( payload(5), %inline ),
            $first, 'duplicate returns the same running operation' );
        T2->is( $calls, 1, 'the handler does not repeat after expiry' );
        T2->is( error( $dispatcher->handle( payload(6), %inline ) )->category,
            'queue_full', 'active ID still uses retention capacity' );
        $work->done;
        T2->ok( $first->is_done, 'the original handler settles' );
        T2->ok( $dispatcher->handle( payload(6), %inline )->is_done, 'completion permits expiry and new work' );
        T2->is( $calls, 2, 'only the new ID starts additional work' );
        $dispatcher->close->get;
        $commands->close;
        T2->is( $clock->timer_count, 0, 'all response timers are cancelled' );
    }
);

T2->subtest(
    'integer autocomplete values are encoded as JSON numbers',
    sub {
        my ( $rest, $http ) = client();
        my $fixture = rig( loop => $rest->loop );
        my $clock = $fixture->{clock};
        my $bot = Discord::Client->new(
            rest => $rest,
            loop => $rest->loop,
            gateway => $fixture->{gateway},
            interaction_options => {
                clock => sub { $clock->{now} },
                delay => sub { $clock->delay( $_[0] ) },
            },
        );

        # Register autocomplete through the public Client command API.
        $bot->command(
            ping => description => 'Ping',
            handler => sub { },
            options => [
                {
                    name => 'n',
                    description => 'Number',
                    type => 'integer',
                    autocomplete => sub { [ { name => 'Two', value => '2' } ] },
                }
            ],
        );
        my $started = $bot->start;
        my $socket = ready_socket( $fixture, interval => 60_000 );
        $clock->run_deferred;
        T2->ok( $started->is_done, 'client starts' );
        $socket->emit(
            {
                op => 0,
                s => 43,
                t => 'INTERACTION_CREATE',
                d => payload(
                    10,
                    type => 4,
                    data => {
                        name => 'ping',
                        type => 1,
                        options => [ { name => 'n', type => 4, value => 1, focused => JSON::PP::true } ],
                    },
                )
            }
        );
        $clock->run_deferred;
        T2->like( $http->call->{request}->content,
            qr/"value":2\b/, 'autocomplete response encodes the value as a JSON number' );
        $http->respond( response( 204, undef ) );
        T2->is( $bot->interactions->stats->{handled}, 1, 'autocomplete handler completes' );
        $bot->close->get;
        $rest->close->get;
    }
);

T2->subtest(
    'HTTP delivery rejects an expired interaction before calling its handler',
    sub {
        my $clock = bless { now => 0, timers => [] }, 'TestDiscordREST::Clock';
        my $key = Crypt::PK::Ed25519->new->generate_key;
        my $http_service = Discord::Client::HTTPInteractions->new(
            public_key => unpack( 'H*', $key->export_key_raw('public') ),
            clock => sub { $clock->{now} },
            wall_clock => sub { 1000 },
            delay => sub { $clock->delay( $_[0] ) },
            on_error => sub { }
        );
        my $calls = 0;
        $http_service->command(
            ping => description => 'Ping',
            handler => sub {
                ++$calls;
                $_[0]->reply('Pong');
            }
        );
        my $body = JSON::PP->new->utf8->encode( payload(11) );
        my $headers = {
            'X-Signature-Timestamp' => '1000',
            'X-Signature-Ed25519' => unpack( 'H*', $key->sign_message( '1000' . $body ) )
        };
        T2->is( $http_service->handle( $headers, $body, received_at => -3 )->get->[0],
            504, 'delayed framework receipt gives bounded error' );
        T2->is( $calls, 0, 'late HTTP handler not executed' );
        $http_service->close;
        my $weak = $http_service;
        weaken($weak);
        undef $http_service;
        T2->ok( !defined($weak), 'closed HTTP service releases dispatcher and closures' );
    }
);

T2->subtest(
    'the facade bounds callback work and cancels it during shutdown',
    sub {
        my ($rest) = client();
        my $rig = rig( loop => $rest->loop );
        my @errors;
        my $bot = Discord::Client->new(
            loop => $rest->loop,
            rest => $rest,
            gateway => $rig->{gateway},
            max_callbacks => 1,
            on_error => sub { push @errors, $_[0] }
        );

        # Keep one callback pending so the next event reaches the configured capacity limit.
        my $pending = Future->new;
        $bot->on( message_create => sub { $pending } );
        my $start = $bot->start;
        my $websocket = ready_socket($rig);
        $start->get;
        $websocket->emit( { op => 0, s => $_, t => 'MESSAGE_CREATE', d => { id => "$_" } } ) for 43, 44;
        $rig->{clock}->run_deferred;
        T2->is( $errors[0]->category, 'queue_full', 'bounded application callback error' );
        $bot->close->get;
        T2->ok( $pending->is_cancelled, 'shutdown cancels callback work' );

        # After shutdown, internal callbacks must not keep the facade alive.
        undef $start;
        my $weak = $bot;
        weaken($weak);
        undef $bot;
        T2->ok( !defined($weak), 'closed facade releases internal owner callbacks' );
        $rest->close;
    }
);

T2->subtest(
    'run starts the Gateway and closes from a READY handler',
    sub {
        my ($rest) = client();
        my $fixture = rig( loop => $rest->loop );
        my $bot = Discord::Client->new(
            loop => $rest->loop,
            rest => $rest,
            gateway => $fixture->{gateway},
        );
        my $ready_calls = 0;

        # The standalone run method drives the loop until the application's close.
        $bot->on(
            READY => sub {
                ++$ready_calls;
                return $_[2]->close;
            }
        );
        $bot->loop->later(
            sub {
                ready_socket($fixture);
                $fixture->{clock}->run_deferred;
            }
        );
        $bot->run;
        T2->is( $ready_calls, 1, 'run delivers READY to the registered handler' );
        T2->ok( $bot->completion->is_done, 'run waits for completed shutdown' );
        T2->is( $fixture->{sockets}[-1]{close_code}, 1000, 'Gateway transport closes gracefully' );
        T2->is( $fixture->{clock}->timer_count, 0, 'run leaves no Gateway timers' );
        $rest->close->get;
    }
);

T2->subtest(
    'run detaches signal handlers after lifecycle failures',
    sub {
        my @cases = (
            {
                name => 'shutdown failure after normal completion',
                startup_failure => 0,
                error => qr/shutdown failed/
            },
            {
                name => 'startup failure takes precedence over shutdown failure',
                startup_failure => 1,
                error => qr/startup failed/
            },
        );
        for my $case (@cases) {
            T2->subtest(
                $case->{name},
                sub {
                    my $loop = bless { attached => [], detached => [] }, 'Local::SignalLoop';
                    my ($rest) = client( loop => $loop );
                    my $gateway = bless {
                        loop => $loop,
                        completion => Future->done,
                        closing => Future->fail( 'shutdown failed', 'transport' ),
                        },
                        'Local::RunGateway';
                    $gateway->{connecting} = Future->fail( 'startup failed', 'transport' )
                        if $case->{startup_failure};
                    my $bot = Discord::Client->new(
                        loop => $loop,
                        rest => $rest,
                        gateway => $gateway
                    );

                    T2->like( T2->dies( sub { $bot->run } ),
                        $case->{error}, 'run surfaces the primary lifecycle failure' );
                    T2->is( $loop->{detached}, $loop->{attached},
                        'signal handlers are removed even when close fails' );
                    $rest->close;
                }
            );
        }
    }
);

T2->subtest(
    'closing from a callback stops further callback invocation',
    sub {
        my ($rest) = client();
        my $rig = rig( loop => $rest->loop );
        my $bot = Discord::Client->new(
            rest => $rest,
            loop => $rest->loop,
            gateway => $rig->{gateway}
        );
        my $later_calls = 0;
        my $unfinished = Future->new;
        $bot->on(
            message_create => sub {
                $_[2]->close;
                return $unfinished;
            }
        );
        $bot->on( message_create => sub { ++$later_calls } );
        my $started = $bot->start;
        my $websocket = ready_socket($rig);
        $started->get;
        $websocket->emit( { op => 0, s => 43, t => 'MESSAGE_CREATE', d => { id => '42' } } );
        $rig->{clock}->run_deferred;
        T2->is( $later_calls, 0, 'callbacks cannot start more work after close' );
        T2->ok( $unfinished->is_cancelled, 'work returned by the closing callback is cancelled' );
        $rest->close;
    }
);

T2->subtest(
    'application error hook can close the client during a handler Future failure',
    sub {
        my ( $rest, $http ) = client();
        my $fixture = rig( loop => $rest->loop );
        my $clock = $fixture->{clock};
        my ( $bot, $received_error, $received_context, $closing );
        $bot = Discord::Client->new(
            rest => $rest,
            loop => $rest->loop,
            gateway => $fixture->{gateway},
            interaction_options => {
                clock => sub { $clock->{now} },
                delay => sub { $clock->delay( $_[0] ) },
            },
            on_error => sub {
                my ( $error, $context, $client ) = @_;
                ( $received_error, $received_context ) = ( $error, $context );
                $closing = $client->close;
            },
        );
        my $work = Future->new;
        my $handler;

        # Acknowledge through REST, then return the application's pending work.
        $bot->command(
            ping => description => 'Ping',
            handler => sub {
                return $handler = $_[0]->defer->then( sub { return $work } );
            }
        );
        my $started = $bot->start;
        my $socket = ready_socket( $fixture, interval => 60_000 );
        $clock->run_deferred;
        T2->ok( $started->is_done, 'client starts' );
        $socket->emit( { op => 0, s => 43, t => 'INTERACTION_CREATE', d => payload(100) } );
        $clock->run_deferred;
        $http->respond( response( 204, undef ) );
        T2->ok( !$handler->is_ready, 'handler waits for application work' );

        # The error hook is allowed to stop the client while dispatch is settling.
        T2->try_ok(
            sub { $work->fail( 'private handler details', 'handler' ) },
            'error hook shutdown does not complete an already cancelled Future'
        );
        T2->is( $received_error->category, 'handler', 'application receives the handler failure' );
        T2->unlike( $received_error->message, qr/private handler details/, 'error is sanitized' );
        T2->is( $received_context->id, '100', 'error hook receives the failing interaction' );
        T2->ok( $closing->is_done, 'error hook completes client shutdown' );
        T2->ok( $bot->completion->is_done, 'Gateway lifetime ends' );
        T2->is( $bot->interactions->stats->{pending}, 0, 'no job retained after error hook shutdown' );
        T2->is( $clock->timer_count, 0, 'shutdown removes response and Gateway timers' );
        $rest->close->get;
    }
);

T2->subtest(
    'a callback can return asynchronous client shutdown',
    sub {
        # Hold the transport shutdown open so the callback returns pending work.
        my ($rest) = client();
        my $fixture = rig( loop => $rest->loop );
        my $bot = Discord::Client->new(
            rest => $rest,
            loop => $rest->loop,
            gateway => $fixture->{gateway}
        );
        my $closing;
        $bot->on( READY => sub { return $closing = $_[2]->close } );
        my $started = $bot->start;
        my $websocket = ready_socket($fixture);
        my $transport_close = $websocket->{close_future} = Future->new;

        # Returning the shutdown Future must preserve the graceful close handshake.
        $fixture->{clock}->run_deferred;
        T2->ok( $started->is_done, 'startup completed before the callback' );
        T2->ok( !$closing->is_ready, 'client shutdown still awaits its transport' );
        T2->ok( !$transport_close->is_ready, 'transport close was not cancelled' );
        $transport_close->done unless $transport_close->is_ready;
        T2->ok( $closing->is_done, 'client shutdown completes successfully' );
        T2->ref_is( $bot->close, $closing, 'later close calls observe the same result' );
        $rest->close;
    }
);

T2->subtest(
    'work returned after dispatcher shutdown cannot produce later side effects',
    sub {
        # Model application work independent of the interaction REST transport.
        my $clock = bless { now => 0, timers => [] }, 'TestDiscordREST::Clock';
        my $commands = Discord::Client::Commands->new;
        my $dispatcher = Discord::Client::Interactions->new(
            commands => $commands,
            clock => sub { $clock->{now} },
            delay => sub { $clock->delay( $_[0] ) },
            on_error => sub { }
        );
        my ( $work, $effects );
        $effects = 0;
        $commands->define(
            ping => description => 'Stop',
            handler => sub {
                $work = $clock->delay(1)->then(
                    sub {
                        ++$effects;
                        return Future->done;
                    }
                );
                $dispatcher->close;
                return $work;
            }
        );

        # Closing during invocation must also cancel the not-yet-registered Future.
        my $handled = $dispatcher->handle( payload(100) );
        T2->ok( $handled->is_cancelled, 'dispatch result is cancelled' );
        T2->ok( $work->is_cancelled, 'returned application work is cancelled' );
        $clock->advance(1);
        T2->is( $effects, 0, 'no side effects occur after shutdown' );
        T2->is( $dispatcher->stats->{pending}, 0, 'shutdown releases the handler slot' );
        $commands->close;
    }
);

package Local::SignalLoop;
sub new_future { Future->new }

sub attach_signal {
    my ( $self, $signal ) = @_;
    my $id = @{ $self->{attached} } + 1;
    push @{ $self->{attached} }, [ $signal, $id ];
    return $id;
}

sub detach_signal {
    my ( $self, @args ) = @_;
    push @{ $self->{detached} }, \@args;
}

package Local::RunGateway;
sub on { $_[0] }
sub _on_dispatch { $_[0] }
sub connect { $_[0]{connecting} // $_[0]{loop}->new_future->done( $_[0] ) }
sub completion { $_[0]{completion} }

sub close {
    $_[0]{closed} = 1;
    $_[0]{closing} // $_[0]{loop}->new_future->done;
}

package main;
T2->done_testing;
