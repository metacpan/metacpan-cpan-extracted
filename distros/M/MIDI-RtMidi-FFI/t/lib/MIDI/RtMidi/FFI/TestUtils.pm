use strict;
use warnings;
package MIDI::RtMidi::FFI::TestUtils;
use base qw/ Exporter /;

use MIDI::RtMidi::FFI::Device;
use MIDI::Event;

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
        _skip_free => 1
    );
}

sub connect_devices {
    my ( $in, $out ) = @_;
    my $port_name = "rtmidi-ffi-port-out-$time";
    $out->open_virtual_port( $port_name );
    $in->open_port_by_name( qr/$port_name/ );
}

# TAP readability
sub msg2hex { join '', map { sprintf "%02x", ord $_ } split '', $_[0]; }
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

our @EXPORT = (qw/
    newdevice
    connect_devices
    msg2hex
    msgs2hex
    drain_msgs
/);
