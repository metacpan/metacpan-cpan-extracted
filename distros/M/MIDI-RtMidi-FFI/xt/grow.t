use strict;
use warnings;

use Test2::V0;
use Test::MemoryGrowth;
use Test::Lib;
use Time::HiRes qw/ usleep /;

use MIDI::RtMidi::FFI::TestUtils;

plan skip_all => "Sanity check failed" unless sanity_check;

my ( $in, $out ) = ( newdevice( 'in' ), newdevice() );
isa_ok( $_, 'MIDI::RtMidi::FFI::Device' ) for ( $in, $out );

my @events = (
    [ note_on => 0x00, 0x40, 0x7f ],
    [ note_off => 0x01, 0x40, 0 ],
    [ pitch_wheel_change => 0x02, 0x1f40 ],
    [ control_change => 0x0f, 0x01, 0x5f ],
    [ key_after_touch => 0x00, 0x40, 0x5f ],
    [ sysex_f0 => "Hello, world!" ],
);

subtest event => sub {
    plan skip_all => 'Cannot open virtual ports on this platform' if no_virtual;

    connect_devices( $in, $out );

    no_growth {
        $out->send_message_encoded( note_on => 0x00, 0x40, 0x5a );
        $in->get_message;
    } 'Sending messages does not grow memory';

    $in->set_callback( sub {} );

    no_growth {
        $out->send_message_encoded( note_on => 0x00, 0x40, 0x5a );
        usleep 200;
    } ( calls => 1000 ), 'Callback msgs do not grow memory';
};

done_testing;


