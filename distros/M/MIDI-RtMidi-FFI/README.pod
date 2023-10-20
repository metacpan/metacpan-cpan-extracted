use strict;
use warnings;
package MIDI::RtMidi::FFI::Device;

# ABSTRACT: OO interface for MIDI::RtMidi::FFI

=encoding UTF-8

=head1 SYNOPSIS

    use MIDI::RtMidi::FFI::Device;
    
    my $device = RtMidiOut->new;
    $device->open_virtual_port( 'perl-rtmidi' );
    $device->send_event( note_on => 0x00, 0x40, 0x5a );
    sleep 1;
    $device->send_event( note_off => 0x00, 0x40, 0x5a );

=head1 DESCRIPTION

MIDI::RtMidi::FFI::Device is an OO interface for L<MIDI::RtMidi::FFI> to help
you manage devices, ports and MIDI events.

=cut

use MIDI::RtMidi::FFI ':all';
use MIDI::Event;
use Carp;

our $VERSION = '0.00';

my $rtmidi_api_names = {
    unspecified => [ "Unknown",            RTMIDI_API_UNSPECIFIED ],
    core        => [ "CoreMidi",           RTMIDI_API_MACOSX_CORE ],
    alsa        => [ "ALSA",               RTMIDI_API_LINUX_ALSA ],
    jack        => [ "Jack",               RTMIDI_API_UNIX_JACK ],
    winmm       => [ "Windows MultiMedia", RTMIDI_API_WINDOWS_MM ],
    dummy       => [ "Dummy",              RTMIDI_API_RTMIDI_DUMMY ]
};

=head1 METHODS

=head2 new

    my $device = MIDI::RtMidi::FFI::Device->new( %options );
    my $midiin = RtMidiIn->new( %options );
    my $midiout = RtMidiOut->new( %options );

Returns a new MIDI::RtMidi::FFI::Device object. RtMidiIn and RtMidiOut are
provided as shorthand to instantiate devices of type 'in' and 'out'
respectively. Valid attributes:

=over 4

=item *

B<type> -
Device type : 'in' or 'out' (defaults to 'out')

Ignored if instantiating RtMidiIn or RtMidiOut.

=item *

B<api> -
MIDI API to use. This should be a L<RtMidiApi constant|MIDI::RtMidi::FFI/"RtMidiApi">.
By default the device should use the first compiled API available. See search
order notes in
L<Using Simultaneous Multiple APIs|https://www.music.mcgill.ca/~gary/rtmidi/index.html#multi>
on the RtMidi website.

=item *

B<api_name> -
MIDI API to use by name. One of 'alsa', 'jack', 'core', 'winmm' or 'dummy'.

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
(Type 'in' only) Ignore incoming SysEx messages (defaults to true)

=item *

B<ignore_timing> -
(Type 'in' only) Ignore incoming timing messages (defaults to true)

=item *

B<ignore_sensing> -
(Type 'in' only) Ignore incoming active sensing messages (defaults to true)

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

Open a virtual device port. A virtual device may be connected to other MIDI software, just as with a hardware device.

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

=head2 set_callback

    $device->set_callback( sub {
        my ( $ts, $msg ) = @_;
        # handle $msg here
    } );

Type 'in' only. Sets a callback to be executed when an incoming MIDI message is
received. Your callback receives the time which has elapsed since the previous
event in seconds, alongside the MIDI message.

As a callback may occur at any point in your program's flow, the program should
probably not be doing much when it occurs. That is, programs handling RtMidi
callbacks should be asleep or awaiting user input when the callback is
triggered.

For the sake of compatibility with previous versions, some data may be passed
which is passed to the callback for each event. This data parameter exists in
the librtmidi interface to work around the lack of closures in C. It is less
useful in Perl, though you are free to use it.

The data is not stored by librtmidi, so may be any Perl data structure you
like.

    $device->set_callback( sub {
        my ( $ts, $msg, $data ) = @_;
        # handle $msg here
    }, $data );

See the examples included with this dist for some ideas on how to incorporate
callbacks into your program.

=cut

sub set_callback {
    my ( $self, $cb, $data ) = @_;
    croak "Unable to set_callback for device type : $self->{type}" unless $self->{type} eq 'in';
    $self->{callback} = rtmidi_in_set_callback( $self->{device}, $cb, $data );
}

=head2 set_callback_decoded

    $device->set_callback_decoded( sub {
        my ( $ts, $msg, $event ) = @_;
        # handle $msg / $event here
    } );

Same as L</set_callback>, though also attempts to decode the message with
L<MIDI::Event>, which is passed to the callback as an array ref. The original
message is also sent in case this fails.

=cut

sub set_callback_decoded {
    my ( $self, $cb, $data ) = @_;
    my $event_cb = sub {
        my ( $ts, $msg, $data ) = @_;
        my $decoded = $self->decode_message( $msg );
        $cb->( $ts, $msg, $decoded, $data );
    };
    $self->set_callback( $event_cb, $data );
}
=head2 cancel_callback

    $device->cancel_callback();

Type 'in' only. Removes the callback from your device.

=cut

sub cancel_callback {
    my ( $self ) = @_;
    return unless $self->{callback};
    croak "Unable to cancel_callback for device type : $self->{type}" unless $self->{type} eq 'in';
    delete $self->{callback};
    rtmidi_in_cancel_callback( $self->{device} );
}

=head2 ignore_types

    $device->ignore_types( $ignore_sysex, $ignore_timing, $ignore_sensing );
    $device->ignore_types( (1)x3 );

Type 'in' only. Set message types to ignore.

=cut

sub ignore_types {
    my ( $self, $sysex, $timing, $sensing ) = @_;
    @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } = ( $sysex, $timing, $sensing );
    croak "Unable to ignore_types for device type : $self->{type}" unless $self->{type} eq 'in';
    rtmidi_in_ignore_types( $self->{device}, $sysex, $timing, $sensing );
}

=head2 ignore_sysex

    $device->ignore_sysex( 1 );
    $device->ignore_sysex( 0 );

Type 'in' only. Set whether or not to ignore sysex messages.

=cut

sub ignore_sysex {
    my ( $self, $ignore_sysex ) = @_;
    $self->{ignore_sysex} = $ignore_sysex;
    $self->ignore_types( @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } )
}

=head2 ignore_timing

    $device->ignore_timing( 1 );
    $device->ignore_timing( 0 );

Type 'in' only. Set whether or not to ignore timing messages.

=cut

sub ignore_timing {
    my ( $self, $ignore_timing ) = @_;
    $self->{ignore_timing} = $ignore_timing;
    $self->ignore_types( @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } )
}

=head2 ignore_sensing

    $device->ignore_sensing( 1 );
    $device->ignore_sensing( 0 );

Type 'in' only. Set whether or not to ignore active sensing messages.

=cut

sub ignore_sensing {
    my ( $self, $ignore_sensing ) = @_;
    $self->{ignore_sensing} = $ignore_sensing;
    $self->ignore_types( @{ $self }{ qw/ ignore_sysex ignore_timing ignore_sensing / } )
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

=head2 get_event

    $device->get_message_decoded();

Type 'in' only. Gets the next message from the queue, if available, as a
decoded L<MIDI::Event>.

=cut

sub get_message_decoded {
    my ( $self ) = @_;
    $self->decode_message( $self->get_message );
}

=head2 get_event

Alias for L</get_message_decoded>, for backwards compatibility.

B<NB> Previous versions of this call spliced out the channel portion of the
message. This is no longer the case. The dtime (or delta-time) portion is still
removed.

=cut

*get_event = \&get_message_decoded;

=head2 decode_message

    $device->decode_message( $msg );

Attempts to decode the passed message with L<Midi::Event>. Decoded messages
should match the events listed in MIDI::Event documentation, except without
dtime.

=cut

sub decode_message {
    my ( $self, $msg ) = @_;
    return unless $msg;

    # Real-time messages don't have 'dtime', but MIDI::Event expects it:
    $msg = chr(0) . $msg;

    my $decoded = MIDI::Event::decode( \$msg )->[0];

    if ( ref $decoded ne 'ARRAY' ) {
        warn "Could not decode message " . unpack( 'H*', $msg );
        return;
    }

    # Delete dtime
    splice( @{ $decoded }, 1, 1 );

    $decoded->[0] = 'note_off' if ( $decoded->[0] eq 'note_on' && $decoded->[-1] == 0 );
    return wantarray
        ? @{ $decoded }
        : $decoded;
}

=head2 send_message

    $device->send_message( $msg );

Type 'out' only. Sends a message to the device's open port.

=cut

sub send_message {
    my ( $self, $msg ) = @_;
    croak "Unable to send_message for device type : $self->{type}" unless $self->{type} eq 'out';
    rtmidi_out_send_message( $self->{device}, $msg );
}

=head2 encode_message

    my $msg = $device->encode_message( note_on => 0x00, 0x40, 0x5a )
    $device->send_message( $msg );

Attempts to encode the passed message with L<MIDI::Event>.
The specification for events is the same as those listed in MIDI::Event's
documentation, except dtime should be omitted.

=cut

sub encode_message {
    my ( $self, @event ) = @_;

    $event[0] = 'sysex_f0' if $event[0] eq 'sysex';

    # Insert 0 dtime
    splice @event, 1, 0, 0;

    my $msg = MIDI::Event::encode( [[@event]], { never_add_eot => 1 } );

    # Strip dtime before send
    substr( $$msg, 0, 1 ) = '';

    # Terminate SysEx messages (hax hax hax, probably fragile...)
    my $first = substr( $$msg, 0, 1 );
    if ( ( $first eq chr( 0xf0 ) || $first eq chr( 0xf7 ) ) && substr( $$msg, -1, 1 ) ne chr( 0xf7 ) ) {
        $$msg .= chr( 0xf7 );
    }

    return $$msg;
}

=head2 send_message_encoded

    $device->send_message_encoded( @event );
    # Event, channel, note, velocity
    $device->send_message_encoded( note_on => 0x00, 0x40, 0x5a );
    $device->send_message_encoded( sysex => "Hello, computer?" );

Type 'out' only. Sends a L<MIDI::Event> encoded message to the open port.

=cut

sub send_message_encoded {
    my ( $self, @event ) = @_;
    $self->send_message( $self->encode_message( @event ) );
}

=head2 send_event

Alias for L</send_message_encoded>, for backwards compatibility.

B<NB> Previous versions of this module stripped channel data from messages.
This is no longer the case - channel should be provided where necessary.

=cut

*send_event = \&send_message_encoded;

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
    my $api_by_name;
    $api_by_name = $rtmidi_api_names->{ $self->{api_str} } if $self->{api_str};
    $self->{api} //= $api_by_name->[1] if $api_by_name;
    $self->{api} //= $rtmidi_api_names->{ unspecified }->[1];
    $self->{device} = $create_dispatch->{ $fn }->( $self->{api}, $self->{name}, $self->{queue_size_limit} );
    $self->{type} eq 'in' && $self->ignore_types(
        $self->{ignore_sysex},
        $self->{ignore_timing},
        $self->{ignore_sensing},
    );
}

my $free_dispatch = {
    in  => \&rtmidi_in_free,
    out => \&rtmidi_out_free
};
sub DESTROY {
    my ( $self ) = @_;
    my $fn = $free_dispatch->{ $self->{type} };
    # croak "Unable to free type : $self->{type}" unless $fn;
    # There is an extant issue around the Perl object lifecycle and C++ object lifecycle.
    # If we free the RtMidiPtr here, a double-free error may occur on process exit.
    # For now, cancel the callback and close the port, then trust the process ...
    $self->cancel_callback;
    $self->close_port;
    # $fn->( $self->{device} );
}

{
    package RtMidiIn;
    use strict; use warnings;
    sub new {
        shift;
        MIDI::RtMidi::FFI::Device->new( @_, type => 'in' );
    }
}

{
    package RtMidiOut;
    use strict; use warnings;
    sub new {
        shift;
        MIDI::RtMidi::FFI::Device->new( @_, type => 'out' );
    }
}

1;

__END__

=head1 KNOWN ISSUES

Use of L<MIDI::Event> is a bit of a hack for convenience, exploiting the
similarity of realtime MIDI messages and MIDI song file messages. It may break
in unexpected ways if used for large SysEx messages or other "non-music"
events, though should be fine for encoding and decoding note, pitch, aftertouch
and CC messages.

=head1 SEE ALSO

L<RtMidi|https://www.music.mcgill.ca/~gary/rtmidi/>

L<MIDI::RtMidi::FFI>

L<MIDI::Event>

=head1 CONTRIBUTING

L<https://github.com/jbarrett/MIDI-RtMidi-FFI>

All comments and contributions welcome.

=head1 BUGS AND SUPPORT

Please direct all requests to L<https://github.com/jbarrett/MIDI-RtMidi-FFI/issues>

=cut
