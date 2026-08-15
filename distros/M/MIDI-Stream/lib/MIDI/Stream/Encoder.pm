use v5.26;
use warnings;
use Feature::Compat::Class;

# ABSTRACT: MIDI event to bytestream encoder

package MIDI::Stream::Encoder;
class MIDI::Stream::Encoder :isa( MIDI::Stream );


our $VERSION = '0.006';

use Time::HiRes qw/ gettimeofday tv_interval /;
use Carp qw/ carp croak /;
use MIDI::Stream::Tables qw/
    has_channel keys_for is_single_byte
    status_byte split_bytes is_realtime
    message_length
/;


field $enable_14bit_cc :param = 0;
field $enable_running_status :param = 0;
field $running_status_retransmit :param = 10;
field $concat :param = 0;

field @msb;
field $running_status = 0;
field $running_status_count = 0;

my $_flatten = method( $event ) {
    my @keys = ( 'name', keys_for( $event->{ name } )->@* );
    my @e = $event->@{ @keys };
    [ $event->@{ @keys } ];
};

my $_running_status = method( $status ) {
    return $status unless $enable_running_status;
    # MIDI 1.0 Detailed Specification v4.2.1 p. 5
    # Data Types > Status Bytes > Running Status:
    #
    # "For Voice and Mode messages only ...
    # Running Status will be stopped when any other Status byte
    # intervenes. Real-Time messages should not affect Running Status."
    #
    # I interpret this as:
    # - Running status is only for channel messages
    # - System messages reset status, but do not set it
    # - ...apart form realtime status which does not reset or set
    return $status if is_realtime( $status );
    if ( ! has_channel( $status ) ) {
        $self->clear_running_status;
        return $status;
    }

    # Running status found, and haven't reached retransmit threshold
    return 0 if
        $status == $running_status &&
        $running_status_count++ < $running_status_retransmit;

    # Set and return status
    $running_status_count = 0;
    $running_status = $status;
};


my $encode_one = method( $event ) {
    my @event = $event->@*;

    my $event_name = shift @event;
    my $status = status_byte( $event_name );
    if ( ! $status ) {
        carp "Ignoring unknown status : $event_name";
        return;
    }

    if ( $event_name eq 'pitch_bend' ) {
        splice @event, 1, 1, split_bytes( $event[1] + 8192 );
    }

    if ( $event_name eq 'song_position' ) {
        splice @event, 0, 1, split_bytes( $event[0] );
    }

    # 'Note off' events with velocity should retain their status,
    # and set running-status accordingly.
    # 'Note on' with velocity 0 is treated as 'Note off'.
    # Strings of 'Note on' events can take better advantage of
    # running-status.
    $status |= 0x10 if
         $enable_running_status &&
         $status == 0x80 &&
         !$event[ 2 ] &&
         $status != ( $running_status & 0xf0 );

    $status |= shift @event & 0xf if has_channel( $status );

    $status = $self->$_running_status( $status );
    join '', map { chr } $status
        ? ( $status, @event )
        : @event
};

method encode( $event ) {
    $event = $self->$_flatten( $event )
        if ref $event eq 'HASH';
    $event = $event->as_arrayref
        if eval{ $event->isa('MIDI::Stream::Event') };
    my @event = $event->@*;
    my @events;

    if ( $event[0] eq 'sysex' ) {
        if ( ref $event[1] eq 'ARRAY' ) {
            @event = ( $event[0], $event[1]->@* );
            push @event, 0xf7 unless $event[-1] == 0xf7;
        }
        else {
            my $msg = chr( 0xf0 ) . $event[1];
            $msg .= substr( $event[1], -1 ) ne chr( 0xf7 )
                ? chr( 0xf7 )
                : '';
            return $msg;
        }
    }

    if ( $enable_14bit_cc && $event[0] eq 'control_change' && $event[2] < 0x20 ) {
        my ( $lsb, $msb ) = split_bytes( $event [3] );
        # Comparing new MSB against last-sent MSB for this CC
        if ( ( $msb[ $event[2] ] // -1 ) == $msb ) {
            # MSB already sent, just send LSB on CC + 32
            $event[2] |= 0x20;
            $event[3] = $lsb;
        }
        else {
            # Re-send MSB, concatenate LSB running status
            $msb[ $event[2] ] = $msb;
            $event[3] = $msb;
            if ( $concat ) {
                push @event, $event[2] | 0x20, $lsb;
            }
            else {
                push @events, ( [ @event ], [ @event[ 0, 1 ], $event[2] | 0x20, $lsb ] );
            }
        }
    }
    elsif ( ! $concat && has_channel( $event[0] ) ) {
        my $length = message_length( $event[0] );

        if ( @event > $length + 1 ) {
            my @status = @event[ 0, 1 ];
            my $i = 2;
            my $l = $length - 1;
            while ( $event[ $i ] ) {
                push @events, [ @status, @event[ $i, $i + $l - 1 ] ];
                $i += $l;
            }
        }
    }

    @events
        ? map { $self->$encode_one( $_ ) } @events
        : $self->$encode_one( \@event );

}


method encode_events( @events ) {
    $concat
        ? join '', map { $self->encode( $_ ) } @events
        : map { $self->encode( $_ ) } @events;
}


method clear_running_status {
    $running_status_count = 0;
    $running_status = 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Stream::Encoder - MIDI event to bytestream encoder

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use MIDI::Stream::Encoder;

    my $encoder = MIDI::Stream::Encoder->new(
        enable_14bit_cc => true,
        enable_running_status => false
    );

    # Middle C to channel 9, max velocity
    my $midi_bytes = $encoder->encode( [ note_on => 0x9, 0x3c, 0x7f ] );

    # 14-bit value 6704 for CCs 19 and 51 on channel 15
    $midi_bytes .= $encoder->encode( [ control_change => 0xf, 0x12, 0x1a30 ] );

    # Encode MIDI::Stream::Event back to bytes
    $midi_bytes .= $encoder->encode( $midi_stream_event );

    # Your favourite output MIDI library goes here ...
    $some_midi_device->send( $midi_bytes );

=head1 DESCRIPTION

MIDI::Stream::Encoder provides realtime MIDI stream encoding facilities.  It
supports running-status, 14-bit CC, and all basic channel, system common, and
realtime messages.

MIDI::Stream::Encoder is a stateful class. A new instance should
be created for each target MIDI port, device or stream.

There is no explicit support for many extended sequences. This includes, but is
not limited to, MPE, (N)RPN, Bank/Program Select, Channel Modes, Song Position,
Advanced SysEx operations, or TimeCode/Quarter frame messages.

The arrayref form of encode(), by design, allows for additional bytes to be
appended to the message. For example, a complete bank select may be constructed
as follows:

    $encoder->encode( [ control_change => 0, 0, $msb, 32, $lsb );

You might also use this to encode multiple note messages for block chords:

    # C-Major
    $encoder->encode( [ note_on => 0x2, 0x3c, 0x60,
                                        0x40, 0x46,
                                        0x43, 0x3f ] );

Depending on whether the L</concat> option is set, this will return a single
byte string, or a list of discrete strings each representing one note on event.

=head1 METHODS

=head2 new

    my $encoder = MIDI::Stream::Encoder->new( %options );

Returns a new encoder instance. Options:

=head3 enable_running_status

Enables running-status. Running status skips retransmitting status (e.g. "note
on" for channel 7) if it has not changed between messages. This is recommended
when communicating with external MIDI hardware, especially if over DIN or TRS.

This is disabled by default.

=head3 running_status_retransmit

In case a receiver misses a status, it is recommended status is retransmitted
every so often. This value controls how often this occurs. If the count of a
run of same-status messages exceeds the configured threshold, the status is
sent again, and the count is reset.

This has no effect if enable_running_status is false. The default value is 10.

=head3 enable_14bit_cc

Enables encoding of 14bit CC values for the lower 32 CCs. Ordinarily this would
require separate messages be constructed for the CC's MSB and its corresponding
LSB.

For example, with enable_14bit_cc = true:

    $encoder->encode( [ control_change => 7, 2, 8190 ] );

...will encode a control change for Channel 7, CC 2 = 63 (the MSB), and a control
change for Channel 7, CC 34 = 126 (the LSB).

This is disabled by default.

=head3 concat

Enables concatenation of multiple events passed to L</encode> and
L</encode_events> to a single byte string. Some subsystems' MIDI send
routines, e.g.
L<WinMM midiOutShortMsg|https://learn.microsoft.com/en-us/windows/win32/api/mmeapi/nf-mmeapi-midioutshortmsg>
cannot accept MIDI strings which are too long to be packed into a 32-bit word,
so a list of smaller strings will be returned from encode functions.

This is disabled by default.

=head2 encode

    my $midi_bytes = $encoder->encode( $arrayref );
    my $midi_bytes = $encoder->encode( $hashref );
    my $midi_bytes = $encoder->encode( $midi_stream_event );

Encodes the provided event to MIDI bytes. This event may be an arrayref with
named event plus its parameters, a hashref with all event parameters named
(See L</Events and Parameters>), or an instance of L<MIDI::Stream::Event>.

The arrayref parameter allows for additional bytes to be appended to the event
(just bytes, not additional named events - see L<encode_events> for a way to
encode multiple different events in a single call). For example, to encode a
block chord:

    # C-Minor
    my @msgs = $encoder->encode( [ note_on => 0x2, 0x3c, 0x60,
                                                   0x3f, 0x46,
                                                   0x43, 0x3f ] );

This is only supported for channel messages. See L</concat> for options on how
these events will be encoded.

=head2 encode_events

    my $message = $encoder->encode_events( $arrayref, $hashref, $midi_stream_event );

Encode multiple events. Returns a single MIDI byte string if L</concat> is
enabled, or a list of strings, one per-event, otherwise.

=head2 clear_running_status

Explicitly clear the current running status and retransmit counter.

=head1 Events and Parameters

=over

=item note_off - channel, note, velocity

=item note_on - channel, note, velocity

=item polytouch - channel, note, pressure

=item control_change - channel, control, value

=item program_change - channel, program

=item aftertouch - channel, pressure

=item pitch_bend - channel, value

=item song_position - position

=item song_select - song

=item timecode - byte

=item sysex - msg

=item tune_request

=item eox

=item clock

=item start

=item continue

=item stop

=item active_sensing

=item system_reset

=back

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
