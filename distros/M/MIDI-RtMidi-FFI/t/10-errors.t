use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use MIDI::RtMidi::FFI::Device;
use MIDI::RtMidi::FFI::TestUtils;

my $dev = RtMidiOut->new;

ok( dies { $dev->open_port( $dev->get_port_count, 'foo' ) } );

subtest event => sub {
    plan skip_all => 'Test is for Windows only' if ! no_virtual;
    ok( dies { $dev->open_virtual_port( 'foo' ) } );
};

done_testing;
