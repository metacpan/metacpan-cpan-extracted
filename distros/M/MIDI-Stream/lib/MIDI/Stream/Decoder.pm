use v5.26;
use warnings;
use Feature::Compat::Class;
use experimental qw/ signatures /;

# ABSTRACT: MIDI bytestream decoder

package MIDI::Stream::Decoder;
class MIDI::Stream::Decoder :isa( MIDI::Stream );


our $VERSION = '0.006';

use Time::HiRes qw/ gettimeofday tv_interval /;
use Carp qw/ carp croak /;
use MIDI::Stream::Tables qw/ is_cc is_realtime message_length combine_bytes event_desc /;
use MIDI::Stream::FIFO;
use MIDI::Stream::EventFactory;

my $event_desc = event_desc();
my @event_keys = keys $event_desc->%*;


field $retain_events :param = 1;

field $enable_14bit_cc :param = 0;
field @cc;

field $callback :param = sub { @_ };
field $filter_cb = {};

field $clock_ppqn :param = 24;
field $clock_samples :param = 24;
field $clock_fifo = MIDI::Stream::FIFO->new( length => $clock_samples );
field $round_tempo :param = 0;

field @events;
field @pending_event;
field $message_length;

my $_expand_cc = method( $event ) {
    return $event unless is_cc( $event->[ 0 ] );
    return $event unless $enable_14bit_cc;
    return $event if $event->[ 1 ] > 0x3f;
    return $event if $event->[ 2 ] > 0x7f;

    if ( $event->[ 1 ] & 0x20 ) {
        my $msb = $cc[ $event->[ 1 ] & ~0x20 ];
        return unless defined $msb;
        $event->[ 2 ] = combine_bytes( $event->[ 2 ], $msb );
        $event->[ 1 ] &= ~0x20;
        return $event;
    }

     $cc[ $event->[ 1 ] ] = $event->[ 2 ];
     return;
};

my $_sample_clock = method() {
    state $t = [ gettimeofday ];
    $clock_fifo->add( tv_interval( $t ) );
    $t = [ gettimeofday ];
};

my $_push_event = method( $event = undef ) {
    state $t = [ gettimeofday ];
    # Do not use a reference to @pending_event!
    # Contents will have changed by the time you get round to using it.
    $event //= [ @pending_event ];
    $event = $self->$_expand_cc( $event );
    return unless $event;
    my $dt = tv_interval( $t );
    $t = [ gettimeofday ];

    my $stream_event = MIDI::Stream::EventFactory->event( $dt, $event );

    if ( !$stream_event ) {
        carp( "Ignoring unknown status $event->[0]" );
        return;
    }

    push @events, $stream_event if $retain_events;

    my @callbacks = ( $filter_cb->{ all } // [] )->@*;
    push @callbacks, ( $filter_cb->{ $stream_event->name } // [] )->@*;

    for my $cb ( @callbacks ) {
        no warnings 'uninitialized';
        last if $cb->( $stream_event ) eq $self->stop;
    }

    $callback->( $stream_event );
};

my $_reset_pending_event = method( $status = undef ) {
    @pending_event = ();
    push @pending_event, $status if defined $status;
    $message_length = message_length( $status );
};


method decode( @bytestrings ) {
    my $bytestring = join '', @bytestrings;
    my @bytes = unpack 'C*', $bytestring;
    my $status;

    BYTE:
    while ( @bytes ) {

        # Status byte - start/end of message
        if ( $bytes[0] & 0x80 ) {
            my $status = shift @bytes;

            # Sample the clock to determine tempo ASAP
            $status == 0xf8 && $self->$_sample_clock();

            # End-of-Xclusive
            if ( $status == 0xf7 ) {
                carp( "EOX received for non-SysEx message - ignoring!") && next BYTE
                    unless $pending_event[0] == 0xf0;
                $self->$_push_event();
                $self->$_reset_pending_event();
                next BYTE;
            }

            # Real-Time messages can appear within other messages.
            if ( is_realtime( $status ) ) {
                # Push unless we have an undefined realtime status
                $self->$_push_event( [ $status ] ) unless $status == 0xf9 || $status == 0xfd;
                next BYTE;
            }

            # Any non-Real-Time status byte ends a SysEx
            # Push the pending sysex and proceed ...
            if ( @pending_event && $pending_event[0] == 0xf0 ) {
                $self->$_push_event();
            }

            # Undefined system statuses which should reset running status -
            # a full message needs to be received after this
            if ( $status == 0xf4 || $status == 0xf5 ) {
                @pending_event = ();
                next BYTE;
            }

            # Should now be able to push any single-byte statuses,
            # e.g. Tune request
            if ( message_length( $status ) == 1 ) {
                @pending_event = ();
                $self->$_push_event( [ $status ] );
                next BYTE;
            }

            $self->$_reset_pending_event( $status );
            next BYTE;
        } # end if status byte

        my $byte = shift @bytes;
        next BYTE unless @pending_event;

        push @pending_event, $byte;
        my $remaining = $message_length - @pending_event;

        # A complete message denoted by length, not upcoming status bytes
        if ( $message_length && $remaining <= 0 ) {
            $self->$_push_event();
            $self->$_reset_pending_event( $pending_event[0] );
        }
    } # end while

    scalar @events;
}


my $matching_events = sub( $event ) {
    [ grep { $_ =~ $event } @event_keys ]
};

method attach_callback( $event, $callback ) {
    if ( ref $event eq 'ARRAY' ) {
        $self->attach_callback( $_, $callback ) for $event->@*;
        return;
    }
    if ( ref $event eq 'Regexp' ) {
        $self->attach_callback( $matching_events->( $event ), $callback );
    }
    push $filter_cb->{ $event }->@*, $callback;
}


*attach_event_callback = \&attach_callback;


method cancel_event_callback( $event ) {
    if ( ref $event eq 'ARRAY' ) {
        $self->cancel_event_callback( $_ ) for $event->@*;
        return;
    }
    if ( ref $event eq 'Regexp' ) {
        $self->cancel_event_callback( $matching_events->( $event ) );
    }
    delete $filter_cb->{ $event };
}


method cancel_callback {
    undef $callback;
}


method events {
    splice @events;
}


method fetch_one_event {
    shift @events;
}


method tempo {
    my $tempo = 60 / ( $clock_fifo->average * $clock_ppqn );
    $round_tempo ? sprintf( '%.0f', $tempo ) : $tempo;
}

method continue { MIDI::Stream::Tables::continue() }
method stop { MIDI::Stream::Tables::stop() }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Decoder - MIDI bytestream decoder

=head1 VERSION

version 0.006

=head1 SYNOPSIS

Using a callback for event-driven operation:

    use MIDI::Stream::Decoder;

    my $decoder = MIDI::Stream::Decoder->new(
        retain_events => false,
        callback => sub( $event ) {
            # Handle MIDI::Stream::Event $event
        }
    );

    # Callbacks can respond to individual event types
    $decoder->attach_callback(
        [ qw/ note_off note_on / ] => sub( $event ) {
            # Handle MIDI::Stream::Event::Note $event
        }
    );

    # Your favourite MIDI input library goes here ...
    while ( my $msg = await $some_midi_device->receive ) {
        $decoder->decode( $msg );
    }

Procedural approach:

    use MIDI::Stream::Decoder;

    my $decoder = MIDI::Stream::Decoder->new(
        retain_events => true,
    );

    while ( my $msg = $some_midi_device->receive ) {
        if ( $decoder->decode( $msg ) ) {
            my @events = $decoder->events;
            # Handle MIDI::Stream::Event @events
        }
    }

=head1 DESCRIPTION

MIDI::Stream::Decoder provides realtime MIDI stream decoding facilities. It
supports running-status, 14-bit CC, and all basic channel, system common, and
realtime messages.

MIDI::Stream::Decoder is a stateful class. A new instance should be created
for each target MIDI port, device or stream.

Two main modes of operation are provided, a procedural mode where events are
retrieved by-hand, and an event-driven mode where events are passed to
callbacks as they arrive. Callbacks receive a L<MIDI::Stream::Event>
instance.

=head1 METHODS

=head2 new

    my $decoder = MIDI::Stream::Decoder->new( %options );

Returns a new decoder instance. Options:

=head3 retain_events

Store decoded events for later retrieval. This should be set to true if using
the procedural interface, or wish to hold events in memory for any other
purpose. Retaining events is not required for the callback interface.

The default value is true.

=head3 enable_14bit_cc

Enable decoding of 14-bit CC values for the lower 32 CCs. This option will
combine CC MSB/LSB values to a single 14-bit value, assigned to the lower (MSB)
CC.

The default value is false.

=head3 round_tempo

This module will use the timing of incoming clock events to derive a tempo, or BPM. This option will force tempo to be rounded to the nearest whole number.

The default value is false.

=head3 clock_samples

The number of clock events to sample when deriving tempo.

The default value is 24.

=head3 clock_ppqn

The PPQN value of the incoming clock. This is probably 24.

The default value is 24.

=head2 decode

    my $pending_count = $decoder->decode( $midi_bytes );
    $decoder->decode( $midi_bytes, $more_midi_bytes );

Decodes any MIDI messages in the passed string. Returns the number of
pending events if retain_events is enabled. Any callbacks associated with
the decoded events will be invoked.

=head2 attach_callback

    $decoder->attach_callback( $event, $callback );

    $decoder->attach_callback(
        control_change => sub( $event ) {
            ...
            $decoder->stop;
        }
    );

    $decoder->attach_callback(
        [ qr/^note/, 'control_change' ] => sub( $event ) {
            ...
            $decoder->continue;
        }
    );

Attaches the given callback to the specified event type. Multiple event types
may be bound by setting $event to be an arrayref of event types. Regular
expressions matching event names may also be passed.

Any number of callbacks may be attached to an event. They will be executed in
the order they were attached. Should you wish to stop processing further
callbacks for the given event, your callback should return $decoder->stop.

A special event 'all' will respond to all event types. These callbacks will
be called before the global callback, if one was passed to the constructor.
If set, the global callback will always be called no matter the return value
of attached event callbacks.

=head2 attach_event_callback

Alias for L</attach_callback>

=head2 cancel_event_callback

    $decoder->cancel_event_callback( $event );

    $decoder->cancel_event_callback( [ qr/^note/, 'control_change' ] );

Cancels the callbacks associated with the given event name.
As with attach_callback, $event may be an arrayref or regular expression
matching event names.

=head2 cancel_callback

Cancels the global callback, the one passed in the constructor parameter
'callback'.

B<NB> This operation cannot be undone!

=head2 events

Return all pending events. This clears the event queue.

=head2 fetch_one_event

Returns the next pending event from the event queue.

=head2 tempo

Return the current tempo/BPM, based on incoming clock events.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
