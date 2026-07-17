use v5.26;
use warnings;
use Feature::Compat::Class;
use experimental qw/ signatures /;

package MIDI::RtMidi::FFI::Device::Out;
class MIDI::RtMidi::FFI::Device::Out :isa( MIDI::RtMidi::FFI::AbstractDevice );

our $VERSION = '0.12';

# ABSTRACT: OO interface for MIDI::RtMidi::FFI output deviced

use MIDI::Stream::Encoder;
use MIDI::Stream::Tables qw/ split_bytes /;
use MIDI::RtMidi::FFI ':all';
use Carp qw/ croak carp /;

field $enable_14bit_cc :param = 0;
field $enable_running_status :param = 0;
field $encoder = MIDI::Stream::Encoder->new(
    enable_14bit_cc => $enable_14bit_cc,
    enable_running_status => $enable_running_status,
);

method build_device( $api, $name ) {
    my $device = rtmidi_out_create( $api, $name );
    croak "Error creating device" if !$device || !$device->ok;
    $device;
}


method send_message( @msg ) {
    rtmidi_out_send_message( $self->device, $_ ) for @msg;
}


my $_munge_midi_event_name = method( $event ) {
    $event->[0] = $self->name_from_midi_event( $event->[0] );
    $event;
};

method encode_message( @event ) {
    if ( ref $event[0] eq 'ARRAY' ) {
        return map { $self->encode_message( $_->@* ) } @event;
    }
    $encoder->encode( $self->$_munge_midi_event_name( \@event ) );
}


method encode( @event ) { $self->encode_message( @event ) }


method send_message_encoded( @event ) {
    $self->send_message( $self->encode_message( @event ) );
}


*send_event = \&send_message_encoded;


method rpn( $channel, $rpn, $value, $cc = [ 101, 100 ] ) {
    my ( $rpn_msb, $rpn_lsb ) = ref $rpn eq 'ARRAY'
        ? map { $_ // 0 } $rpn->@[0, 1]
        : split_bytes( $rpn );

    my ( $msb, $lsb ) = ref $value eq 'ARRAY'
        ? $value->@*
        : split_bytes( $value );

    my @msg = ( $cc->[0], $rpn_msb, $cc->[1], $rpn_lsb, 6, $msb );
    push @msg, ( 38, $lsb ) if defined $lsb;
    push @msg, ( 101, 127, 100, 127 );
    $self->cc( $channel, @msg );
}


method nrpn( $channel, $nrpn, $value ) {
    $self->rpn( $channel, $nrpn, $value, [ 99, 98 ] );
}


sub panic {
    my ( $self, $channel ) = @_;
    my @channels = defined $channel
        ? ( $channel )
        : ( 0..15 );
    $self->cc( 123, $_, 0 ) for @channels;
}


sub PANIC {
    my ( $self, $channel ) = @_;
    my @channels = defined $channel
        ? ( $channel )
        : ( 0..15 );
    for my $ch ( @channels ) {
        $self->note_off( $ch, $_ ) for 0..127;
    }
}

method get_current_api {
    rtmidi_out_get_current_api( $self->device );
}


method note_off { $self->send_event( note_off => @_ ) };
method note_on { $self->send_event( note_on => @_ ) };
method control_change { $self->send_event( control_change => @_ ) };
method patch_change { $self->send_event( patch_change => @_ ) };
method key_after_touch { $self->send_event( key_after_touch => @_ ) };
method channel_after_touch { $self->send_event( channel_after_touch => @_ ) };
method pitch_wheel_change { $self->send_event( pitch_wheel_change => @_ ) };
method sysex { $self->send_event( sysex => @_ ) };
method clock { $self->send_event( clock => @_ ) };
method start { $self->send_event( start => @_ ) };
method stop { $self->send_event( stop => @_ ) };
method continue { $self->send_event( continue => @_ ) };


*cc = \&control_change;
*program_change = \&patch_change;
*aftertouch = \&channel_after_touch;
*polytouch = \&key_after_touch;
*pitch_bend = \&pitch_wheel_change;

method DESTROY {
    $self->close_port;
    #rtmidi_out_free( $self->device );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI::Device::Out - OO interface for MIDI::RtMidi::FFI output deviced

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

=head3 enable_14bit_cc

Enable encoding of 14-bit values to MSB/LSB pairs for lower 32 CCs. Default:
false

=head3 enable_running_status

Enable running-status in encoded messages - status is not retransmitted for
consecutive messages with the same status, after the first message in the set.

=head2 send_message

    $device->send_message( $msg );
    $device->send_message( $msg, $other_msg );

Sends a message - MIDI bytes - on the device's open port.

=head2 encode_message

    my $msg = $device->encode_message( note_on => 0x00, 0x40, 0x5a )
    $device->encode_message( @event );

Attempts to encode the passed message with L<MIDI::Stream::Encoder>.

=head2 encode

Alias for L</encode_message>.

=head2 send_message_encoded

    $device->send_message_encoded( @event );
    # Event, channel, note, velocity
    $device->send_message_encoded( note_on => 0x00, 0x40, 0x5A );
    $device->send_message_encoded( control_change => 0x01, 0x1F, 0x3F7F );
    $device->send_message_encoded( sysex => "Hello, computer?" );

Sends an event to the open port. Event names may be
L<MIDI::Event names|MIDI::Event/EVENTS> or
L<MIDI::Stream event names|MIDI::Stream/Events and Parameters>.

=head2 send_event

Alias for L</send_message_encoded>.

=head2 rpn

    $device->rpn( $channel, $rpn, $value );
    $device->rpn( $channel, [ $rpn_msb, $rpn_lsb ], [ $value_msb, $value_lsb ] );
    $device->rpn( $channel, [ $rpn_msb, $rpn_lsb ], [ $value_msb ] );
    $device->rpn( 0xf, 0x0000, 0x1fff );

Send a single Registered Paramater Number (RPN) value.

This expects the parameter number and its value as 14-bit values,
or you can pass an arrayref for either to speficy MSB and LSB
separately.

If your parameter expects only a MSB value (CC6 only), you may specify just
the MSB in an arrayref, or shift the MSB by 7 bits. That is:

    $device->rpn( $channel, $rpn, $value_msb << 7 );
    $device->rpn( $channel, $rpn, [ $value_msb ] );

...not:

    $device->rpn( $channel, $rpn, $value_msb ); # wrong!

=head2 nrpn

    $device->nrpn( $channel, $nrpn, $value );
    $device->nrpn( $channel, [ $nrpn_msb, $nrpn_lsb ], [ $value_msb, $value_lsb ] );
    $device->nrpn( 0xf, 0x0000, 0x1fff );

Send a single Non-Registered Paramater Number (NRPN) value.
See L</rpn> for additional detail on parameters.

=head2 panic

    $device->panic( $channel );
    $device->panic( 0x00 );

Send an "All MIDI notes off" (CC 123) message to the specified channel.
If no channel is specified, the message is sent to all channels.

=head2 PANIC

    $device->PANIC( $channel );
    $device->PANIC( 0x00 );

Send 'note_off' to all 128 notes on the specified channel.
If no channel is specified, the message is sent to all channels.

B<Warning:> This method has the potential to flood buffers!
It should be a recourse of last resort - consider L</panic>,
it'll probably work.

=head2 note_off, note_on, control_change, patch_change, key_after_touch, channel_after_touch, pitch_wheel_change, sysex, clock, start, stop, continue

Wrapper methods for L</send_message_encoded>, e.g.

    $device->note_on( 0x00, 0x40, 0x5a );

is equivalent to:

    $device->send_message_encoded( note_on => 0x00, 0x40, 0x5a );

=head2 cc

An alias for control_change.

=head2 program_change

An alias for patch_change.

=head2 aftertouch

An alias for channel_after_touch.

=head2 polytouch

An alias for key_after_touch.

=head2 pitch_bend

An alias for pitch_wheel_change.

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
