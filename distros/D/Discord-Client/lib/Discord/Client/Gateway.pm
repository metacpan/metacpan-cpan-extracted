package Discord::Client::Gateway;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Encode qw(encode);
use JSON::PP ();
use IO::Async::Loop;
use Scalar::Util qw(blessed refaddr weaken);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use URI;
use Discord::Client::Error;
use Discord::Client::REST;
use Discord::Client::Gateway::Session;
use Discord::Client::Gateway::IdentifyLimiter;
use Discord::Client::Gateway::WebSocket;

our $VERSION = '0.002';

# Connection-local send limits; protocol traffic shares this window with application writes.
use constant {
    OUTGOING_WINDOW_SECONDS => 60,
    MAX_SENDS_PER_WINDOW => 120,
    MAX_PAYLOAD_BYTES => 4096,
};

sub new {
    my ( $class, %args ) = @_;

    # Keep protocol state independent of the loop and the WebSocket transport.
    my $loop = $args{loop} // IO::Async::Loop->new;
    my $session = Discord::Client::Gateway::Session->new(
        token => $args{token},
        intents => $args{intents} // 0,
        random => $args{random} // sub { rand() },
        shard => $args{shard},
    );
    my $self = bless {
        loop => $loop,
        session => $session,
        state => 'idle',
        clock => $args{clock} // sub { clock_gettime(CLOCK_MONOTONIC) },
        random => $args{random} // sub { rand() },
        delay => $args{delay} // sub { $loop->delay_future( after => $_[0] ) },
        defer => $args{defer} // sub { $loop->later( $_[0] ) },
        websocket_factory => $args{websocket_factory},
        websocket_options => $args{websocket_options} // {},
        shard_id => $args{shard} ? $args{shard}[0] : 0,
        connect_timeout => $args{connect_timeout} // 30,
        stable_after => $args{stable_after} // 60,
        backoff_base => $args{backoff_base} // 1,
        backoff_max => $args{backoff_max} // 60,
        max_outgoing => $args{max_outgoing} // 128,
        max_events => $args{max_events} // 1024,
        max_handlers => $args{max_handlers} // 64,
        handlers => {},
        dispatch_observers => [],
        event_queue => [],
        handler_futures => {},
        outgoing => [],
        timers => {},
        counters => {},
        generation => 0,
        attempts => 0,
        send_times => [],
        on_error => $args{on_error},
        on_diagnostic => $args{on_diagnostic},
    }, $class;

    # Validate resource bounds and hooks before attaching owned network resources.
    for my $field (qw(max_outgoing max_events max_handlers)) {
        croak "$field must be a positive integer"
            unless defined( $self->{$field} )
            && !ref( $self->{$field} )
            && $self->{$field} =~ /\A\d+\z/
            && $self->{$field} > 0;
    }
    for my $field (qw(connect_timeout stable_after backoff_base backoff_max)) {
        croak "$field must be positive"
            unless defined( $self->{$field} )
            && !ref( $self->{$field} )
            && $self->{$field} =~ /\A\d+(?:\.\d+)?\z/
            && $self->{$field} > 0;
    }
    for my $field (qw(clock random delay defer websocket_factory on_error on_diagnostic)) {
        croak "$field must be a code reference" if defined( $args{$field} ) && ref( $args{$field} ) ne 'CODE';
    }
    croak 'websocket_options must be a hash reference' unless ref( $self->{websocket_options} ) eq 'HASH';

    # Share discovery and Identify scheduling when a shard manager provides them.
    $self->{rest} = $args{rest} // Discord::Client::REST->new( token => $args{token}, loop => $loop );
    $self->{own_rest} = !$args{rest};
    $self->{identify_limiter} = $args{identify_limiter} // Discord::Client::Gateway::IdentifyLimiter->new(
        loop => $loop,
        rest => $self->{rest},
        clock => $self->{clock},
        delay => $self->{delay}
    );
    $self->{own_limiter} = !$args{identify_limiter};
    $self->{completion} = $loop->new_future;
    return $self;
}

sub loop { $_[0]->{loop} }
sub state { $_[0]->{state} }
sub session { $_[0]->{session} }
sub completion { $_[0]->{completion} }
sub identify_limiter { $_[0]->{identify_limiter} }

sub stats {
    my ($self) = @_;

    # Report queue sizes and timing without retaining or exposing payloads.
    return {
        %{ $self->{counters} },
        state => $self->{state},
        pending_events => scalar( @{ $self->{event_queue} } ),
        active_handlers => scalar( keys %{ $self->{handler_futures} } ),
        pending_writes => scalar( @{ $self->{outgoing} } ) + ( $self->{active_write} ? 1 : 0 ),
        heartbeat_latency => $self->{heartbeat_latency}
    };
}

sub on {
    my ( $self, $event, $callback ) = @_;

    # Validate the event before adding a callback to the delivery registry.
    croak 'event name and callback are required'
        unless defined($event)
        && !ref($event)
        && length($event)
        && ref($callback) eq 'CODE';
    push @{ $self->{handlers}{$event} }, $callback;
    return $self;
}

# SDK state consumers run before the bounded application callback queue.
sub _on_dispatch {
    my ( $self, $callback ) = @_;
    croak 'dispatch observer must be a code reference' unless ref($callback) eq 'CODE';

    push @{ $self->{dispatch_observers} }, $callback;
    return $self;
}

sub connect {
    my ($self) = @_;

    # Reuse an outstanding startup wait; a reconnect needs a fresh ready notification.
    return $self->_failed( 'Gateway is closed', 'shutdown' ) if $self->{closed};
    return $self->{loop}->new_future->done($self) if $self->{state} eq 'ready';
    return $self->{ready_future} if $self->{ready_future} && !$self->{ready_future}->is_ready;
    my $ready = $self->{loop}->new_future;
    $self->{ready_future} = $ready;
    $ready->on_cancel( sub { $self->close } );
    return $ready if $self->{running};

    # Discover the endpoint once before opening the first connection.
    $self->{running} = 1;
    $self->{state} = 'discovering';
    my $info = $self->{identify_limiter}->info;
    $self->{discovery} = $info;

    # Discovery completion may arrive after the caller has closed the Gateway.
    $info->on_ready(
        sub {
            delete $self->{discovery};
            return if $self->{closed};
            if ( $info->is_done ) {
                ( $self->{gateway_info} ) = $info->result;
                $self->_open;
            }
            elsif ( $info->is_failed ) {
                my ( undef, $category ) = $info->failure;
                $self->_fatal( 'Gateway discovery failed', $category // 'transport' );
            }
            else {
                $self->_fatal( 'Gateway discovery cancelled', 'transport' );
            }
        }
    );
    return $ready;
}

sub _open {
    my ($self) = @_;
    return if $self->{closed};

    # Tag callbacks so an old socket cannot mutate a newer connection.
    my $generation = ++$self->{generation};
    my $url = $self->{session}->can_resume ? $self->{session}->resume_gateway_url : $self->{gateway_info}{url};
    my $uri = URI->new($url);
    unless ( ( $uri->scheme // '' ) eq 'wss'
        && $uri->host
        && !defined( $uri->userinfo )
        && !defined( $uri->fragment ) )
    {
        $self->_fatal( 'Invalid Gateway URL', 'protocol' );
        return;
    }

    # Metadata and Resume URLs may omit a path; HTTP upgrades still need '/'.
    $uri->path('/') unless length( $uri->path );
    $uri->query_form( v => 10, encoding => 'json' );

    # Transport callbacks do not own the Gateway; stale callbacks are ignored.
    my $weak = $self;
    weaken($weak);
    my %options = (
        %{ $self->{websocket_options} },
        loop => $self->{loop},
        on_text => sub { $weak->_receive( $_[0], $generation ) if $weak },
        on_close => sub { $weak->_closed( $_[0], $generation ) if $weak }
    );

    # Validate injected adapters before using their asynchronous transport methods.
    my $websocket = eval {
              $self->{websocket_factory}
            ? $self->{websocket_factory}->(%options)
            : Discord::Client::Gateway::WebSocket->new(%options);
    };
    unless ( blessed($websocket)
        && $websocket->can('connect')
        && $websocket->can('send')
        && $websocket->can('abort')
        && $websocket->can('close') )
    {
        $self->_fatal( 'Invalid Gateway transport', 'transport' );
        return;
    }

    # Bound connection establishment and HELLO receipt with one handshake deadline.
    $self->{websocket} = $websocket;
    $self->{state} = 'connecting';
    $self->_timer(
        handshake => $self->{connect_timeout},
        sub {
            $self->_reconnect( 0, 'Gateway handshake timed out', 'timeout' );
        }
    );
    my $connect = eval { $websocket->connect( $uri->as_string ) };
    unless ( blessed($connect) && $connect->isa('Future') ) {
        $self->_reconnect( 0, 'Gateway connection failed', 'transport' );
        return;
    }
    $self->{connection_future} = $connect;

    # Enter the protocol handshake only after WebSocket connection succeeds.
    $connect->on_ready(
        sub {
            return if $self->{closed} || $generation != $self->{generation};
            delete $self->{connection_future};
            if ( $connect->is_done ) {
                $self->{session}->opened;
                $self->{state} = 'awaiting_hello';
                $self->_diagnostic('connected');
            }
            else {
                $self->_reconnect( 0, 'Gateway connection failed', 'transport' );
            }
        }
    );
}

sub _receive {
    my ( $self, $text, $generation ) = @_;
    return if $self->{closed} || $generation != $self->{generation};

    # Decode and validate the packet before applying any transport actions.
    my $packet = eval { JSON::PP->new->decode($text) };
    my $actions = !$@ ? eval { $self->{session}->receive($packet) } : undef;
    if ( !$actions || $@ ) {
        $self->_reconnect( 0, 'Invalid Gateway packet', 'protocol' );
        return;
    }

    # HELLO ends the connection deadline; Identify may wait on a shared permit.
    if ( $packet->{op} == 10 ) {
        $self->{state} = 'authenticating';
        $self->_cancel_timer('handshake');
    }

    # Measure heartbeat acknowledgement latency independently of event callbacks.
    if ( $packet->{op} == 11 && defined( $self->{heartbeat_sent_at} ) ) {
        $self->{heartbeat_latency} = $self->{clock}->() - $self->{heartbeat_sent_at};
        $self->_diagnostic('heartbeat_ack');
    }
    $self->_actions( $actions, $packet );
}

sub _actions {
    my ( $self, $actions, $packet ) = @_;

    # Execute protocol decisions in order, stopping if a callback closes the Gateway.
    for my $action (@$actions) {
        last if $self->{closed};
        if ( $action->{action} eq 'heartbeat_schedule' ) {
            $self->{heartbeat_interval} = $action->{interval_ms} / 1000;
            $self->_timer( heartbeat => $action->{first_delay_ms} / 1000, sub { $self->_heartbeat } );
        }
        elsif ( $action->{action} eq 'send' ) {
            my $payload = $action->{payload};
            if ( $payload->{op} == 2 ) {
                $self->_identify($payload);
            }
            else {
                $self->_protocol_send($payload);
            }
        }
        elsif ( $action->{action} eq 'event' ) {

            # A ready session clears authentication timeout and begins the stability window.
            if ( $action->{name} eq 'READY' || $action->{name} eq 'RESUMED' ) {
                $self->{state} = 'ready';
                $self->_timer( stable => $self->{stable_after}, sub { $self->{attempts} = 0 } )
                    if $self->{attempts};
                $self->_cancel_timer('handshake');
                $self->_diagnostic( lc $action->{name} );
            }
            $self->_dispatch( $action->{name}, $action->{data}, $packet );
            if ( $action->{name} eq 'READY' || $action->{name} eq 'RESUMED' ) {

                # Startup observers see Client state updated from the same packet.
                my $ready = delete $self->{ready_future};
                $ready->done($self) if $ready && !$ready->is_ready && !$self->{closed};
            }
        }
        elsif ( $action->{action} eq 'reconnect' ) {
            $self->_reconnect(
                $action->{delay_ms} / 1000,
                'Gateway session reconnect requested',
                'reconnect', $packet && $packet->{op} == 7
            );
            last;
        }
        elsif ( $action->{action} eq 'opcode' ) {
            $self->_dispatch( 'OPCODE', { op => $action->{op}, d => $action->{data} }, $packet );
        }
    }
}

sub _heartbeat {
    my ($self) = @_;
    return if $self->{closed} || !$self->{websocket};

    # A missed acknowledgement can replace the connection instead of sending a beat.
    my $generation = $self->{generation};
    $self->_actions( $self->{session}->heartbeat_due );
    return if $generation != $self->{generation} || $self->{closed};
    $self->_timer( heartbeat => $self->{heartbeat_interval}, sub { $self->_heartbeat } );
}

sub _identify {
    my ( $self, $payload ) = @_;

    # Acquire a shared Identify permit without blocking heartbeat processing.
    my $generation = $self->{generation};
    my $grant = $self->{identify_limiter}->acquire( $self->{shard_id} );
    $self->{identify_future} = $grant;
    $grant->on_ready(
        sub {
            delete $self->{identify_future} if $generation == $self->{generation};
            if ( $grant->is_done ) {
                my ($permit) = $grant->result;
                if ( $self->{closed} || $generation != $self->{generation} ) {
                    $permit->cancel;
                    return;
                }
                $self->_protocol_send( $payload, $permit );
            }
            elsif ( !$grant->is_cancelled && !$self->{closed} && $generation == $self->{generation} ) {
                $self->_fatal( 'Gateway Identify scheduling failed', 'identify' );
            }
        }
    );
}

sub _protocol_send {
    my ( $self, $payload, $permit ) = @_;

    # Protocol writes have priority and reconnect if their delivery fails.
    my $generation = $self->{generation};
    my $future = $self->_queue_send( $payload, protocol => 1, permit => $permit );
    $future->on_ready(
        sub {
            return if $self->{closed} || $generation != $self->{generation};
            if ( !$future->is_done ) {
                $self->_reconnect( 0, 'Gateway protocol write failed', 'transport' );
            }
        }
    );
}

sub send {
    my ( $self, $op, $data ) = @_;

    # Application sends cannot bypass the internal authentication or heartbeat paths.
    return $self->_failed( 'Gateway is closed', 'shutdown' ) if $self->{closed};
    return $self->_failed( 'Gateway is not ready', 'state' ) unless $self->{state} eq 'ready';
    return $self->_failed( 'Invalid Gateway opcode', 'request' )
        unless defined($op) && !ref($op) && $op =~ /\A\d+\z/ && $op != 1 && $op != 2 && $op != 6;
    return $self->_queue_send( { op => 0 + $op, d => $data } );
}

sub _queue_send {
    my ( $self, $payload, %options ) = @_;
    my $permit = $options{permit};
    my $is_protocol = $options{protocol} // 0;

    # Reject disconnected, oversized or excess writes before consuming a permit.
    my $future = $self->{loop}->new_future;
    unless ( $self->{websocket} ) {
        $permit->cancel if $permit;
        return $self->_fail( $future, 'Gateway is disconnected', 'state' );
    }
    my $text = eval { JSON::PP->new->encode($payload) };
    if ( $@ || length( encode( 'UTF-8', $text ) ) > MAX_PAYLOAD_BYTES ) {
        $permit->cancel if $permit;
        return $self->_fail( $future, 'Gateway payload is invalid or exceeds 4096 bytes', 'request' );
    }
    if ( @{ $self->{outgoing} } + ( $self->{active_write} ? 1 : 0 ) >= $self->{max_outgoing} ) {
        $permit->cancel if $permit;
        return $self->_fail( $future, 'Gateway write queue capacity exceeded', 'queue_full' );
    }

    # Keep protocol traffic ahead of application writes within one serialized queue.
    my $job = { future => $future, text => $text, permit => $permit, op => $payload->{op}, protocol => $is_protocol };
    if ($is_protocol) {
        unshift @{ $self->{outgoing} }, $job;
    }
    else {
        push @{ $self->{outgoing} }, $job;
    }

    # Queued writes can be removed; cancelling an active write makes delivery uncertain.
    $future->on_cancel(
        sub {
            @{ $self->{outgoing} } = grep { $_ != $job } @{ $self->{outgoing} };
            $permit->cancel if $permit;
            if ( $self->{active_write} && $self->{active_write} == $job ) {
                $self->_reconnect( 0, 'Active Gateway write cancelled', 'transport' );
            }
        }
    );
    $self->_drain_writes;
    return $future;
}

sub _drain_writes {
    my ($self) = @_;
    return if $self->{active_write} || $self->{draining_writes} || !$self->{websocket} || $self->{closed};

    # Synchronous transport completion must not recursively drain the same queue.
    local $self->{draining_writes} = 1;
    while ( @{ $self->{outgoing} } && $self->{websocket} && !$self->{active_write} && !$self->{closed} ) {
        my $now = $self->{clock}->();
        @{ $self->{send_times} } = grep { $_ > $now - OUTGOING_WINDOW_SECONDS } @{ $self->{send_times} };
        my $limit = $self->_outgoing_limit( $self->{outgoing}[0]{protocol} );
        if ( @{ $self->{send_times} } >= $limit ) {
            $self->_timer(
                outbound => $self->{send_times}[0] + OUTGOING_WINDOW_SECONDS - $now,
                sub { $self->_drain_writes }
            );
            last;
        }
        my $job = shift @{ $self->{outgoing} };
        last unless $self->_start_write($job);
    }
    $self->_cancel_timer('outbound') unless @{ $self->{outgoing} };
}

sub _outgoing_limit {
    my ( $self, $is_protocol ) = @_;
    return MAX_SENDS_PER_WINDOW if $is_protocol;

    # Application traffic leaves room for scheduled heartbeats and additional protocol writes.
    # The three extra slots are local safety headroom; they do not increase the server quota.
    my $reserved_sends = 4;
    if ( $self->{heartbeat_interval} ) {
        my $expected_heartbeats = int( OUTGOING_WINDOW_SECONDS / $self->{heartbeat_interval} );
        $reserved_sends = $expected_heartbeats + 3;
    }

    # Even very short heartbeat intervals leave one slot for application traffic.
    $reserved_sends = MAX_SENDS_PER_WINDOW - 1 if $reserved_sends >= MAX_SENDS_PER_WINDOW;
    return MAX_SENDS_PER_WINDOW - $reserved_sends;
}

sub _start_write {
    my ( $self, $job ) = @_;

    # Commit Identify immediately before sending, then account for connection quota.
    $self->{active_write} = $job;
    my $generation = $self->{generation};
    $job->{permit}->commit if $job->{permit};
    return 0 if $self->{closed} || $generation != $self->{generation};
    if ( $job->{op} == 1 ) {
        $self->{heartbeat_sent_at} = $self->{clock}->();
        $self->_diagnostic('heartbeat_sent');
    }
    return 0 if $self->{closed} || $generation != $self->{generation};

    push @{ $self->{send_times} }, $self->{clock}->();

    # Translate adapter exceptions into a failed write and a connection reset.
    my $write_future = eval { $self->{websocket}->send( $job->{text} ) };
    unless ( blessed($write_future) && $write_future->isa('Future') ) {
        delete $self->{active_write};
        $self->_fail( $job->{future}, 'Gateway write failed', 'transport' );
        $self->_reconnect( 0, 'Gateway write failed', 'transport' );
        return 0;
    }

    # Authentication timeout starts at send time, after any Identify scheduling delay.
    if ( $job->{op} =~ /\A(?:2|6)\z/ && $self->{state} ne 'ready' && !$self->{closed} ) {
        $self->_timer(
            handshake => $self->{connect_timeout},
            sub {
                $self->_reconnect( 0, 'Gateway authentication timed out', 'timeout' );
            }
        );
    }
    $job->{write_future} = $write_future;
    $write_future->on_ready( sub { $self->_complete_write( $job, $write_future, $generation ) } );
    return 1;
}

sub _complete_write {
    my ( $self, $job, $write_future, $generation ) = @_;
    return if $generation != $self->{generation} || $self->{closed};

    # Release the active slot before notifying callers that can enqueue more writes.
    delete $self->{active_write};
    if ( !$job->{future}->is_ready ) {
        if ( $write_future->is_done ) {
            $job->{future}->done;
        }
        else {
            $self->_fail( $job->{future}, 'Gateway write failed', 'transport' );
        }
    }
    $self->_reconnect( 0, 'Gateway write failed', 'transport' ) unless $write_future->is_done;
    $self->_drain_writes;
}

sub _closed {
    my ( $self, $code, $generation ) = @_;
    return if $self->{closed} || $generation != $self->{generation};

    # Fatal Discord close codes terminate the lifetime; recoverable closes reconnect.
    my $actions = $self->{session}->closed($code);
    if ( @$actions && $actions->[0]{action} eq 'fatal' ) {
        $self->_fatal( 'Discord rejected the Gateway session', 'gateway_close', close_code => $code );
    }
    else {
        $self->_reconnect( 0, 'Gateway connection closed', 'transport' );
    }
}

sub _reconnect {
    my ( $self, $minimum, $message, $category, $immediate ) = @_;
    return if $self->{closed} || $self->{state} eq 'reconnecting';

    # Notify the caller before teardown, allowing the error hook to request shutdown.
    $self->_report( $message, $category );
    return if $self->{closed};
    $self->_teardown;
    $self->{session}->closed(1006);
    $self->{state} = 'reconnecting';

    # Bound exponential backoff and jitter; explicit server reconnects may be immediate.
    my $attempt = $self->{attempts}++;
    $attempt = 16 if $attempt > 16;
    my $base = $self->{backoff_base} * ( 2**$attempt );
    $base = $self->{backoff_max} if $base > $self->{backoff_max};
    my $random = $self->{random}->();
    $random = 0.5
        unless defined($random)
        && !ref($random)
        && $random =~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/
        && $random >= 0
        && $random < 1;
    my $after = $base * ( 0.5 + 0.5 * $random );
    $after = 0 if $immediate && $attempt == 0;
    $after = $minimum if $minimum > $after;
    $self->_diagnostic( 'reconnect_scheduled', after => $after );
    $self->_timer( reconnect => $after, sub { $self->_open } );
}

sub _dispatch {
    my ( $self, $event, $data, $packet ) = @_;
    return if $self->{closed};
    my $received_at = $self->{clock}->();

    # Cache updates and interaction admission must survive application overload.
    for my $observer ( @{ $self->{dispatch_observers} } ) {
        my $ok = eval {
            $observer->( $event, $data, $self, $packet, $received_at );
            1;
        };
        $self->_report( 'Gateway dispatch observer failed', 'handler', event => $event ) unless $ok;
        return if $self->{closed};
    }

    # Queue each application listener separately after SDK observers have run.
    my @jobs;
    for my $callback ( @{ $self->{handlers}{$event} // [] } ) {
        push @jobs,
            {
                callback => $callback,
                args => [ $data, $self, $packet, $received_at ],
                event => $event,
            };
    }
    for my $callback ( @{ $self->{handlers}{'*'} // [] } ) {
        push @jobs,
            {
                callback => $callback,
                args => [ $event, $data, $self, $packet, $received_at ],
                event => $event,
            };
    }

    # Drop the whole application event on overflow and report once per saturated queue.
    if ( @{ $self->{event_queue} } + @jobs > $self->{max_events} ) {
        ++$self->{counters}{dropped_events};
        $self->{counters}{dropped_callbacks} += @jobs;
        unless ( $self->{event_overflow_reported} ) {
            $self->{event_overflow_reported} = 1;
            $self->_report( 'Gateway event queue capacity exceeded; event dropped', 'queue_full' );
        }
        return;
    }
    push @{ $self->{event_queue} }, @jobs;
    $self->_schedule_handlers;
}

sub _schedule_handlers {
    my ($self) = @_;
    return if $self->{handler_scheduled} || $self->{closed} || !@{ $self->{event_queue} };

    # Defer application callbacks so packet processing can finish first.
    $self->{handler_scheduled} = 1;
    $self->{defer}->(
        sub {
            delete $self->{handler_scheduled};
            $self->_drain_handlers;
        }
    );
}

sub _drain_handlers {
    my ($self) = @_;
    return if $self->{closed} || $self->{draining_handlers};

    # Admit callbacks up to the pending-Future limit without recursive draining.
    local $self->{draining_handlers} = 1;
    while ( @{ $self->{event_queue} } && keys( %{ $self->{handler_futures} } ) < $self->{max_handlers} ) {
        my $job = shift @{ $self->{event_queue} };
        my $result = eval { $job->{callback}->( @{ $job->{args} } ) };
        if ($@) {
            $self->_report( 'Gateway event handler failed', 'handler', event => $job->{event} );
            next;
        }
        if ( $self->{closed} ) {

            # Work returned by a closing handler has not yet entered our registry.
            # Preserve close itself so its transport handshake can finish.
            $result->cancel
                if blessed($result)
                && $result->isa('Future')
                && !$result->is_ready
                && ( !$self->{close_future} || $result != $self->{close_future} );
            last;
        }

        # Keep handler work alive until settled and resume queued callbacks afterward.
        if ( blessed($result) && $result->isa('Future') ) {
            my $id = refaddr($job);
            $self->{handler_futures}{$id} = $result;
            $result->on_ready(
                sub {
                    delete $self->{handler_futures}{$id};
                    if ( !$result->is_done && !$self->{closed} ) {
                        $self->_report( 'Gateway event handler failed', 'handler', event => $job->{event} );
                    }
                    $self->_schedule_handlers;
                }
            );
        }
    }
    delete $self->{event_overflow_reported} unless @{ $self->{event_queue} };
}

sub _timer {
    my ( $self, $name, $after, $callback ) = @_;

    # Only one timer per purpose may act on the current connection generation.
    $self->_cancel_timer($name);
    my $generation = $self->{generation};
    my $timer = $self->{delay}->($after);
    $self->{timers}{$name} = $timer;
    $timer->on_done(
        sub {
            delete $self->{timers}{$name};
            $callback->() unless $self->{closed} || $generation != $self->{generation};
        }
    );
}

sub _cancel_timer {
    my ( $self, $name ) = @_;

    # Detach the timer before cancellation can invoke callbacks that re-enter the driver.
    if ( my $timer = delete $self->{timers}{$name} ) {
        $timer->cancel unless $timer->is_ready;
    }
}

sub _teardown {
    my ($self) = @_;

    # Invalidate old callbacks before cancelling timers and in-flight operations.
    ++$self->{generation};
    $self->_cancel_timer($_) for keys %{ $self->{timers} };
    for my $name (qw(connection_future identify_future discovery)) {
        if ( my $future = delete $self->{$name} ) {
            $future->cancel unless $future->is_ready;
        }
    }

    # Detach queued writes before failing them; completion hooks may re-enter the driver.
    my @writes = @{ $self->{outgoing} };
    $self->{outgoing} = [];
    push @writes, delete( $self->{active_write} ) if $self->{active_write};
    for my $job (@writes) {
        $job->{permit}->cancel if $job->{permit};
        $job->{write_future}->cancel if $job->{write_future} && !$job->{write_future}->is_ready;
        $self->_fail( $job->{future}, 'Gateway disconnected before write completed', 'transport' )
            unless $job->{future}->is_ready;
    }

    # Connection-local timing and quota must not leak into the replacement socket.
    delete @{$self}{qw(heartbeat_interval heartbeat_sent_at)};
    $self->{send_times} = [];
    my $websocket = delete $self->{websocket};
    $websocket->abort if $websocket;
}

sub _fail {
    my ( $self, $future, $message, $category, %fields ) = @_;
    my $error = Discord::Client::Error->new( message => $message, category => $category, %fields );
    return $future->fail( $message, $category, $error );
}

sub _failed {
    my ( $self, @args ) = @_;
    return $self->_fail( $self->{loop}->new_future, @args );
}

sub _report {
    my ( $self, $message, $category, %fields ) = @_;

    # Surface structured errors without forwarding raw exceptions or protocol payloads.
    my $error = Discord::Client::Error->new( message => $message, category => $category, %fields );
    ++$self->{counters}{errors};
    if ( $self->{on_error} ) {
        my $ok = eval {
            $self->{on_error}->( $error, $self );
            1;
        };
        warn "Gateway error handler failed\n" unless $ok;
    }
    else {
        warn "$message\n";
    }
    return $error;
}

sub _diagnostic {
    my ( $self, $type, %fields ) = @_;

    # Diagnostics are optional observations and cannot interrupt protocol processing.
    ++$self->{counters}{$type};
    return unless $self->{on_diagnostic};
    my $ok = eval {
        $self->{on_diagnostic}->( { type => $type, %fields, state => $self->{state} } );
        1;
    };
    warn "Gateway diagnostic handler failed\n" unless $ok;
}

sub _fatal {
    my ( $self, $message, $category, %fields ) = @_;
    return if $self->{closed};

    # Fail startup and lifetime before closing so fatal failures remain observable.
    my $error = $self->_report( $message, $category, %fields );
    $self->{fatal_error} = $error;
    $self->_fail( $self->{ready_future}, $message, $category, %fields )
        if $self->{ready_future} && !$self->{ready_future}->is_ready;
    $self->_fail( $self->{completion}, $message, $category, %fields ) unless $self->{completion}->is_ready;
    $self->close;
}

sub close {
    my ($self) = @_;
    return $self->{close_future} if $self->{close_future};

    # Publish the shutdown Future before cancelling anything that can re-enter close.
    my $result = $self->{loop}->new_future;
    $self->{close_future} = $result;
    $self->{closed} = 1;
    $self->{state} = 'closed';

    # Detach the live socket so teardown cannot abort the graceful close handshake.
    my $websocket = delete $self->{websocket};
    $self->_teardown;
    $self->{session}->stop;
    $self->_fail( $self->{ready_future}, 'Gateway closed before READY', 'shutdown' )
        if $self->{ready_future} && !$self->{ready_future}->is_ready;

    # Drop queued notifications and cancel pending handlers before releasing owned resources.
    $self->{event_queue} = [];
    $self->{dispatch_observers} = [];
    my @handlers = values %{ $self->{handler_futures} };
    $self->{handler_futures} = {};
    for my $future (@handlers) {
        $future->cancel unless $future->is_ready;
    }
    $self->{identify_limiter}->close if $self->{own_limiter};
    $self->{rest}->close if $self->{own_rest};

    # Await transport shutdown, converting adapter exceptions into a sanitized failure.
    my $closing = $websocket ? eval { $websocket->close(1000) } : $self->{loop}->new_future->done;

    if ( !blessed($closing) || !$closing->isa('Future') ) {
        $websocket->abort if $websocket;
        $self->_fail( $result, 'Gateway shutdown failed', 'transport' );
        $self->{completion}->done unless $self->{completion}->is_ready;
        return $result;
    }
    $closing->on_ready(
        sub {
            $self->{completion}->done unless $self->{completion}->is_ready;
            return if $result->is_ready;
            $closing->is_done ? $result->done : $self->_fail( $result, 'Gateway shutdown failed', 'transport' );
        }
    );

    # Explicit shutdown cancellation aborts the socket and ends the lifetime wait.
    $result->on_cancel(
        sub {
            $closing->cancel unless $closing->is_ready;
            $websocket->abort if $websocket;
            $self->{completion}->done unless $self->{completion}->is_ready;
        }
    );
    return $result;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Gateway - Discord Gateway connections and events

=head1 SYNOPSIS

    use Discord::Client::Gateway;

    # Configure the connection.
    my $gateway = Discord::Client::Gateway->new(
        token => $ENV{DISCORD_BOT_TOKEN}, loop => $loop, intents => ['GUILDS'],
    );

    # Return asynchronous work from the event handler.
    $gateway->on(MESSAGE_CREATE => sub {
        my ($data, $gateway, $packet) = @_;
        return handle_message($data);
    });

    # Start on the application's loop.
    my $ready = $gateway->connect;

=head1 DESCRIPTION

Receives L<Discord v10 JSON events|https://docs.discord.com/developers/events/gateway>
and manages the WebSocket connection, heartbeats, Resume and reconnects.
Use it independently or through L<Discord::Client>.
The caller drives the loop. Standalone Gateway intents default to zero.

=head1 METHODS

=head2 new

C<new(token =E<gt> $token, loop =E<gt> $loop, intents =E<gt> ['GUILDS'])>
returns a Gateway without I/O. C<loop> is optional; otherwise one is created.
Intents accept a bitmask or arrayref of names. Set intents for the events you need.
C<rest> and C<identify_limiter> can inject caller-owned discovery resources.
C<shard =E<gt> [$id, $total]> selects a shard.

=head2 connect

Discovers C</gateway/bot>, opens a verified TLS WebSocket and returns a Future
resolving to the Gateway on READY or RESUMED. During reconnects, it waits for
the next ready session. Cancelling it closes the Gateway.

=head2 completion

Returns the lifetime Future, resolving on orderly shutdown and failing on
fatal errors.

=head2 close

Returns a Future waiting for transport shutdown. Cancels timers, writes and
handlers. Repeated calls return the same Future. Injected REST clients and
Identify limiters remain caller-owned.

=head2 on

C<on(EVENT =E<gt> CODE)> registers an event callback and returns the Gateway.
Callbacks and failure handling are described under L</EVENTS AND FAILURES>.

=head2 send

C<send(opcode, data)> returns a Future completing after the write, only while
ready. Heartbeat, Identify and Resume are driver-managed. Payloads must fit
4096 bytes. The SDK limits traffic to 120 payloads per 60 seconds and reserves
capacity for protocol traffic.

Cancelling removes an unsent write. Cancelling an active write resets the
connection because delivery is uncertain. Application writes are not replayed.

=head2 state

Returns the connection state string.

=head2 loop

Returns the IO::Async::Loop.

=head2 session

Returns the internal protocol object. Use events for application work.

=head2 identify_limiter

Returns the internal Identify scheduler. Its API is not a public contract.

=head2 stats

Returns a hashref of counters, queue sizes and heartbeat latency.

=head1 EVENTS AND FAILURES

Event names are uppercase. Callbacks receive C<($data, $gateway, $packet)>.
C<on('*' =E<gt> CODE)> receives C<($event, $data, $gateway, $packet)>.
Unknown events and fields are preserved; unknown opcodes produce C<OPCODE>
with C<{op, d}>.

Return handler Futures. Pending Futures do not delay heartbeats or incoming
packets, but blocking Perl code blocks the loop. Thrown exceptions and failed
Futures produce C<handler> errors without stopping the connection.

C<on_error =E<gt> CODE> receives C<($error, $gateway)> synchronously. Without it,
the SDK warns with a generic message. Errors omit raw frames, exceptions and
credentials. Fatal L<close codes|https://docs.discord.com/developers/topics/opcodes-and-status-codes> appear in C<close_code> and stop reconnecting.

When the callback queue is full, the incoming event's application callbacks are
dropped. Through L<Discord::Client>, SDK cache and READY state updates and
interaction dispatch occur before this queue and are preserved. Interaction
dispatch still has its own bounded capacity.
A C<queue_full> error is reported once per saturation episode; C<stats> counts
all C<dropped_events> and C<dropped_callbacks>. Earlier work continues. Dropped
events are not replayed; applications needing a complete stream must reconcile
state. Each callback invocation uses capacity, even with a shared Future.

=head1 RECONNECTS AND IDENTIFY

The SDK schedules heartbeats from HELLO and reconnects if ACK is missing.
Resume uses the saved URL, session ID and sequence. Non-resumable sessions
Identify again; fatal close codes stop the driver.
Reconnects use jittered backoff, reset after stable operation. Opcode 7 starts
the first Resume attempt immediately. Compression is not requested.

C<shard =E<gt> [$id, $total]> selects a shard. Identify uses session-start metadata
from C</gateway/bot> and a five-second cooldown per concurrency bucket.
The cooldown starts when Identify is sent. Resume consumes no session start.
Exhausted budgets wait for reset and refresh metadata. An exhausted budget with
zero C<reset_after> refreshes every second until starts or a positive delay
become available. Heartbeats continue during Identify waits.

For several shards, use L<the shard manager|Discord::Client::Gateway::Shards>. Identify coordination
is local to one process; separate processes need external coordination.

=head1 OPTIONS

=over 4

=item C<max_outgoing>

Queued and active writes; default 128.

=item C<max_events>

Queued callback invocations; default 1024.

=item C<max_handlers>

Pending callback invocations; default 64.

=item C<connect_timeout>

Seconds for connection/HELLO or sent authentication; default 30.

=item C<backoff_base>

Initial backoff in seconds; default 1.

=item C<backoff_max>

Maximum backoff in seconds; default 60.

=item C<stable_after>

Seconds before resetting backoff; default 60.

=back

Identify waiting is excluded from the authentication timeout.
C<stats> returns counters, queue sizes and heartbeat latency. C<on_diagnostic>
receives synchronous events with state and reconnect timing, without raw payloads.

=head1 TRANSPORT INJECTION

C<websocket_factory> receives C<loop>, C<on_text> and C<on_close>. Its transport
provides Future-returning C<connect($url)>, C<send($unicode_json)>, C<abort> and
C<close($code)>. Resolve connection before delivering text. C<abort> stops I/O;
C<close> waits for cleanup. C<on_close> supplies a numeric code without raw reason
text. Pathless Gateway URLs use C</> for the handshake.

C<clock>, C<delay>, C<defer> and C<random> hooks allow deterministic tests.
C<websocket_options =E<gt> {tls =E<gt> {...}}> can supply a local test CA; peer and
hostname verification remain enabled. The adapter accepts frames up to 16 MiB.

=head1 LICENSE

Apache License 2.0.

=cut
