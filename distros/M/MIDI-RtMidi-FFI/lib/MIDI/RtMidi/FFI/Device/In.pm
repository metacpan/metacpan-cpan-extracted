use v5.26;
use warnings;
use Feature::Compat::Class;
use experimental qw/ signatures /;

package MIDI::RtMidi::FFI::Device::In;
class MIDI::RtMidi::FFI::Device::In :isa( MIDI::RtMidi::FFI::AbstractDevice );

our $VERSION = '0.12';

# ABSTRACT: OO interface for MIDI::RtMidi::FFI input devices

use MIDI::Stream::Decoder;
use MIDI::RtMidi::FFI ':all';
use Carp qw/ croak carp /;

field $ignore_sysex   :param = 1;
field $ignore_timing  :param = 1;
field $ignore_sensing :param = 1;

field $enable_14bit_cc :param = 0;
field $retain_events :param = 1;
field $decoder :param :reader = MIDI::Stream::Decoder->new(
    enable_14bit_cc => $enable_14bit_cc,
    retain_events => $retain_events,
);

field $queue_size_limit :param = MIDI::RtMidi::FFI::BUFFER_SIZE;
field $bufsize :param :reader = $queue_size_limit;

field $remap_event_names :param = 1;

field $callback;

method build_device( $api, $name ) {
    my $device = rtmidi_in_create( $api, $name, $bufsize );
    croak "Error creating device" if !$device || !$device->ok;
    $device;
}

ADJUST {
    $self->ignore_types( $ignore_sysex, $ignore_timing, $ignore_sensing );
}



method set_callback( $cb ) {
    $self->cancel_callback;
    $callback = rtmidi_in_set_callback( $self->device, $cb );
}


my $_munge_midi_event_name = method( $event ) {
    return $event unless $remap_event_names;
    $event->[0] = $self->name_to_midi_event( $event->[0] );
    $event;
};

method set_callback_decoded( $cb ) {
    $decoder->cancel_event_callback( 'all' );
    $decoder->attach_callback(
        all => sub( $event ) {
            $cb->(
                $event->dt,
                $event->bytes,
                $self->$_munge_midi_event_name( $event->as_arrayref )
            );
            $decoder->continue;
        }
    );
    $self->set_callback( sub( $dt, $msg ) { $self->decode_message( $msg ) } );
}


method cancel_callback {
    return unless $callback;
    undef $callback;
    rtmidi_in_cancel_callback( $self->device );
}


method get_fh {
    $self->cancel_callback;
    $callback = callback_fh( $self->device );
}


method ignore_types( $sysex, $timing, $sensing ) {
    ( $ignore_sysex, $ignore_timing, $ignore_sensing ) = ( $sysex, $timing, $sensing );
    rtmidi_in_ignore_types( $self->device, $sysex, $timing, $sensing );
}


method ignore_sysex( $new_ignore_sysex ) {
    $self->ignore_types( $new_ignore_sysex, $ignore_timing, $ignore_sensing );
}


method ignore_timing( $new_ignore_timing ) {
    $self->ignore_types( $ignore_sysex, $new_ignore_timing, $ignore_sensing );
}


method ignore_sensing( $new_ignore_sensing ) {
    $self->ignore_types( $ignore_sysex, $ignore_timing, $new_ignore_sensing );
}


method get_message {
    rtmidi_in_get_message( $self->device );
}


method get_message_decoded {
    $self->decode_message( $self->get_message );
}


*get_event = \&get_message_decoded;


method decode_message( $msg ) {
    return unless $decoder->decode( $msg );
    $self->$_munge_midi_event_name( $decoder->fetch_one_event->as_arrayref );
}


method decode( $msg ) { $self->decode_message( $msg ) }

method get_current_api {
    rtmidi_in_get_current_api( $self->device );
}

method DESTROY {
    $self->close_port;
    $self->cancel_callback;
    MIDI::RtMidi::FFI::_cleanup( $self->device );
    # rtmidi_in_free( $self->device );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI::Device::In - OO interface for MIDI::RtMidi::FFI input devices

=head1 VERSION

version 0.12

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

See L<MIDI::RtMidi::FFI::Device> for documentation methods common to all
device types.

=head2 new

Construct new instance.

    my $midiin = MIDI::RtMidi::FFI::Device::In->new( %options );

See global device options in L<MIDI::RtMidi::FFI::Device/new>.

=head3 ignore_sysex

Ignore incoming SysEx messages. Default: true

=head3 ignore_timing

Ignore incoming timing messages. Default: true

=head3 ignore_sensing

Ignore incoming active sensing messages. Default: true

=head3 enable_14bit_cc

Enable decoding of MSB/LSB pairs for lower 32 CCs to 14-bit values. Default:
false

=head3 retain_events

Retain decoded events. Calling L</decode> or L</get_message_decoded> will
clear events from the queue as they are retrieved.

If you intend to use callbacks to retrieve MIDI events or data, consider
disabling this option to save memory. All pending events may be retrieved
with:

    my @events = $midiin->decoder->events();

Default: true.

=head3 queue_size_limit

Buffer size for incoming messages. Default: 4096 bytes

=head3 bufsize

An alias for queue_size_limit.

=head3 remap_event_names

If true, decoded incoming events will use
L<MIDI::Event namesMIDI::Event/EVENTS>
for backwards compatibility. If false,
L<MIDI::Stream event names|MIDI::Stream/Events> will be used.

Default: true.

=head2 bufsize

Read-only accessor for bufsize/queue_size_limit parameter.

=head2 set_callback

    $device->set_callback( sub( $dt, $msg ) {
        # handle $msg here
    } );

Sets a callback to be executed when an incoming MIDI message is
received. Your callback receives the time which has elapsed since the previous
event in seconds, alongside the MIDI message.

B<NB> As a callback may occur at any point in your program's flow, the program
should probably not be doing much when it occurs. That is, programs handling
RtMidi callbacks should be asleep the callback is triggered. See L</get_fh>
for an approach to integrating rtmidi into event loops.

See the examples included with this dist for some ideas on how to incorporate
callbacks into your program.

=head2 set_callback_decoded

    $device->set_callback_decoded( sub( $dt, $msg, $event ) {
        # handle $msg / $event here
    } );

Same as L</set_callback>, though also attempts to decode the message, and pass
that to the callback as an array ref. The original message is also sent in
case this fails.

See L</remap_event_names> - a constructor option which sets event names for
incoming events.

=head2 cancel_callback

    $device->cancel_callback();

Removes the callback from your device.

=head2 get_fh

    # Future::AsyncAwait style ...
    my $fh = $midi_in->get_fh;
    my $size = $midi_in->bufsize;
    my $decoder = MIDI::Stream::Decoder->new(
        callback => sub( $event ) { # Handle $event here }
    );
    while ( my $bytes = await Future::IO->read( $fh, $size ) ) {
        $decoder->decode( $bytes );
    }

This uses the rtmidi callback mechanism to write MIDI bytes to a pipe as the
arrive. This method returns the other end of the pipe as a nonblocking
L<IO::Handle> instance, which can be handed to the event loop of your choice.

B<NB> This receives raw MIDI bytes, not decoded events with timestamps.
This cannot be used in conjunction with L</set_callback> or 
L</set_callback_decoded>.

=head2 ignore_types

    $device->ignore_types( $ignore_sysex, $ignore_timing, $ignore_sensing );
    $device->ignore_types( (1)x3 );

Type 'in' only. Set message types to ignore.

=head2 ignore_sysex

    $device->ignore_sysex( 1 );
    $device->ignore_sysex( 0 );

Type 'in' only. Set whether or not to ignore sysex messages.

=head2 ignore_timing

    $device->ignore_timing( 1 );
    $device->ignore_timing( 0 );

Type 'in' only. Set whether or not to ignore clock/timing messages.

=head2 ignore_sensing

    $device->ignore_sensing( 1 );
    $device->ignore_sensing( 0 );

Type 'in' only. Set whether or not to ignore active sensing messages.

=head2 get_message

    $device->get_message();

Type 'in' only. Gets the next message from the queue, if available.

=head2 get_message_decoded

    $device->get_message_decoded();

Type 'in' only. Gets the next message from the queue, if available, decoded
as an event. See L</decode_message> for what to expect from incoming events.

=head2 get_event

Alias for L</get_message_decoded>.

=head2 decode_message

    my $event = $device->decode_message( $msg );

Decodes the passed MIDI byte string with L<MIDI::Stream::Decoder>.

=head2 decode

Alias for L</decode_message>

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
