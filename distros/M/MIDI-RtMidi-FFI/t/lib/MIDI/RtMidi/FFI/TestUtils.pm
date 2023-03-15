use strict;
use warnings;
package MIDI::RtMidi::FFI::TestUtils;
use base qw/ Exporter /;

use MIDI::RtMidi::FFI::Device;
use MIDI::RtMidi::FFI ':all';
use MIDI::Event;
use Proc::Find qw/ proc_exists /;

use Time::HiRes qw/ usleep /;

my $time = time();

sub newdevice {
    my ( $type, $name ) = @_;
    $type //= 'out';
    $name //= "rtmidi-ffi-test-$type-$time";
    MIDI::RtMidi::FFI::Device->new(
        type => $type,
        name => $name,
        ignore_sysex => 0,
        ignore_timing => 0,
        ignore_sensing => 0,
    );
}

sub connect_devices {
    my ( $in, $out ) = @_;
    my $port_name = "rtmidi-ffi-port-out-$time";
    $in->open_virtual_port( $port_name );
    $out->open_port_by_name( qr/$port_name/ );
}

# TAP readability
sub msg2hex { unpack( 'H*', $_[0] ) }
sub msgs2hex { [ map { msg2hex( $_ ) } @_ ] }

sub drain_msgs {
    my ( $device, $count, $sleep ) = @_;
    $sleep //= 10_000;
    my @msgs; my $total_time;
    while ( @msgs < $count ) {
        my $in = $device->get_message;
        push @msgs, $in if $in;
        usleep $sleep;
        $total_time += $sleep;
        return @msgs if $total_time > 1_000_000;
    }
    return @msgs;
}

sub no_virtual {
    my $api = rtmidi_get_compiled_api( 1 )->[0];
    return 1 if
        ( $api == RTMIDI_API_WINDOWS_MM ||
          $api == RTMIDI_API_RTMIDI_DUMMY );
    0;
}

sub sanity_check {
    # TODO: Extend this for other platforms
    my $api = rtmidi_get_compiled_api( 1 )->[0];
    if ( $api == RTMIDI_API_LINUX_ALSA ) {
        return 0 unless -w '/dev/snd/seq';
    }
    if ( $api == RTMIDI_API_UNIX_JACK ) {
        return 0 unless proc_exists( name => 'jackd' );
    }
    1;
}

our @EXPORT = (qw/
    newdevice
    connect_devices
    msg2hex
    msgs2hex
    drain_msgs
    no_virtual
    sanity_check
/);
