package Discord::Client::HTTPInteractions;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use IO::Async::Loop;
use IO::Handle;
use JSON::PP ();
use Scalar::Util qw(weaken);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use Discord::Client::Interaction::Verifier;
use Discord::Client::Commands;
use Discord::Client::Interactions;
use Discord::Client::REST;

our $VERSION = '0.001';

sub new {
    my ( $class, %args ) = @_;

    # Allocate independent limits for active handlers, cached replies and retained IDs.
    my $loop = $args{loop} // IO::Async::Loop->new;
    my $self = bless {
        loop => $loop,
        clock => $args{clock} // sub { clock_gettime(CLOCK_MONOTONIC) },
        max_body => $args{max_body} // 1024 * 1024,
        max_replay => $args{max_replay} // 1024,
        max_seen => $args{max_seen} // 10000,
        replay_ttl => $args{replay_ttl} // 900,
        pending => {},
        replies => {},
        seen => {},
        counters => {},
        on_error => $args{on_error}
    }, $class;

    # Validate capacity and hooks before creating verification or transport resources.
    for my $key (qw(max_body max_replay max_seen replay_ttl)) {
        croak "$key must be a positive integer" unless !ref( $self->{$key} ) && $self->{$key} =~ /\A[1-9]\d*\z/;
    }
    for my $key (qw(clock delay on_error)) {
        croak "$key must be a code reference" if exists( $args{$key} ) && ref( $args{$key} ) ne 'CODE';
    }

    # Verify signatures independently of command dispatch and token-only followup delivery.
    $self->{verifier} = Discord::Client::Interaction::Verifier->new(
        public_key => $args{public_key},
        ( exists( $args{wall_clock} ) ? ( wall_clock => $args{wall_clock} ) : () ),
        ( exists( $args{max_age} ) ? ( max_age => $args{max_age} ) : () ),
    );
    $self->{rest} = $args{rest} // Discord::Client::REST->new( auth => 0, loop => $loop );
    $self->{own_rest} = !$args{rest};
    $self->{commands} = $args{commands} // Discord::Client::Commands->new(
        rest => $self->{rest},
        loop => $loop,
        application_id => $args{application_id}
    );
    $self->{own_commands} = !$args{commands};

    # Dispatcher error callbacks must not keep the HTTP service alive.
    my $weak = $self;
    weaken($weak);
    $self->{dispatcher} = Discord::Client::Interactions->new(
        loop => $loop,
        commands => $self->{commands},
        rest => $self->{rest},
        clock => $self->{clock},
        ( exists( $args{delay} ) ? ( delay => $args{delay} ) : () ),
        max_seen => $self->{max_seen},
        seen_ttl => $self->{replay_ttl},
        max_pending => $args{max_pending} // 512,
        on_error => sub {
            return unless $weak;
            ++$weak->{counters}{handler_errors};
            if ( $weak->{on_error} ) {
                my $ok = eval {
                    $weak->{on_error}->(@_);
                    1;
                };
                warn "HTTP interaction error handler failed\n" unless $ok;
            }
            else {
                warn $_[0]->message . "\n";
            }
        }
    );
    return $self;
}

sub loop { $_[0]->{loop} }
sub commands { $_[0]->{commands} }
sub rest { $_[0]->{rest} }
sub dispatcher { $_[0]->{dispatcher} }

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

sub _response {
    my ( $self, $status, $data ) = @_;

    # Return PSGI bytes and a byte count, not a character count.
    my $body = JSON::PP->new->utf8->encode($data);
    return [ $status, [ 'Content-Type' => 'application/json', 'Content-Length' => length($body) ], [$body] ];
}

sub _done {
    my ( $self, $status, $data ) = @_;
    return $self->{loop}->new_future->done( $self->_response( $status, $data ) );
}

sub _copy_response {
    my ($response) = @_;
    my ( $status, $headers, $body ) = @$response;
    return [ $status, [@$headers], [@$body] ];
}

sub _waiter {
    my ( $self, $source ) = @_;

    # Each HTTP caller gets its own response copy and cannot cancel shared handler work.
    my $future = $self->{loop}->new_future;
    $source->on_ready(
        sub {
            return if $future->is_ready;
            if ( $source->is_done ) {
                my ($response) = $source->result;
                $future->done( _copy_response($response) );
            }
            else {
                $future->done( $self->_response( 503, { error => 'Interaction request cancelled' } ) );
            }
        }
    );
    return $future;
}

sub handle {
    my ( $self, $headers, $body, %args ) = @_;

    # Record arrival before verification so all admission time counts toward the deadline.
    my $received_at = $args{received_at} // $self->{clock}->();
    ++$self->{counters}{requests};
    return $self->_done( 503, { error => 'Interaction service closed' } ) if $self->{closed};
    return $self->_done( 400, { error => 'Invalid request body' } ) unless defined($body) && !ref($body);
    return $self->_done( 413, { error => 'Request body too large' } ) if length($body) > $self->{max_body};
    return $self->_done( 401, { error => 'Invalid request signature' } ) unless ref($headers) eq 'HASH';
    my %normalized_headers = map { lc($_) => $headers->{$_} } keys %$headers;
    my $signature = $normalized_headers{'x-signature-ed25519'};
    my $timestamp = $normalized_headers{'x-signature-timestamp'};

    # Verify the exact signed octets before trusting or parsing JSON fields.
    unless ( $self->{verifier}->verify( $signature, $timestamp, $body ) ) {
        ++$self->{counters}{rejected_signatures};
        return $self->_done( 401, { error => 'Invalid request signature' } );
    }

    # PING is a signature check and needs neither a command context nor replay storage.
    my $payload = eval { JSON::PP->new->utf8->decode($body) };
    return $self->_done( 400, { error => 'Invalid interaction JSON' } )
        if $@
        || ref($payload) ne 'HASH'
        || !defined( $payload->{type} )
        || ref( $payload->{type} );
    return $self->_done( 200, { type => 1 } ) if $payload->{type} eq '1';

    my $now = $self->{clock}->();
    $self->_expire_replay_records($now);

    # Coalesce running duplicates and replay completed responses without rerunning handlers.
    my $id = $payload->{id};
    return $self->_done( 400, { error => 'Invalid interaction ID' } )
        unless defined($id) && !ref($id) && $id =~ /\A\d+\z/;
    my $replayed_response = $self->_replay_response($id);
    return $replayed_response if $replayed_response;

    return $self->_done( 503, { error => 'Interaction capacity exceeded' } )
        if keys( %{ $self->{seen} } ) >= $self->{max_seen};
    return $self->_dispatch_payload( $payload, $received_at, $now );
}

sub _expire_replay_records {
    my ( $self, $now ) = @_;

    # Expire completed IDs only; running work must remain protected from replay.
    for my $id ( keys %{ $self->{seen} } ) {
        next if $self->{pending}{$id} || $self->{seen}{$id} > $now;
        delete $self->{seen}{$id};
        delete $self->{replies}{$id};
    }
}

sub _replay_response {
    my ( $self, $id ) = @_;

    # Pending work, cached bytes and retained IDs have different replay outcomes.
    if ( my $record = $self->{pending}{$id} ) {
        ++$self->{counters}{duplicates};
        return $self->_waiter( $record->{response} );
    }
    if ( my $record = $self->{replies}{$id} ) {
        ++$self->{counters}{duplicates};
        return $self->{loop}->new_future->done( _copy_response( $record->{response} ) );
    }

    # Evicted response bytes do not permit the same side effects to run again.
    if ( exists $self->{seen}{$id} ) {
        ++$self->{counters}{duplicates};
        return $self->_done( 409, { error => 'Interaction response no longer cached' } );
    }
    return undef;
}

sub _dispatch_payload {
    my ( $self, $payload, $received_at, $now ) = @_;
    my $id = $payload->{id};
    my $response_future = $self->{loop}->new_future;
    my $record = { response => $response_future };

    # Reserve the ID before invoking application code, including reentrant calls.
    $self->{pending}{$id} = $record;
    $self->{seen}{$id} = $now + $self->{replay_ttl};
    my $work = $self->{dispatcher}->handle(
        $payload,
        received_at => $received_at,
        initial_sender => sub { $self->_complete_inline_reply( $response_future, $_[0] ) },
    );
    $record->{work} = $work unless $work->is_ready;

    # Release active ownership after both acknowledgement and application work settle.
    $work->on_ready(
        sub {
            delete $record->{work};
            if ( $work->is_failed && ( $work->failure )[1] eq 'queue_full' ) {

                # Admission failed before any handler ran; retries may try again.
                delete $self->{seen}{$id};
                delete $self->{pending}{$id};
                $self->_finish_unanswered_response( $response_future, $work );
                return;
            }
            $self->_finish_unanswered_response( $response_future, $work );
            $self->_cache_response( $id, $response_future ) unless $self->{closed};
            delete $self->{pending}{$id};
        }
    );
    return $self->_waiter($response_future);
}

sub _cache_response {
    my ( $self, $id, $response_future ) = @_;
    $self->{replies}{$id} = { response => ( $response_future->result )[0], order => ++$self->{reply_order} };
    return if keys( %{ $self->{replies} } ) <= $self->{max_replay};

    # Evict response bytes, retaining the ID so side effects cannot run twice.
    my ($oldest) = sort { $self->{replies}{$a}{order} <=> $self->{replies}{$b}{order} }
        keys %{ $self->{replies} };
    delete $self->{replies}{$oldest};
}

sub _complete_inline_reply {
    my ( $self, $response_future, $reply ) = @_;

    # Accept at most one serializable inline response for the request.
    return $self->{loop}->new_future->fail( 'HTTP response is already complete', 'state' )
        if $response_future->is_ready;
    my $wire = eval { $self->_response( 200, $reply ) };
    return $self->{loop}->new_future->fail( 'Invalid HTTP interaction response', 'request' ) unless $wire;
    $response_future->done($wire);
    return $self->{loop}->new_future->done;
}

sub _finish_unanswered_response {
    my ( $self, $response_future, $work ) = @_;
    return if $response_future->is_ready;

    # Map public failure categories to HTTP status without exposing private error details.
    my $status = 500;
    if ( $work->is_failed ) {
        my ( undef, $category ) = $work->failure;
        my %status_for = ( deadline => 504, protocol => 400, queue_full => 503 );
        $status = $status_for{$category} // 500;
    }
    $response_future->done( $self->_response( $status, { error => 'Interaction could not be answered' } ) );
}

sub psgi_app {
    my ($self) = @_;
    return sub { $self->_handle_psgi_request( $_[0] ) };
}

sub _handle_psgi_request {
    my ( $self, $env ) = @_;

    # Bound the POST body before reading from the host-provided input stream.
    my $received_at = $self->{clock}->();
    return $self->_response( 405, { error => 'POST required' } ) unless ( $env->{REQUEST_METHOD} // '' ) eq 'POST';
    my $length = $env->{CONTENT_LENGTH};
    return $self->_response( 400, { error => 'Content-Length required' } )
        unless defined($length) && $length =~ /\A\d+\z/;
    return $self->_response( 413, { error => 'Request body too large' } ) if $length > $self->{max_body};

    # Preserve request bytes for signature validation; reject incomplete host input.
    my $body = eval { _read_psgi_body( $env->{'psgi.input'}, $length ) };
    return $self->_response( 400, { error => 'Incomplete request body' } ) if $@;
    my $future = $self->handle(
        {
            'X-Signature-Ed25519' => $env->{HTTP_X_SIGNATURE_ED25519},
            'X-Signature-Timestamp' => $env->{HTTP_X_SIGNATURE_TIMESTAMP},
        },
        $body,
        received_at => $received_at
    );
    return $future->get if $future->is_ready;

    # Only streaming hosts can wait asynchronously for an unanswered interaction.
    unless ( $env->{'psgi.streaming'} ) {
        return $self->_reject_pending_psgi_response($body);
    }
    return sub {
        my ($responder) = @_;
        $future->on_ready( sub { $responder->( $future->get ) } );
    };
}

sub _read_psgi_body {
    my ( $input, $length ) = @_;
    my $body = '';

    # PSGI input may return short chunks; zero bytes before Content-Length is a failure.
    while ( length($body) < $length ) {
        my $read = $input->read( my $chunk, $length - length($body) );
        die 'Short request body' unless defined($read) && $read > 0;
        $body .= $chunk;
    }
    return $body;
}

sub _reject_pending_psgi_response {
    my ( $self, $body ) = @_;

    # A synchronous host cannot keep an unanswered handler running after returning 503.
    my $payload = eval { JSON::PP->new->utf8->decode($body) };
    my $record = ref($payload) eq 'HASH' ? $self->{pending}{ $payload->{id} // '' } : undef;
    if ($record) {
        $record->{response}->done( $self->_response( 503, { error => 'Asynchronous PSGI support required' } ) )
            unless $record->{response}->is_ready;
        $record->{work}->cancel if $record->{work} && !$record->{work}->is_ready;
    }
    return $self->_response( 503, { error => 'Asynchronous PSGI support required' } );
}

sub stats {
    my ($self) = @_;
    return {
        %{ $self->{counters} },
        replay_entries => scalar( keys %{ $self->{replies} } ),
        pending_requests => scalar( keys %{ $self->{pending} } ),
        seen_entries => scalar( keys %{ $self->{seen} } )
    };
}

sub close {
    my ($self) = @_;

    # Answer outstanding HTTP callers before cancelling dispatcher work and owned resources.
    $self->{closed} = 1;
    for my $record ( values %{ $self->{pending} } ) {
        $record->{response}->done( $self->_response( 503, { error => 'Interaction service closed' } ) )
            unless $record->{response}->is_ready;
    }
    $self->{dispatcher}->close;
    $self->{pending} = {};
    $self->{replies} = {};
    $self->{seen} = {};
    $self->{commands}->close if $self->{own_commands};
    return $self->{own_rest} ? $self->{rest}->close : $self->{loop}->new_future->done;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::HTTPInteractions - Signed HTTP Interactions and PSGI delivery

=head1 SYNOPSIS

    use Discord::Client::HTTPInteractions;

    # Configure signature verification and command dispatch.
    my $service = Discord::Client::HTTPInteractions->new(
        public_key => $public_key, loop => $loop,
    );
    $service->command(
        ping => (
            description => 'Replies with Pong',
            handler => sub {
                my ($interaction) = @_;
                return $interaction->reply('Pong!');
            },
        ),
    );

    # Let the host await this Future on the supplied loop.
    my $response = $service->handle(\%headers, $raw_body);

=head1 DESCRIPTION

Receives commands and components over HTTPS without a Gateway connection.
Handlers use L<Discord::Client::Interaction>; initial replies are returned
inline. Inline replies need no bot token; followups use the interaction token
through REST. Command deployment needs a separate Bot-authorized client;
see L<Discord::Client::Commands/sync>.

=head1 METHODS

=head2 new

C<new(public_key =E<gt> $key, loop =E<gt> $loop)> returns a receiver.
C<public_key> is the required 64-character hexadecimal application public key.
C<loop> is optional; otherwise one is created.
C<rest> and C<commands> can inject caller-owned components.
C<application_id> sets the registry's application ID.

C<max_body> defaults to 1048576 bytes, C<max_pending> to 512 active handlers,
and C<max_replay> to 1024 completed response entries. C<max_seen> defaults to
10,000 deduplication IDs, independent of response storage. C<replay_ttl> defaults
to 900 seconds and must be a positive integer. Running handlers remain protected
until they finish, even beyond this period.
C<max_age> defaults to 300 seconds of timestamp difference; zero disables this
SDK freshness policy. Keep the host clock synchronized.
Tests can inject C<wall_clock>, C<clock> and C<delay>.
C<on_error> receives C<($error, $interaction)> synchronously.

=head2 command

C<command(name, declaration_pairs)> registers a command and returns the service.
Arguments follow L<Discord::Client::Commands/define>; it does not deploy.

=head2 component

C<component(custom_id =E<gt> CODE)> registers a handler and returns the service.

=head2 handle

C<handle> returns a Future yielding C<[status, [headers], [body_bytes]]>.
Pass exact raw body octets before decoding or parsing. Header names are
case-insensitive. Verification covers the timestamp followed by those octets.

=over 4

=item Missing or invalid signature

HTTP 401.

=item Body over C<max_body>

HTTP 413.

=item Invalid body or JSON

HTTP 400.

=item Duplicate whose response was evicted

HTTP 409, without repeating the handler.

=item Unavailable service or capacity

HTTP 503.

=back

Commands do not run for rejected requests. Diagnostics omit request bodies and
signatures. Handlers use the same L<Interaction API|Discord::Client::Interaction> as
Gateway delivery; initial acknowledgements are returned inline.

=head2 psgi_app

Returns a PSGI application coderef. Host requirements are described under
L</PSGI AND ASYNCHRONOUS HANDLERS>.

=head2 loop

Returns the supplied or created IO::Async::Loop.

=head2 rest

Returns the REST client used for followups.

=head2 commands

Returns the Commands registry.

=head2 dispatcher

Returns the Interactions dispatcher.

=head2 stats

Returns request, signature, duplicate and error counters as a hashref, plus
C<pending_requests>, C<replay_entries> and C<seen_entries>.

=head2 close

Returns a Future for cleanup. Pending HTTP responses complete with 503;
handlers and timers are cancelled, and owned resources are closed.
Injected REST and Commands objects remain caller-owned. Call it when the host
stops.

=head1 PSGI AND ASYNCHRONOUS HANDLERS

C<psgi_app> returns a coderef accepting POST requests. It reads C<psgi.input>
using Content-Length and returns an immediate response or delayed responder.
The initial response deadline is three seconds, including body reading and
verification.

Immediate handlers work on an ordinary PSGI host. Asynchronous handlers and
work after defer need a host that advertises C<psgi.streaming> and drives the
supplied C<IO::Async::Loop>. Streaming alone does not run pending Futures.
The adapter does not run another loop. Without delayed-response support,
a pending initial response is cancelled and returns 503.

=head1 DUPLICATES

Signed duplicates of running handlers share the initial response. Completed
responses are copied for replay until C<replay_ttl> expires or C<max_replay>
requires eviction of the oldest completed response. Evicted responses return
409 for duplicate IDs; their handlers do not run again while the IDs are retained.

C<max_seen> bounds the retained IDs; reaching it rejects new requests with 503.
Entries expire on subsequent requests, after their handlers finish. A dispatcher
capacity rejection before a handler starts is not retained, so a retry can run
when capacity returns. Failures after dispatch remain protected because the
handler may have performed side effects. This is process-local.
Use shared deduplication across workers if your side effects require it.

=head1 SERVE THE EXAMPLE

Set C<DISCORD_PUBLIC_KEY> to the application's 64-character hexadecimal public
key from the Developer Portal. Install Plack and a PSGI server, then run:

    PERL5LIB=lib plackup examples/http-interactions.psgi

Expose the service over public HTTPS and set its L<Interactions Endpoint URL|https://docs.discord.com/developers/interactions/overview#configuring-an-interactions-endpoint-url> in
the Developer Portal. C<plackup> alone serves local HTTP. The SDK verifies
signatures and answers signed PING requests. HTTP and Gateway are alternative
interaction delivery methods for the application.

=head1 LICENSE

Apache License 2.0.

=cut
