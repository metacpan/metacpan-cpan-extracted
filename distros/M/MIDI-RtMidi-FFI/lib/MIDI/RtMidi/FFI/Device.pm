use strict;
use warnings;
package MIDI::RtMidi::FFI::Device;

# ABSTRACT: OO interface for MIDI::RtMidi::FFI

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI::Device - OO interface for L<MIDI::RtMidi::FFI>

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use MIDI::RtMidi::FFI::Device;
    
    my $device = MIDI::RtMidi::FFI::Device->new;
    $device->open_virtual_port( 'perl-rtmidi' );
    $device->send_event( note_on => 0, 0, 0x40, 0x5a );
    sleep 1;
    $device->send_event( note_off => 0, 0, 0x40, 0x5a );

=head1 DESCRIPTION

MIDI::RtMidi::FFI::Device is an OO interface for L<MIDI::RtMidi::FFI> to help
you manage devices, ports and MIDI events.

=cut

use MIDI::RtMidi::FFI ':all';
use MIDI::Event;
use Carp;

our $VERSION = $MIDI::RtMidi::FFI::VERSION;

=head1 METHODS

=head2 new

    my $device = MIDI::RtMidi::FFI::Device->new( %attributes );

Returns a new MIDI::RtMidi::FFI::Device object. Valid attributes:

=over 4

=item *

B<type> -
Device type : 'in' or 'out' (defaults to 'out')

=item *

B<name> -
Device name

=item *

B<queue_size_limit> -
(Type 'in' only) The buffer size to allocate for queueing incoming messages
(defaults to 1024)

=item *

B<bufsize> -
(Type 'in' only) An alias for B<queue_size_limit>.

=item *

B<ignore_sysex> -
(Type 'in' only) Ignore incoming SYSEX messages (defaults to true)

=item *

B<ignore_timing> -
(Type 'in' only) Ignore incoming timing messages (defaults to true)

=item *

B<ignore_sensing> -
(Type 'in' only) Ignore incoming active sensing messages (defaults to true)

=item *

B<_skip_free> -
A hack to prevent memory errors when a device is being cleaned up.
Skips C<free()> (defaults to false)

=back

=cut

sub new {
    my ( $class, @args ) = @_;
    my $self = ( @args == 1 and ref $args[0] eq 'HASH' )
        ? bless( $args[0], $class )
        : bless( { @args }, $class );
    $self->{type} //= 'out';
    $self->{ignore_sysex} //= 1;
    $self->{ignore_timing} //= 1;
    $self->{ignore_sensing} //= 1;
    croak "Unknown type : $self->{type}" unless $self->{type} eq 'in' || $self->{type} eq 'out';
    $self->_create_device;
    return $self;
}

=head2 ok, msg, data, ptr

    warn $device->msg unless $device->ok;

Getters for RtMidiWrapper device struct members

=cut

sub ok   { $_[0]->{device}->ok }
sub msg  { $_[0]->{device}->msg }
sub data { $_[0]->{device}->data }
sub ptr  { $_[0]->{device}->ptr }

=head2 open_virtual_port

    $device->open_virtual_port( $name );

Open a virtual device port.

This method will not work on Windows.

=cut

sub open_virtual_port {
    my ( $self, $port_name ) = @_;
    rtmidi_open_virtual_port( $self->{device}, $port_name );
}

=head2 open_port

    $device->open_port( $port, $name );

Open a port.

=cut

sub open_port {
    my ( $self, $port_number, $port_name ) = @_;
    $self->{port_name} = $port_name;
    rtmidi_open_port( $self->{device}, $port_number, $port_name );
}

=head2 get_ports_by_name

    $device->get_ports_by_name( $name );
    $device->get_ports_by_name( qr/name/ );

Returns a list of ports matching the supplied name criteria.

=cut

sub get_ports_by_name {
    my ( $self, $name ) = @_;
    my @ports = grep {
        my $pn = $self->get_port_name( $_ );
        ref $name eq 'Regexp'
            ? $pn =~ $name
            : $pn eq $name
    } 0..($self->get_port_count-1);
    return @ports;
}

=head2 open_port_by_name

    $device->open_port_by_name( $name );
    $device->open_port_by_name( qr/name/ );
    $device->open_port_by_name( [ $name, $othername, qr/anothername/ ] );

Opens the first port found matching the supplied name criteria.

=cut

sub open_port_by_name {
    my ( $self, $name, $portname ) = @_;
    $portname //= $self->{type} . '-' . time();
    if ( ref $name eq 'ARRAY' ) {
        for ( @{ $name } ) {
            return if $self->open_port_by_name( $_ );
        }
    }
    else {
        my @ports = $self->get_ports_by_name( $name );
        return 0 unless @ports;
        return !$self->open_port( $ports[0], $portname );
    }
}

=head2 close_port

    $device->close_port();

Closes the currently open port

=cut

sub close_port {
    my ( $self ) = @_;
    rtmidi_close_port( $self->{device} );
}

=head2 get_port_count

    $device->get_port_count();

Return the number of available MIDI ports to connect to.

=cut

sub get_port_count {
    my ( $self ) = @_;
    rtmidi_get_port_count( $self->{device} );
}

=head2 get_port_name

    $self->get_port_name( $port );

Returns the name of the supplied port number.

=cut

sub get_port_name {
    my ( $self, $port_number ) = @_;
    rtmidi_get_port_name( $self->{device}, $port_number );
}

=head2 get_current_api

    $self->get_current_api();

Returns the MIDI API in use for the device.

This is a L<RtMidiApi constant|MIDI::RtMidi::FFI/"RtMidiApi">.

=cut

sub get_current_api {
    my ( $self ) = @_;
    my $api_dispatch = {
        rtmidi_in_get_current_api => \&rtmidi_in_get_current_api,
        rtmidi_out_get_current_api => \&rtmidi_out_get_current_api,
    };
    my $fn = "rtmidi_$self->{type}_get_current_api";
    croak "Unknown device type : $self->{type}" unless $api_dispatch->{ $fn };
    $api_dispatch->{ $fn }->( $self->{device} );
}

=head2 set_callback 🐉

Here be dragons.

    $device->set_callback( sub {
        my ( $ts, $msg, $data );
        # handle $msg here
    }, $data );

Type 'in' only. Sets a callback to be executed when an incoming message is
received. Your callback receives the timestamp of the event, the message, and
optionally some data you set while defining the callback. This data should
be a simple scalar string, not a reference or other data structure.

In my experience, receiving a message on your device while a callback is in
progress results in a crash.

Depending on the message rate your application expects, this may be OK.

=cut

sub set_callback {
    my ( $self, $cb, $data ) = @_;
    croak "Unable to set_callback for device type : $self->{type}" unless $self->{type} eq 'in';
    $self->{callback} = rtmidi_in_set_callback( $self->{device}, $cb, $data );
}

=head2 cancel_callback

    $device->cancel_callback();

Type 'in' only. Removes the callback from your device.

=cut

sub cancel_callback {
    my ( $self ) = @_;
    croak "Unable to cancel_callback for device type : $self->{type}" unless $self->{type} eq 'in';
    rtmidi_in_cancel_callback( $self->{device} );
}

=head2 ignore_types

    $device->ignore_types( $ignore_sysex, $ignore_timing, $ignore_sensing );
    $device->ignore_types( (1)x3 );

Type 'in' only. Set message types to ignore.

=cut

sub ignore_types {
    my ( $self, $sysex, $time, $sense ) = @_;
    croak "Unable to ignore_types for device type : $self->{type}" unless $self->{type} eq 'in';
    rtmidi_in_ignore_types( $self->{device}, $sysex, $time, $sense );
}

=head2 get_message

    $device->get_message();

Type 'in' only. Gets the next message from the queue, if available.

=cut

sub get_message {
    my ( $self ) = @_;
    croak "Unable to get_message for device type : $self->{type}" unless $self->{type} eq 'in';
    rtmidi_in_get_message( $self->{device}, $self->{queue_size_limit} );
}

=head2 send_message

    $device->send_message( $msg );

Type 'out' only. Sends a message to the open port.

=cut

sub send_message {
    my ( $self, $msg ) = @_;
    croak "Unable to send_message for device type : $self->{type}" unless $self->{type} eq 'out';
    rtmidi_out_send_message( $self->{device}, $msg );
}

=head2 send_event

    $device->send_event( @event );
    $device->send_event( note_on => 0, 0, 0x40, 0x5a );

Type 'out' only. Sends a L<MIDI::Event> encoded message to the open port.

=cut

sub send_event {
    my ( $self, @event ) = @_;
    my $msg = MIDI::Event::encode( [[@event]], { never_add_eot => 1 } );
    $self->send_message( ${ $msg } );
}

sub port_name { $_[0]->{port_name}; }
sub name { $_[0]->{name}; }

sub _create_device {
    my ( $self ) = @_;
    my $create_dispatch = {
        rtmidi_out_create_default => \&rtmidi_out_create_default,
        rtmidi_out_create => \&rtmidi_out_create,
        rtmidi_in_create_default => \&rtmidi_in_create_default,
        rtmidi_in_create => \&rtmidi_in_create,
    };
    my $fn = "rtmidi_$self->{type}_create";
    $fn = "${fn}_default" if !$self->{api} && !$self->{name} && !$self->{queue_size_limit};
    croak "Unknown type : $self->{type}" unless $create_dispatch->{ $fn };

    $self->{queue_size_limit} //= $self->{bufsize} //= 1024;
    $self->{device} = $create_dispatch->{ $fn }->( $self->{api}, $self->{name}, $self->{queue_size_limit} );
    $self->{type} eq 'in' && $self->ignore_types(
        $self->{ignore_sysex},
        $self->{ignore_timing},
        $self->{ignore_sensing},
    );
}

sub DESTROY {
    my ( $self ) = @_;
    my $free_dispatch = {
        rtmidi_in_free => \&rtmidi_in_free,
        rtmidi_out_free => \&rtmidi_out_free
    };
    my $fn = "rtmidi_$self->{type}_free";
    croak "Unable to free type : $self->{type}" unless $free_dispatch->{ $fn };
    $free_dispatch->{ $fn }->( $self->{device} ) unless $self->{_skip_free};
}

1;

__END__

=head1 TODO

=head2 Deprecate the dragon

The callback mechanism for handling incoming events is useful. It would be nice
if it were more robust.

=head2 Deprecate _skip_free

I've found this is only required for certain builds of librtmidi v3.0.0, but
not requiring it at all would be better.

=head1 SEE ALSO

L<RtMidi|https://www.music.mcgill.ca/~gary/rtmidi/>

L<MIDI::RtMidi::FFI>

L<MIDI::Event>

=head1 AUTHOR

John Barrett, <john@jbrt.org>

=head1 CONTRIBUTING

L<https://github.com/jbarrett/MIDI-RtMidi-FFI>

All comments and contributions welcome.

=head1 BUGS AND SUPPORT

Please direct all requests to L<https://github.com/jbarrett/MIDI-RtMidi-FFI/issues>

=head1 COPYRIGHT

Copyright 2019 John Barrett.

=head1 LICENSE

This application is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
