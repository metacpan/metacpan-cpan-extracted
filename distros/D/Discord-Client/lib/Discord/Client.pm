package Discord::Client;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Future;
use IO::Async::Loop;
use Scalar::Util qw(blessed weaken);

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Validate callback limits before constructing owned resources.
    croak 'on_error must be a code reference' if exists( $args{on_error} ) && ref( $args{on_error} ) ne 'CODE';
    croak 'max_callbacks must be a positive integer'
        if exists( $args{max_callbacks} )
        && (  !defined( $args{max_callbacks} )
            || ref( $args{max_callbacks} )
            || $args{max_callbacks} !~ /\A[1-9]\d*\z/ );

    # Load the independently usable components and share one event loop.
    require Discord::Client::REST;
    require Discord::Client::Gateway;
    require Discord::Client::Commands;
    require Discord::Client::Interactions;
    my $loop = $args{loop} // IO::Async::Loop->new;
    my $self = bless {
        loop => $loop,
        handlers => {},
        callbacks => {},
        on_error => $args{on_error},
        max_callbacks => $args{max_callbacks} // 1024,
    }, $class;

    # Child callbacks must not keep the client alive through an ownership cycle.
    my $weak = $self;
    weaken($weak);

    # Share REST across commands and interactions; only close a client we create.
    $self->{cache} = _create_cache( $args{cache} );
    $self->{rest} = $args{rest} // Discord::Client::REST->new(
        token => $args{token},
        loop => $loop,
        %{ $args{rest_options} // {} }
    );
    $self->{own_rest} = !$args{rest};
    $self->{commands} = Discord::Client::Commands->new(
        rest => $self->{rest},
        loop => $loop,
        application_id => $args{application_id}
    );
    $self->{interactions} = Discord::Client::Interactions->new(
        commands => $self->{commands},
        rest => $self->{rest},
        loop => $loop,
        %{ $args{interaction_options} // {} },
        on_error => sub { $weak->_report( $_[0], $_[1] ) if $weak }
    );

    # Keep connection options separate from interaction admission limits.
    my %gateway_options = (
        %{ $args{gateway_options} // {} },
        token => $args{token},
        rest => $self->{rest},
        loop => $loop,
        intents => $args{intents} // ['GUILDS'],
        on_error => sub { $weak->_report( $_[0] ) if $weak }
    );
    $self->{gateway} = _create_gateway( \%args, \%gateway_options );

    # Apply SDK state before admitting application callbacks to the bounded queue.
    $self->{gateway}->_on_dispatch(
        sub {
            return unless $weak;
            $weak->_receive_gateway_event(@_);
        }
    );

    # Forward application notifications through the client callback lifecycle.
    $self->{gateway}->on(
        '*' => sub {
            my ( $event, $data, $gateway, $packet ) = @_;
            $weak->_emit( $event, $data, $packet ) if $weak;
            return;
        }
    );
    return $self;
}

sub _create_cache {
    my ($cache) = @_;

    # Reuse a supplied cache or construct an explicitly enabled one.
    return undef unless $cache;
    require Discord::Client::Cache;

    return $cache if blessed($cache) && $cache->isa('Discord::Client::Cache');
    croak 'cache must be a boolean, options hash or Cache object'
        if ref($cache) && ref($cache) ne 'HASH';
    my %options = ref($cache) eq 'HASH' ? %$cache : ();
    return Discord::Client::Cache->new(%options);
}

sub _create_gateway {
    my ( $args, $options ) = @_;

    # Choose one connection owner without starting network I/O.
    return $args->{gateway} if $args->{gateway};
    if ( exists $args->{shards} ) {
        require Discord::Client::Gateway::Shards;
        return Discord::Client::Gateway::Shards->new( %$options, shards => $args->{shards} );
    }
    return Discord::Client::Gateway->new(%$options);
}

sub _receive_gateway_event {
    my ( $self, $event, $data, $gateway, $packet, $received_at ) = @_;

    # Publish READY state before startup observers or application handlers run.
    $self->{cache}->apply( $event, $data ) if $self->{cache};
    if ( $event eq 'READY' ) {
        $self->{user} = $data->{user};
        $self->{commands}->application_id( $data->{application}{id} )
            if ref( $data->{application} ) eq 'HASH' && defined( $data->{application}{id} );
    }

    # Interaction admission has its own limit, independent of event callbacks.
    $self->_dispatch_interaction( $data, $received_at ) if $event eq 'INTERACTION_CREATE';
    return;
}

sub _dispatch_interaction {
    my ( $self, $data, $received_at ) = @_;

    # Pass receipt time through so queue delays count toward acknowledgement expiry.
    my %options = ( acknowledgement_only => 1 );
    $options{received_at} = $received_at if defined $received_at;
    my $acknowledgement = $self->{interactions}->handle( $data, %options );
    my $weak = $self;
    weaken($weak);

    # Report admission errors here; the dispatcher reports admitted handler errors.
    $acknowledgement->on_fail(
        sub {
            my ( undef, undef, $error ) = @_;
            return unless $weak && !$weak->{closed} && blessed($error);
            if ( $error->category eq 'protocol' || $error->category eq 'queue_full' ) {
                $weak->_report($error);
            }
        }
    );

    return $acknowledgement;
}

# These accessors expose shared components without fetching or copying resources.
sub loop { $_[0]->{loop} }
sub rest { $_[0]->{rest} }
sub gateway { $_[0]->{gateway} }
sub commands { $_[0]->{commands} }
sub interactions { $_[0]->{interactions} }
sub user { $_[0]->{user} }
sub cache { $_[0]->{cache} }

sub model {
    my ( $self, $type, $data ) = @_;
    require Discord::Client::Model;
    return Discord::Client::Model->wrap( $type, $data, rest => $self->{rest} );
}

sub stats {
    my ($self) = @_;

    # Expose counters without including credentials or event payloads.
    return {
        rest => $self->{rest}->stats,
        gateway => $self->{gateway}->stats,
        callbacks => scalar( keys %{ $self->{callbacks} } ),
        ( $self->{cache} ? ( cache => $self->{cache}->stats ) : () )
    };
}

sub command {
    my ( $self, @args ) = @_;
    $self->{commands}->define(@args);
    return $self;
}

sub component {
    my ( $self, @args ) = @_;
    $self->{commands}->component(@args);
    return $self;
}

sub on {
    my ( $self, $event, $callback ) = @_;

    # Normalize event names once so registration and delivery use the same keys.
    croak 'Event and callback are required' unless defined($event) && !ref($event) && ref($callback) eq 'CODE';
    push @{ $self->{handlers}{ uc($event) } }, $callback;
    return $self;
}

sub on_message {
    my ( $self, $callback ) = @_;
    croak 'Message callback must be a code reference' unless ref($callback) eq 'CODE';

    # Reuse event lifetime/error handling while presenting a REST-backed snapshot.
    return $self->on(
        MESSAGE_CREATE => sub {
            my ( $data, $packet, $bot ) = @_;
            my $message = $bot->model( message => $data );
            return $callback->( $message, $bot );
        }
    );
}

sub _emit {
    my ( $self, $event, @data ) = @_;
    return if $self->{closed};

    # Bound pending work before invoking another application callback.
    for my $callback ( @{ $self->{handlers}{ uc($event) } // [] } ) {
        last if $self->{closed};
        if ( keys( %{ $self->{callbacks} } ) >= $self->{max_callbacks} ) {
            $self->_report_error( 'Client event callback capacity exceeded', 'queue_full' );
            last;
        }

        # Isolate synchronous exceptions so later listeners can still run.
        my $future = eval { $callback->( @data, $self ) };
        if ($@) {
            $self->_report_error( 'Client event handler failed', 'handler' );
            next;
        }
        if ( $self->{closed} ) {

            # A callback may return close itself; let that shutdown finish.
            $future->cancel
                if blessed($future)
                && $future->isa('Future')
                && !$future->is_ready
                && ( !$self->{close_future} || $future != $self->{close_future} );
            last;
        }

        # Retain asynchronous work until completion and report only sanitized failures.
        if ( blessed($future) && $future->isa('Future') ) {
            my $key = ++$self->{callback_id};
            $self->{callbacks}{$key} = $future;
            $future->on_ready(
                sub {
                    delete $self->{callbacks}{$key};
                    $self->_report_error( 'Client event handler failed', 'handler' )
                        if !$future->is_done && !$self->{closed};
                }
            );
        }
    }
}

sub _report_error {
    my ( $self, $message, $category ) = @_;
    require Discord::Client::Error;
    $self->_report( Discord::Client::Error->new( message => $message, category => $category ) );
}

sub _report {
    my ( $self, $error, $context ) = @_;
    return if $self->{closed};

    # Use the configured hooks, falling back to a sanitized warning.
    my @handlers = ( $self->{on_error} ? $self->{on_error} : (), @{ $self->{handlers}{ERROR} // [] } );
    if ( !@handlers ) {
        warn $error->message . "\n";
        return;
    }

    # An error hook must not propagate an exception into the event loop.
    for my $handler (@handlers) {
        my $ok = eval {
            $handler->( $error, $context, $self );
            1;
        };
        warn "Client error handler failed\n" unless $ok;
    }
}

sub start {
    my ($self) = @_;

    # Tie startup cancellation to the lifetime of the whole client.
    my $future = $self->{gateway}->connect->then_done($self);
    $future->on_cancel( sub { $self->close } );
    return $future;
}
sub completion { $_[0]->{gateway}->completion }

sub run {
    my ($self) = @_;

    # Signals are optional on some platforms; remember only installed handlers.
    my @signals;
    for my $signal (qw(INT TERM)) {
        my $id = eval {
            $self->{loop}->attach_signal( $signal => sub { $self->close } );
        };
        push @signals, [ $signal, $id ] if defined $id;
    }

    # Drive startup and lifetime using the same loop-backed Futures.
    my $ran = eval {
        $self->start->get;
        $self->completion->get;
        1;
    };
    my $run_error = $@;

    # Always attempt cleanup, preserving the original failure over cleanup errors.
    my $closed = eval {
        $self->close->get;
        1;
    };
    my $close_error = $@;
    $self->{loop}->detach_signal(@$_) for @signals;
    die $run_error unless $ran;
    die $close_error unless $closed;
    return;
}

sub close {
    my ($self) = @_;
    return $self->{close_future} if $self->{close_future};

    # Stop new callbacks before cancelling work that can invoke completion hooks.
    $self->{closed} = 1;
    $self->{interactions}->close;
    $self->{commands}->close;

    # Detach the registry before cancellation callbacks can re-enter it.
    my @callbacks = values %{ $self->{callbacks} };
    $self->{callbacks} = {};
    for my $future (@callbacks) {
        $future->cancel unless $future->is_ready;
    }

    # Wait for transport shutdown and release only the REST client we own.
    my @closing = ( $self->{gateway}->close );
    push @closing, $self->{rest}->close if $self->{own_rest};
    $self->{handlers} = {};
    return $self->{close_future} = Future->needs_all(@closing);
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client - Discord bots using IO::Async and Future

=head1 SYNOPSIS

    use v5.26;
    use warnings;
    use Discord::Client;

    # Create the bot.
    my $bot = Discord::Client->new(token => $ENV{DISCORD_BOT_TOKEN});

    # Reply to /ping.
    $bot->command(
        ping => (
            description => 'Replies with Pong',
            handler => sub {
                my ($interaction) = @_;
                return $interaction->reply('Pong!');
            },
        ),
    );

    # Run until shutdown.
    $bot->run;

=head1 DESCRIPTION

Build Discord bots with IO::Async and Future. REST, Gateway and HTTP
Interactions can also be used independently. The API is experimental.
This library is unofficial and is not affiliated with or endorsed by Discord.

Declare commands locally and deploy them explicitly with
L<Discord::Client::Commands/sync>. Startup never deploys commands.
Return Futures from handlers so the SDK can report failures and cancel work
on shutdown. Blocking code stops the shared loop.

=head1 METHODS

=head2 new

    my $bot = Discord::Client->new(
        token => $token, loop => $loop, intents => ['GUILDS'],
    );

Returns a client without network I/O. C<token> is the bot token. C<loop> is an
optional IO::Async::Loop; otherwise one is created. C<intents> accepts names
or a bitmask and defaults to C<['GUILDS']>.

C<application_id> can set the command application's ID. C<shards> accepts
C<auto> or a positive count; see L<Discord::Client::Gateway::Shards>.
C<cache> accepts C<1>, an options hash or a L<Discord::Client::Cache> object;
it is disabled by default.

C<rest_options>, C<gateway_options> and C<interaction_options> pass constructor
options to those components. Tests can inject C<rest> and C<gateway> objects.
Shutdown closes an injected Gateway and leaves an injected REST client
caller-owned. C<max_callbacks> defaults to 1024 pending event callback Futures;
excess work reports C<queue_full>.

C<on_error> accepts a synchronous callback receiving
C<($error, $interaction_or_undef, $bot)>. Without an error callback, the SDK
warns with a sanitized message.

=head2 run

Runs startup, Gateway lifetime and shutdown; blocks until stopped.
Handles INT/TERM where supported and removes its signal handlers on exit.
Startup or lifetime errors are raised after shutdown is attempted; otherwise
a shutdown error is raised. Returns no value.

=head2 start

Returns a Future resolving to the client when the Gateway is ready.
Cancelling it closes the client. The caller drives the loop.

=head2 completion

Returns the Gateway lifetime Future. It resolves on orderly shutdown and
fails on a fatal error.

=head2 close

Returns a Future waiting for shutdown. Repeated calls return the same Future.
Cancels handlers and owned network work. Closing from a handler stops later
callbacks and cancels that handler's pending Future, unless it is the Future
returned by C<close> itself. Returning C<close> lets graceful shutdown finish.

=head2 command

    $bot->command(name => description => 'Description', handler => $callback);

Declares a command and returns the client. The callback receives an
L<Discord::Client::Interaction>. Options follow L<Discord::Client::Commands/define>.
Invalid declarations throw before changing the registry.

=head2 component

    $bot->component(custom_id => $callback);

Registers a button, select menu or modal handler receiving an Interaction.
Returns the client.

=head2 on

    $bot->on(MESSAGE_CREATE => sub {
        my ($data, $packet, $bot) = @_;
        return handle_message($data);
    });

Registers an event callback and returns the client. Event names accept either
case. Data is a hashref with unknown fields and string IDs preserved.
Thrown exceptions or failed handler Futures reach the error callbacks.
Gateway callback queue limits may drop these notifications. SDK cache and READY
updates and command dispatch precede this queue; command dispatch is separately
bounded by C<interaction_options>.
C<on(error =E<gt> CODE)> receives the same arguments as C<on_error>.

=head2 on_message

    # Ignore bot messages and return the reply Future.
    $bot->on_message(sub {
        my ($message, $bot) = @_;
        return if $message->is_from_bot;
        return unless $message->content eq '!ping';
        return $message->reply('Pong!');
    });

Registers a callback receiving C<($message, $bot)> and returns the client.
The message is a L<Discord::Client::Model::Message> snapshot using the client's
REST transport. Wrapping performs no request and needs no cache.
Set message intents explicitly and enable Message Content in the Developer
Portal when reading message text. Bot messages are not filtered automatically.
Raw C<MESSAGE_CREATE> callbacks still receive hashrefs.

=head2 model

    my $channel = $bot->model(channel => {id => $channel_id});

Synchronously wraps data with the client's REST transport. Types are C<message>,
C<channel>, C<user> and C<guild>; see L<Discord::Client::Model/wrap>.
Invalid data throws. Wrapping performs no request.

=head2 rest

Returns the L<Discord::Client::REST> client.

=head2 gateway

Returns the L<Discord::Client::Gateway> or L<Discord::Client::Gateway::Shards>.

=head2 commands

Returns the L<Discord::Client::Commands> registry.

=head2 interactions

Returns the L<Discord::Client::Interactions> dispatcher.

=head2 loop

Returns the IO::Async::Loop.

=head2 user

Returns the bot user hashref after READY, or undef before it.

=head2 cache

Returns the configured Cache object, or undef when disabled.

=head2 stats

Returns a hashref of REST, Gateway, pending callback and optional cache counters.
It does not include payloads or credentials.

=head1 EXAMPLES

From a source checkout, set C<DISCORD_BOT_TOKEN> and C<TEST_GUILD_ID>.
Invite the bot with C<bot> and C<applications.commands> scopes and leave the
Interactions Endpoint URL empty for Gateway delivery.

    # Deploy /ping once, then run the bot.
    perl examples/sync-commands.pl examples/ping.pl
    perl examples/ping.pl

Deployment replaces this application's commands in the test server, removing
commands absent from the example. Run one example receiver per bot token.

The L<example scripts|https://github.com/viasnake/Discord-Client/tree/main/examples>
cover arguments, buttons, forms, channels, messages and asynchronous work.
Replace C<ping.pl> in both commands to run a slash-command example.
C<messages.pl> needs no deployment; it selects C<GUILDS>, C<GUILD_MESSAGES>,
C<DIRECT_MESSAGES> and C<MESSAGE_CONTENT>. Enable Message Content in the portal.
C<workflow-await.pl> additionally needs C<cpanm Future::AsyncAwait>.
For dependencies under C<local/>, prefix commands with C<PERL5LIB=local/lib/perl5>.

=head1 LICENSE

Apache License 2.0.

=cut
