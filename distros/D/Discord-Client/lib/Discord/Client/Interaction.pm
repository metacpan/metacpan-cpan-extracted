package Discord::Client::Interaction;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use IO::Async::Loop;
use JSON::PP ();
use Scalar::Util qw(blessed refaddr weaken looks_like_number);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use URI::Escape qw(uri_escape_utf8);
use Discord::Client::Error;
use Discord::Client::REST;

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Validate injected hooks and receipt time before creating timers.
    for my $key (qw(clock delay initial_sender)) {
        croak "$key must be a code reference" if exists( $args{$key} ) && ref( $args{$key} ) ne 'CODE';
    }
    croak 'received_at must be a finite number'
        if exists( $args{received_at} )
        && (  !defined( $args{received_at} )
            || ref( $args{received_at} )
            || !looks_like_number( $args{received_at} )
            || $args{received_at} =~ /(?:inf|nan)/i );

    # Require the routing and token fields shared by supported interaction types.
    my $payload = $args{payload};
    croak 'Invalid interaction payload'
        unless ref($payload) eq 'HASH'
        && _id( $payload->{id} )
        && _id( $payload->{application_id} )
        && defined( $payload->{token} )
        && !ref( $payload->{token} )
        && length( $payload->{token} )
        && defined( $payload->{type} )
        && !ref( $payload->{type} )
        && $payload->{type} =~ /\A[2-5]\z/
        && ref( $payload->{data} ) eq 'HASH';

    # Derive both response deadlines from receipt time, including time spent in queues.
    my $loop = $args{loop} // IO::Async::Loop->new;
    my $clock = $args{clock} // sub { clock_gettime(CLOCK_MONOTONIC) };
    my $received = $args{received_at} // $clock->();
    my $self = bless {
        raw => $payload,
        id => "$payload->{id}",
        application_id => "$payload->{application_id}",
        token => $payload->{token},
        type => 0 + $payload->{type},
        loop => $loop,
        clock => $clock,
        delay => $args{delay} // sub { $loop->delay_future( after => $_[0] ) },
        rest => $args{rest},
        initial_sender => $args{initial_sender},
        deadline => $received + 3,
        expires_at => $received + 900,
        state => 'new',
        operations => {},
        options => {},
        path => [],
        acknowledgement => $loop->new_future,
    }, $class;

    # Parse command values before arming a deadline that could invoke callbacks.
    $self->_parse_options( $payload->{data}{options} // [], 0 );
    croak 'Autocomplete requires a focused value'
        if $self->{type} == 4
        && ( !$self->{focused} || $self->{focused}{type} !~ /\A(?:3|4|10)\z/ );

    # A pending acknowledgement owns the deadline, without making the timer own the context.
    my $weak = $self;
    weaken($weak);
    $self->{acknowledgement}->on_cancel( sub { $weak->close if $weak } );
    my $after = $self->{deadline} - $clock->();
    if ( $after <= 0 ) {
        $self->_expire_initial;
    }
    else {
        $self->{initial_timer} = $self->{delay}->($after);
        $self->{initial_timer}->on_done( sub { $weak->_expire_initial if $weak } );
    }
    return $self;
}

sub _id { defined( $_[0] ) && !ref( $_[0] ) && $_[0] =~ /\A\d+\z/ }

# Payload accessors preserve unknown fields and do not fetch related resources.
sub id { $_[0]->{id} }
sub application_id { $_[0]->{application_id} }
sub type { $_[0]->{type} }
sub raw { $_[0]->{raw} }
sub state { $_[0]->{state} }
sub acknowledgement { $_[0]->{acknowledgement} }
sub responded { $_[0]->{state} ne 'new' && $_[0]->{state} ne 'expired' }
sub options { +{ %{ $_[0]->{options} } } }
sub option { $_[0]->{options}{ $_[1] } }
sub command_path { [ @{ $_[0]->{path} } ] }
sub focused { $_[0]->{focused} }
sub custom_id { $_[0]->{raw}{data}{custom_id} }
sub values { $_[0]->{raw}{data}{values} // [] }

sub field {
    my ( $self, $custom_id ) = @_;
    croak 'Field ID must be a non-empty string'
        unless defined($custom_id) && !ref($custom_id) && length($custom_id);
    return undef unless $self->{type} == 5;

    # Labels use a single child; older Action Rows contain an array of children.
    for my $container ( @{ $self->{raw}{data}{components} // [] } ) {
        next unless ref($container) eq 'HASH';
        my @children;
        if ( ( $container->{type} // 0 ) == 18 ) {
            @children = ( $container->{component} );
        }
        elsif ( ( $container->{type} // 0 ) == 1 && ref( $container->{components} ) eq 'ARRAY' ) {
            @children = @{ $container->{components} };
        }
        for my $input (@children) {
            next unless ref($input) eq 'HASH' && ( $input->{type} // 0 ) == 4;
            return $input->{value} if ( $input->{custom_id} // '' ) eq $custom_id;
        }
    }
    return undef;
}

sub guild_id { $_[0]->{raw}{guild_id} }

sub channel_id {
    my ($self) = @_;
    return $self->{raw}{channel_id} // ( ref( $self->{raw}{channel} ) eq 'HASH' ? $self->{raw}{channel}{id} : undef );
}

sub user {
    my ($self) = @_;
    return $self->{raw}{user} // ( ref( $self->{raw}{member} ) eq 'HASH' ? $self->{raw}{member}{user} : undef );
}
sub member { $_[0]->{raw}{member} }

sub resolved {
    my ( $self, $kind, $id ) = @_;

    # Support the full resolved payload, one resource collection, or one resource ID.
    my $resolved = $self->{raw}{data}{resolved} // {};
    return $resolved unless $kind;
    return $resolved->{$kind} unless defined $id;
    return ref( $resolved->{$kind} ) eq 'HASH' ? $resolved->{$kind}{$id} : undef;
}

sub _parse_options {
    my ( $self, $options, $depth ) = @_;

    # Bound each level and reject duplicate names before flattening selected values.
    croak 'Invalid interaction options' unless ref($options) eq 'ARRAY' && @$options <= 25 && $depth <= 2;
    my %names;
    for my $option (@$options) {
        croak 'Invalid interaction option'
            unless ref($option) eq 'HASH'
            && defined( $option->{name} )
            && !ref( $option->{name} )
            && length( $option->{name} )
            && defined( $option->{type} )
            && !ref( $option->{type} )
            && $option->{type} =~ /\A(?:[1-9]|10|11)\z/;
        croak 'Invalid interaction option' if $names{ $option->{name} };
        $names{ $option->{name} } = 1;

        # Nested selectors form the command path; leaf options hold values and focus state.
        if ( $option->{type} == 1 || $option->{type} == 2 ) {
            croak 'Invalid nested interaction option' if exists $option->{value};
            push @{ $self->{path} }, $option->{name};
            $self->_parse_options( $option->{options} // [], $depth + 1 );
            next;
        }

        # Leaf values are flattened for handlers; only one may drive autocomplete.
        croak 'Invalid interaction option value'
            if exists( $option->{options} )
            || !exists( $option->{value} )
            || ( ref( $option->{value} ) && !JSON::PP::is_bool( $option->{value} ) );
        $self->{options}{ $option->{name} } = $option->{value};
        if ( $option->{focused} ) {
            croak 'Multiple focused interaction options' if $self->{focused};
            $self->{focused} = {%$option};
        }
    }
}

sub _failed {
    my ( $self, $message, $category, %fields ) = @_;
    my $future = $self->{loop}->new_future;
    my $error = Discord::Client::Error->new( message => $message, category => $category, %fields );
    return $future->fail( $message, $category, $error );
}

sub _expire_initial {
    my ($self) = @_;
    return if $self->{acknowledgement}->is_ready;

    # Mark expiry before notifying observers so no callback can start another response.
    $self->{state} = 'expired';
    my $failed = $self->_failed( 'Interaction initial response deadline exceeded', 'deadline' );
    $self->{acknowledgement}->fail( $failed->failure );
    if ( my $initial = $self->{initial_operation} ) {
        $initial->fail( $failed->failure ) unless $initial->is_ready;
    }

    # Cancel outstanding delivery after publishing the deadline failure.
    if ( my $source = delete $self->{initial_source} ) {
        $source->cancel unless $source->is_ready;
    }
}

sub _message {
    my ( $self, $message, %options ) = @_;

    # Copy caller data before adding SDK-controlled visibility flags.
    croak 'Message must be a string or hash reference'
        unless defined($message)
        && ( !ref($message) || ref($message) eq 'HASH' );
    my $data = ref($message) ? {%$message} : { content => "$message" };
    if ( $options{ephemeral} ) {
        croak 'Invalid message flags'
            if defined( $data->{flags} )
            && ( ref( $data->{flags} ) || $data->{flags} !~ /\A\d+\z/ );
        $data->{flags} = ( $data->{flags} // 0 ) | 64;
    }
    return $data;
}

sub reply {
    my ( $self, $message, %options ) = @_;
    return $self->_failed( 'Autocomplete interactions require choices', 'state' ) if $self->{type} == 4;
    my $data = eval { $self->_message( $message, %options ) };
    return $self->_failed( 'Invalid interaction message', 'request' ) if $@;

    # Complete a confirmed deferral by editing its original message exactly once.
    if ( $self->{state} eq 'deferred' || $self->{state} eq 'deferred_update' ) {
        return $self->_failed( 'Deferred response visibility is already fixed', 'request' )
            if exists $options{ephemeral};
        $self->{state} = 'completing';
        my $future = $self->_webhook( 'PATCH', '/messages/@original', json => $data );
        $future->on_ready( sub { $self->{state} = $future->is_done ? 'replied' : 'failed' } );
        return $future;
    }
    return $self->_initial( 4, $data, 'replied' );
}

sub defer {
    my ( $self, %options ) = @_;
    return $self->_failed( 'Autocomplete cannot be deferred', 'state' ) if $self->{type} == 4;

    # Message updates and new deferred replies have different visibility rules.
    if ( $options{update} ) {
        return $self->_failed( 'Update deferral requires a message component', 'state' ) unless $self->_can_update;
        return $self->_failed( 'Update deferral cannot set ephemeral visibility', 'request' ) if $options{ephemeral};
        return $self->_initial( 6, undef, 'deferred_update' );
    }
    return $self->_initial( 5, $options{ephemeral} ? { flags => 64 } : undef, 'deferred' );
}

sub _can_update { $_[0]->{type} == 3 || ( $_[0]->{type} == 5 && ref( $_[0]->{raw}{message} ) eq 'HASH' ) }

sub update {
    my ( $self, $message ) = @_;
    return $self->_failed( 'Update requires a message component', 'state' ) unless $self->_can_update;
    my $data = eval { $self->_message($message) };
    return $self->_failed( 'Invalid interaction message', 'request' ) if $@;
    return $self->_initial( 7, $data, 'replied' );
}

sub autocomplete {
    my ( $self, $choices ) = @_;
    return $self->_failed( 'Choices require an autocomplete interaction', 'state' ) unless $self->{type} == 4;
    return $self->_failed( 'Invalid autocomplete choices', 'request' )
        unless ref($choices) eq 'ARRAY' && @$choices <= 25;

    # Validate each suggestion against the focused option and normalize JSON value types.
    my @wire;
    for my $choice (@$choices) {
        return $self->_failed( 'Invalid autocomplete choice', 'request' )
            unless ref($choice) eq 'HASH'
            && defined( $choice->{name} )
            && !ref( $choice->{name} )
            && length( $choice->{name} ) >= 1
            && length( $choice->{name} ) <= 100
            && defined( $choice->{value} )
            && !ref( $choice->{value} );
        my $type = $self->{focused}{type};
        if ( $type == 3 ) {
            return $self->_failed( 'Invalid autocomplete choice value', 'request' )
                if length( $choice->{value} ) > 100;
        }
        else {
            return $self->_failed( 'Invalid autocomplete choice value', 'request' )
                if !looks_like_number( $choice->{value} )
                || abs( $choice->{value} ) > 9007199254740992
                || ( $type == 4
                    && ( $choice->{value} != int( $choice->{value} ) || abs( $choice->{value} ) >= 9007199254740992 ) );
        }
        push @wire, { %$choice, value => $type == 3 ? "$choice->{value}" : 0 + $choice->{value} };
    }
    return $self->_initial( 8, { choices => \@wire }, 'replied' );
}

sub modal {
    my ( $self, $data ) = @_;

    # A modal opens only from a command or message component, never a modal submission.
    return $self->_failed( 'Modal response is invalid for this interaction', 'state' )
        unless $self->{type} == 2 || $self->{type} == 3;
    return $self->_failed( 'Invalid modal response', 'request' )
        unless ref($data) eq 'HASH'
        && defined( $data->{custom_id} )
        && !ref( $data->{custom_id} )
        && length( $data->{custom_id} ) <= 100
        && length( $data->{custom_id} ) > 0
        && defined( $data->{title} )
        && !ref( $data->{title} )
        && length( $data->{title} ) > 0
        && length( $data->{title} ) <= 45
        && ref( $data->{components} ) eq 'ARRAY';
    return $self->_initial( 9, $data, 'replied' );
}

sub _initial {
    my ( $self, $type, $data, $next_state ) = @_;

    # Reject closed, expired or already-answered contexts before attempting delivery.
    return $self->_failed( 'Interaction is closed', 'shutdown' ) if $self->{closed};
    return $self->_failed( 'Interaction initial response deadline exceeded', 'deadline' )
        if $self->{clock}->() >= $self->{deadline} || $self->{state} eq 'expired';
    return $self->_failed( 'Interaction already has an initial response', 'state' ) unless $self->{state} eq 'new';

    # Validate serialization before consuming the one initial-response opportunity.
    my $payload = { type => $type };
    $payload->{data} = $data if defined $data;
    return $self->_failed( 'Interaction response is not JSON encodable', 'request' )
        unless eval {
            JSON::PP->new->encode($payload);
            1;
        };

    # Reserve the response before invoking either REST or an inline HTTP sender.
    $self->{state} = 'responding';
    my $source = eval { $self->_send_initial_response($payload) };
    my $future = $self->_observe($source);
    $self->{initial_operation} = $future;
    $self->{initial_source} = $source if blessed($source) && $source->isa('Future');
    $future->on_ready( sub { $self->_complete_initial_response( $future, $next_state ) } );
    return $future;
}

sub _send_initial_response {
    my ( $self, $payload ) = @_;

    # HTTP delivery can answer inline; Gateway delivery uses the unauthenticated callback endpoint.
    return $self->{initial_sender}->($payload) if $self->{initial_sender};
    my $path = '/interactions/' . $self->{id} . '/' . uri_escape_utf8( $self->{token} ) . '/callback';
    return $self->_rest->request( 'POST', $path, auth => 0, json => $payload );
}

sub _complete_initial_response {
    my ( $self, $future, $next_state ) = @_;
    return if $self->{state} eq 'expired' || $self->{closed};

    # Release delivery state and deadline before notifying acknowledgement observers.
    delete @{$self}{qw(initial_operation initial_source)};
    if ( my $timer = delete $self->{initial_timer} ) {
        $timer->cancel unless $timer->is_ready;
    }

    # Only confirmed delivery enables webhook operations; failure remains non-retryable.
    if ( $future->is_done ) {
        $self->{state} = $next_state;
        $self->{acknowledgement}->done unless $self->{acknowledgement}->is_ready;
        return;
    }

    # Cancellation cannot distinguish a rejected response from one already delivered.
    $self->{state} = 'failed';
    my $failure = $future;
    unless ( $future->is_failed ) {
        $failure = $self->_failed( 'Interaction response cancelled; delivery is uncertain', 'cancelled' );
    }
    $self->{acknowledgement}->fail( $failure->failure ) unless $self->{acknowledgement}->is_ready;
}

sub _rest {
    my ($self) = @_;

    # Standalone contexts lazily create token-only REST and own its cleanup.
    unless ( $self->{rest} ) {
        $self->{rest} = Discord::Client::REST->new( auth => 0, loop => $self->{loop} );
        $self->{own_rest} = 1;
    }
    return $self->{rest};
}

sub _observe {
    my ( $self, $source ) = @_;
    return $self->_failed( 'Interaction transport failed', 'transport' )
        unless blessed($source) && $source->isa('Future');

    # Track operations so context shutdown can cancel both the observer and transport.
    my $future = $self->{loop}->new_future;
    my $key = refaddr($future);
    $self->{operations}{$key} = $future;
    $future->on_cancel( sub { $source->cancel unless $source->is_ready } );

    # Detach completed work before forwarding its outcome to application callbacks.
    $source->on_ready(
        sub {
            delete $self->{operations}{$key};
            return if $future->is_ready;
            if ( $source->is_done ) {
                $future->done( $source->result );
                return;
            }
            if ( $source->is_cancelled ) {
                $future->cancel;
                return;
            }

            # Preserve useful error codes while excluding raw transport details and tokens.
            my ( undef, $category, $error ) = $source->failure;
            my %fields;
            if ( blessed($error) && $error->isa('Discord::Client::Error') ) {
                %fields = ( status => $error->status, discord_code => $error->discord_code );
                $self->{invalidated} = 1
                    if ( $error->status // 0 ) == 401
                    || ( $error->discord_code // 0 ) == 10015
                    || ( $error->discord_code // 0 ) == 10062;
            }
            my $failed = $self->_failed( 'Interaction request failed', $category // 'transport', %fields );
            $future->fail( $failed->failure );
        }
    );
    return $future;
}

sub _webhook {
    my ( $self, $method, $suffix, %args ) = @_;

    # Webhook operations require a confirmed acknowledgement and a still-valid token.
    return $self->_failed( 'Interaction is closed', 'shutdown' ) if $self->{closed};
    return $self->_failed( 'Interaction token expired or invalidated', 'expired' )
        if $self->{invalidated} || $self->{clock}->() >= $self->{expires_at};
    return $self->_failed( 'Interaction requires a confirmed initial response', 'state' )
        unless $self->{acknowledgement}->is_done;

    # Escape the token as one path segment and never attach Bot authorization.
    my $source = eval {
        $self->_rest->request(
            $method, '/webhooks/'
                . $self->{application_id}
                . '/'
                . uri_escape_utf8( $self->{token} )
                . $suffix,
            auth => 0,
            %args
        );
    };
    return $self->_observe($source);
}

sub edit_original {
    my ( $self, $message ) = @_;
    my $data = eval { $self->_message($message) };
    return $self->_failed( 'Invalid interaction message', 'request' ) if $@;
    return $self->_webhook( 'PATCH', '/messages/@original', json => $data );
}
sub get_original { $_[0]->_webhook( 'GET', '/messages/@original' ) }
sub delete_original { $_[0]->_webhook( 'DELETE', '/messages/@original' ) }

sub followup {
    my ( $self, $message, %options ) = @_;
    my $data = eval { $self->_message( $message, %options ) };
    return $self->_failed( 'Invalid interaction message', 'request' ) if $@;
    return $self->_webhook( 'POST', '', json => $data, query => { wait => 'true' } );
}

sub edit_followup {
    my ( $self, $id, $message ) = @_;
    return $self->_failed( 'Invalid followup message ID', 'request' ) unless _id($id);
    my $data = eval { $self->_message($message) };
    return $self->_failed( 'Invalid interaction message', 'request' ) if $@;
    return $self->_webhook( 'PATCH', '/messages/' . $id, json => $data );
}

sub delete_followup {
    my ( $self, $id ) = @_;
    return $self->_failed( 'Invalid followup message ID', 'request' ) unless _id($id);
    return $self->_webhook( 'DELETE', '/messages/' . $id );
}

sub close {
    my ($self) = @_;

    # Stop the deadline and prevent future operations before cancelling current work.
    return $self->{loop}->new_future->done if $self->{closed};
    $self->{closed} = 1;
    if ( my $timer = delete $self->{initial_timer} ) {
        $timer->cancel unless $timer->is_ready;
    }
    if ( !$self->{acknowledgement}->is_ready ) {
        $self->{acknowledgement}->fail( $self->_failed( 'Interaction is closed', 'shutdown' )->failure );
    }

    # Use a snapshot because cancellation callbacks mutate the operation registry.
    my @operations = CORE::values %{ $self->{operations} };
    $_->cancel for grep { !$_->is_ready } @operations;
    $self->{operations} = {};
    return $self->{own_rest} ? $self->{rest}->close : $self->{loop}->new_future->done;
}

sub DESTROY {
    my ($self) = @_;

    # Release lazily owned resources even when the caller simply drops the context.
    $self->{initial_timer}->cancel if $self->{initial_timer} && !$self->{initial_timer}->is_ready;
    $self->{rest}->close if $self->{own_rest};
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Interaction - Interaction responses and payload access

=head1 SYNOPSIS

    # Acknowledge before slow work and return the entire operation.
    return $interaction->defer(ephemeral => 1)->then(sub {
        return $bot->loop->delay_future(after => 1);
    })->then(sub {
        return $interaction->reply('Your report is ready.');
    });

=head1 DESCRIPTION

Command, component, autocomplete and modal handlers receive an Interaction.
Reply L<within three seconds|https://docs.discord.com/developers/interactions/receiving-and-responding>
or defer before starting slow work. Return the handler's Future.
The SDK does not acknowledge handlers automatically.
Use Futures or optional Future::AsyncAwait; blocking C<sleep> or C<get> stops
the shared loop.

Only one initial response is allowed. Failed or cancelled initial operations
are not replayed because delivery may be uncertain. The three-second deadline
includes event queue and REST waiting time. Expiry fails with C<deadline> and
cancels I/O. Edits and followups require confirmed acknowledgement and expire
fifteen minutes after receipt.

Operations use the interaction token without Bot authorization. Token rejection
invalidates the context. Failures include a sanitized L<Discord::Client::Error>
with separate HTTP status and Discord code. The client reports handler failures
through its error callback; standalone dispatch uses L<Discord::Client::Interactions>.

=head1 RESPONSE METHODS

All response methods return Futures. Message arguments accept text or Discord
JSON hashrefs, including embeds, components and C<allowed_mentions>.
C<ephemeral =E<gt> 1> makes a reply private.

=head2 reply

C<reply(text_or_hash, ephemeral =E<gt> 1)> sends an initial reply.
After a successful defer, it edits the original response. Visibility chosen
by defer cannot be changed by the completing reply.

=head2 defer

C<defer(ephemeral =E<gt> 1)> acknowledges before slow work.
C<defer(update =E<gt> 1)> defers an update to a component's message.

=head2 update

C<update(text_or_hash)> updates the message for a component interaction.
Update and deferred-update responses also support message-associated modal
submissions.

=head2 autocomplete

C<autocomplete(choices_array)> answers autocomplete. Choices contain C<name>
and C<value>. Normal message replies cannot answer autocomplete.

=head2 modal

C<modal(modal_hash)> opens a modal from a command or component.
Use L<Discord::Client::UI/modal> or a native Discord payload.

=head2 get_original

Fetches the original response; the Future yields its message hashref.

=head2 edit_original

C<edit_original(text_or_hash)> edits the original response; the Future yields
its message hashref.

=head2 delete_original

Deletes the original response; the Future resolves to undef.

=head2 followup

C<followup(text_or_hash, ephemeral =E<gt> 1)> sends another message; the Future
yields its message hashref.

=head2 edit_followup

C<edit_followup(message_id, text_or_hash)> edits a followup; the Future yields
its message hashref.

=head2 delete_followup

C<delete_followup(message_id)> deletes a followup; the Future resolves to undef.

=head1 CONTEXT METHODS

Accessors are synchronous. IDs remain strings.

=head2 new

C<new(payload =E<gt> $payload, loop =E<gt> $loop, rest =E<gt> $rest)> wraps an
incoming interaction. Dispatchers normally construct this for handlers.
C<payload> is required. C<loop> and C<rest> are optional; a loop is created
when absent and token-only REST is created when first needed.
Invalid payloads throw. Construction starts the initial acknowledgement timer.
C<received_at> supplies receipt time in monotonic seconds. Tests can inject
C<clock> and C<delay>.

C<initial_sender> can supply an inline HTTP response callback. It receives
the response hashref and returns a Future confirming acceptance; later webhook
operations still use REST.

=head2 id

Returns the interaction ID.

=head2 application_id

Returns the application ID.

=head2 type

Returns the numeric interaction type.

=head2 raw

Returns the incoming payload hashref. It contains the interaction token;
do not log it.

=head2 option

C<option(name)> returns a command argument or undef when absent.

=head2 options

Returns a hashref of command arguments.

=head2 command_path

Returns an arrayref of selected group/subcommand names, excluding the root command.

=head2 focused

Returns the focused autocomplete option hashref or undef.

=head2 resolved

C<resolved(kind, id)> returns a resolved resource. Omit C<id> for the resource
map of that kind; omit both arguments for the full map.

=head2 user

Returns the caller's user hashref, including from guild member data.

=head2 member

Returns the guild member hashref or undef.

=head2 guild_id

Returns the guild ID or undef.

=head2 channel_id

Returns the channel ID or undef.

=head2 custom_id

Returns a component's custom ID or undef.

=head2 values

Returns the select values arrayref, or an empty arrayref when absent.

=head2 field

C<field(custom_id)> reads a submitted modal Text Input. Empty input returns
C<''>; a missing field or non-modal interaction returns undef. It reads Label
and Action Row children. Other fields remain available through C<raw>.
Invalid field IDs throw.

=head2 state

Returns the response state string.

=head2 responded

Returns true when the initial response has been reserved, including while
sending or after failure. It does not confirm successful acknowledgement.

=head2 acknowledgement

Returns the Future for the initial response, tracked separately from the
handler's work.

=head2 close

Cancels operations and acknowledgement timers. Returns a Future for cleanup
of owned resources; an injected REST client remains caller-owned.

=head1 LICENSE

Apache License 2.0.

=cut
