use strict;
use warnings;
package MIDI::RtMidi::FFI;
use base qw/ Exporter /;

our $VERSION = '0.01';

# ABSTRACT: Bindings for librtmidi - Realtime MIDI library

=encoding UTF-8

=head1 NAME

MIDI::RtMidi::FFI - Perl bindings for RtMidi.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use MIDI::RtMidi::FFI ':all';
    use MIDI::Event;
    
    my $device = rtmidi_out_create( RTMIDI_API_UNIX_JACK, 'perl-jack' );
    my $port_count = rtmidi_get_port_count( $device );
    my $synth_port = grep {
        rtmidi_get_port_name( $device, $_ ) =~ /synth/i
    } 0..($port_count-1);
    
    rtmidi_open_port( $device, $synth_port, 'my synth' );
    rtmidi_out_send_message(
        $device,
        ${ MIDI::Event::encode([[ note_on => 0, 0, 0x40, 0x5a ]], { never_add_eot => 1 }) }
    );

=head1 DESCRIPTION

L<RtMidi|https://www.music.mcgill.ca/~gary/rtmidi/> provides a common API for
realtime MIDI input/output supporting ALSA, JACK, CoreMIDI and Windows
Multimedia.

MIDI::RtMidi::FFI provides a more-or-less direct binding to
L<RtMidi's C Interface|https://www.music.mcgill.ca/~gary/rtmidi/group__C-interface.html>.
MIDI::RtMidi::FFI should work with v3.0.0, v4.0.0 and possibly later versions
of librtmidi.

Check out L<MIDI::RtMidi::FFI::Device> for an OO interface to this module.

=cut

{
package RtMidiWrapper;
use FFI::Platypus::Record;

record_layout(
    opaque => 'ptr',
    opaque => 'data',
    bool   => 'ok',
    string => 'msg'
);
}

use FFI::Platypus;
use FFI::CheckLib;
use FFI::Platypus::Buffer qw/ scalar_to_buffer buffer_to_scalar /;
use FFI::Platypus::Memory qw/ malloc free /;

my $ffi = FFI::Platypus->new;
$ffi->lib( find_lib_or_die( lib => 'rtmidi' ) );
$ffi->ignore_not_found(1);

$ffi->type("record(RtMidiWrapper)" => 'RtMidiPtr');
$ffi->type("record(RtMidiWrapper)" => 'RtMidiInPtr');
$ffi->type("record(RtMidiWrapper)" => 'RtMidiOutPtr');

=head1 ENUMS

=head2 RtMidiApi

RTMIDI_API_UNSPECIFIED, RTMIDI_API_MACOSX_CORE, RTMIDI_API_LINUX_ALSA,
RTMIDI_API_UNIX_JACK, RTMIDI_API_WINDOWS_MM, RTMIDI_API_RTMIDI_DUMMY,
RTMIDI_API_NUM

=cut

# enum RtMidiApi
use constant RTMIDI_API_UNSPECIFIED  => 0;
use constant RTMIDI_API_MACOSX_CORE  => 1;
use constant RTMIDI_API_LINUX_ALSA   => 2;
use constant RTMIDI_API_UNIX_JACK    => 3;
use constant RTMIDI_API_WINDOWS_MM   => 4;
use constant RTMIDI_API_RTMIDI_DUMMY => 5;
use constant RTMIDI_API_NUM          => 6;
$ffi->type(enum => 'RtMidiApi');

=head2 RtMidiErrorType

RTMIDI_ERROR_WARNING, RTMIDI_ERROR_DEBUG_WARNING, RTMIDI_ERROR_UNSPECIFIED,
RTMIDI_ERROR_NO_DEVICES_FOUND, RTMIDI_ERROR_INVALID_DEVICE,
RTMIDI_ERROR_MEMORY_ERROR, RTMIDI_ERROR_INVALID_PARAMETER,
RTMIDI_ERROR_INVALID_USE, RTMIDI_ERROR_DRIVER_ERROR, RTMIDI_ERROR_SYSTEM_ERROR,
RTMIDI_ERROR_THREAD_ERROR

=cut

# enum RtMidiErrorType
use constant RTMIDI_ERROR_WARNING           => 0;
use constant RTMIDI_ERROR_DEBUG_WARNING     => 1;
use constant RTMIDI_ERROR_UNSPECIFIED       => 2;
use constant RTMIDI_ERROR_NO_DEVICES_FOUND  => 3;
use constant RTMIDI_ERROR_INVALID_DEVICE    => 4;
use constant RTMIDI_ERROR_MEMORY_ERROR      => 5;
use constant RTMIDI_ERROR_INVALID_PARAMETER => 6;
use constant RTMIDI_ERROR_INVALID_USE       => 7;
use constant RTMIDI_ERROR_DRIVER_ERROR      => 8;
use constant RTMIDI_ERROR_SYSTEM_ERROR      => 9;
use constant RTMIDI_ERROR_THREAD_ERROR      => 10;
$ffi->type(enum => 'RtMidiErrorType');

=head1 FUNCTIONS

=cut

$ffi->attach( rtmidi_api_display_name => ['int'] => 'string' );
$ffi->attach( rtmidi_api_name => ['int'] => 'string' );

sub RTMIDI_VERSION { defined &rtmidi_api_display_name ? 4 : 3 }

$ffi->attach(
    rtmidi_get_compiled_api =>
    (RTMIDI_VERSION>3?['opaque', 'unsigned int']:['opaque*']) =>
    'int', sub {
        my ( $sub, $get ) = @_;
        my $num_apis = $sub->();
        return unless $num_apis;
        return $num_apis unless $get;
        my $apis = malloc RTMIDI_API_NUM * $ffi->sizeof('enum');
        $sub->( $apis, RTMIDI_API_NUM ) if RTMIDI_VERSION > 3;
        $sub->( \$apis ) if RTMIDI_VERSION==3;
        my $api_arr = $ffi->cast( 'opaque' => "enum[$num_apis]", $apis );
        free $apis;
        return $api_arr;
    }
);
$ffi->attach( rtmidi_compiled_api_by_name => ['string'] => 'int' );
$ffi->attach( rtmidi_open_port => ['RtMidiPtr', 'int', 'string'] => 'void' );
$ffi->attach( rtmidi_open_virtual_port => ['RtMidiPtr', 'string'] => 'void' );
$ffi->attach( rtmidi_close_port => ['int'] => 'void' );
$ffi->attach( rtmidi_get_port_count => ['RtMidiPtr'] => 'int' );
$ffi->attach( rtmidi_get_port_name => ['RtMidiPtr', 'int'] => 'string' );
$ffi->attach( rtmidi_in_create_default => ['void'] => 'RtMidiInPtr' );
$ffi->attach( rtmidi_in_create => ['int', 'string', 'unsigned int'] => 'RtMidiInPtr' );
$ffi->attach( rtmidi_in_free => ['RtMidiInPtr'] => 'void' );
$ffi->attach( rtmidi_in_get_current_api => ['RtMidiInPtr'] => 'int' );
$ffi->attach( rtmidi_in_cancel_callback => ['RtMidiInPtr'] => 'void' );
$ffi->attach( rtmidi_in_ignore_types => ['RtMidiInPtr','bool','bool','bool'] => 'void' );
$ffi->attach( rtmidi_out_create_default => ['void'] => 'RtMidiOutPtr' );
$ffi->attach( rtmidi_out_create => ['int', 'string'] => 'RtMidiOutPtr' );
$ffi->attach( rtmidi_out_free => ['RtMidiOutPtr'] => 'void' );
$ffi->attach( rtmidi_out_get_current_api => ['RtMidiOutPtr'] => 'int' );
$ffi->attach(
    rtmidi_in_get_message =>
    ['RtMidiInPtr',(RTMIDI_VERSION>3?'opaque':'opaque*'),'size_t*'] =>
    'double',
    sub {
        my ( $sub, $dev, $size ) = @_;
        $size //= 1024;
        my $str = malloc $size;
        $sub->( $dev, $str, \$size ) if RTMIDI_VERSION > 3;
        $sub->( $dev, \$str, \$size ) if RTMIDI_VERSION == 3;
        my $msg = buffer_to_scalar( $str, $size );
        free $str;
        return $msg;
    }
);
$ffi->attach(
    rtmidi_out_send_message =>
    ['RtMidiOutPtr','opaque','int']
    => 'int',
    sub {
        my ( $sub, $dev, $str ) = @_;
        my ( $buffer, $bufsize ) = scalar_to_buffer $str;
        $sub->( $dev, $buffer, $bufsize );
    }
);
if ( RTMIDI_VERSION > 3 ) {
    $ffi->type('(double,opaque,size_t,string)->void' => 'RtMidiCCallback');
    $ffi->attach( rtmidi_in_set_callback => ['RtMidiInPtr','RtMidiCCallback','string'] => 'void', sub {
        my ( $sub, $dev, $cb, $data ) = @_;
        my $callback = sub {
            my ( $timestamp, $inmsg, $size, $data ) = @_;
            my $msg = buffer_to_scalar $inmsg, $size;
            $cb->( $timestamp, $msg, $data );
        };
        my $closure = $ffi->closure($callback);
        $sub->( $dev, $closure, $data );
        return $closure;
    } );
}
else {
    $ffi->type('(double,string,string)->void' => 'RtMidiCCallback');
    $ffi->attach( rtmidi_in_set_callback => ['RtMidiInPtr','RtMidiCCallback','string'] => 'void', sub {
            my ( $sub, $dev, $cb, $data ) = @_;
            my $closure = $ffi->closure($cb);
            $sub->( $dev, $closure, $data );
            return $closure;
        }
    );
}

our @EXPORT_OK = (qw/
    RTMIDI_API_UNSPECIFIED
    RTMIDI_API_MACOSX_CORE
    RTMIDI_API_LINUX_ALSA
    RTMIDI_API_UNIX_JACK
    RTMIDI_API_WINDOWS_MM
    RTMIDI_API_RTMIDI_DUMMY
    RTMIDI_API_NUM
    RTMIDI_ERROR_WARNING
    RTMIDI_ERROR_DEBUG_WARNING
    RTMIDI_ERROR_UNSPECIFIED
    RTMIDI_ERROR_NO_DEVICES_FOUND
    RTMIDI_ERROR_INVALID_DEVICE
    RTMIDI_ERROR_MEMORY_ERROR
    RTMIDI_ERROR_INVALID_PARAMETER
    RTMIDI_ERROR_INVALID_USE
    RTMIDI_ERROR_DRIVER_ERROR
    RTMIDI_ERROR_SYSTEM_ERROR
    RTMIDI_ERROR_THREAD_ERROR
    RTMIDI_VERSION
    rtmidi_get_compiled_api
    rtmidi_api_display_name
    rtmidi_api_name
    rtmidi_compiled_api_by_name
    rtmidi_open_port
    rtmidi_open_virtual_port
    rtmidi_close_port
    rtmidi_get_port_count
    rtmidi_get_port_name
    rtmidi_in_create_default
    rtmidi_in_create
    rtmidi_in_free
    rtmidi_in_get_current_api
    rtmidi_in_cancel_callback
    rtmidi_in_ignore_types
    rtmidi_in_get_message
    rtmidi_out_create_default
    rtmidi_out_create
    rtmidi_out_free
    rtmidi_out_get_current_api
    rtmidi_out_send_message
    rtmidi_in_set_callback
/);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

__END__


=head2 rtmidi_get_compiled_api

    rtmidi_get_compiled_api( $return_apis );
    rtmidi_get_compiled_api( 1 );

Returns available APIs.

Pass a true value to return an array ref of available APIs as RT_API constants,
otherwise a count of available APIs is returned.

=head2 rtmidi_api_display_name

    rtmidi_api_display_name( $api );

From v4.0.0. Returns the associated display name for a RTMIDI_API constant.

=head2 rtmidi_api_name

    rtmidi_api_name( $api );

From v4.0.0. Returns the associated name for a given RTMIDI_API constant.

=head2 rtmidi_compiled_api_by_name

    rtmidi_compiled_api_by_name( $name );

From v4.0.0. Returns the associated RTMIDI_API constant for a given name.

=head2 rtmidi_open_port

    rtmidi_open_port( $device, $port, $name );

Open a MIDI port.

=head2 rtmidi_open_virtual_port

    rtmidi_open_virtual_port( $device, $name );

Creates a virtual MIDI port to which other software applications can connect.

=head2 rtmidi_close_port

    rtmidi_close_port( $device );

Close a MIDI connection.

=head2 rtmidi_get_port_count

    rtmidi_get_port_count( $device );

Return the number of available MIDI ports.

=head2 rtmidi_get_port_name

    rtmidi_get_port_name( $device, $port );

Return the name for the specified MIDI input port number.

=head2 rtmidi_in_create_default

    rtmidi_in_create_default();

Create a default MIDI in device with no initial values.

=head2 rtmidi_in_create

    rtmidi_in_create( $api, $name, $queuesize );

Create a MIDI in device with initial values.

=head2 rtmidi_in_free

    rtmidi_in_free( $device );

Free the given MIDI in device.

=head2 rtmidi_in_get_current_api

    rtmidi_in_get_current_api( $device );

Return the RTMIDI_API constant for the given device.

=head2 rtmidi_in_set_callback

    rtmidi_in_set_callback( $device, $coderef, $data );

Set a callback function to be invoked for incoming MIDI messages.

Your callback receives the timestamp of the event, the message and the data you
set while defining the callback. Due to the way params are packed, this data
can only be a simple scalar, not a reference.

B<NB> This is not recommended in the current implementation. If a message
arrives while the callback is already running, your program will segfault!

=head2 rtmidi_in_cancel_callback

    rtmidi_in_cancel_callback( $device );

Cancel use of the current callback function (if one exists).

=head2 rtmidi_in_ignore_types

    rtmidi_in_ignore_types( $device, $ignore_sysex, $ignore_timing, $ignore_sensing );

Specify whether certain MIDI message types should be queued or ignored during input.

=head2 rtmidi_out_create_default

    rtmidi_out_create_default();

Create a default MIDI out device with no initial values.

=head2 rtmidi_out_create

    rtmidi_out_create( $api, $name );

Create a MIDI out device with initial values.

=head2 rtmidi_out_free

    rtmidi_out_free( $device );

Free the given MIDI out device.

=head2 rtmidi_out_get_current_api

    rtmidi_out_get_current_api( $device );

Return the RTMIDI_API constant for the given device.

=head2 rtmidi_out_send_message

    rtmidi_out_send_message( $device, $message );

Send a single message out an open MIDI output port.

=head1 SEE ALSO

L<RtMidi|https://www.music.mcgill.ca/~gary/rtmidi/>

L<MIDI::RtMidi::FFI::Device>

L<MIDI::ALSA>

L<Win32API::MIDI>

L<Mac::CoreMIDI>

L<MIDI::Music>

L<MIDI::Realtime>

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
