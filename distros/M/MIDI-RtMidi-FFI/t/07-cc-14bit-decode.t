use strict;
use warnings;

use Test2::V0;
use List::Util qw/ pairs /;

use MIDI::RtMidi::FFI::Device;
my $dev = RtMidiOut->new( api_name => 'dummy' );
$dev->_init_timestamp;

sub do_tests {
    my $tests = shift;
    my $mode = $dev->get_14bit_mode // 'disabled';
    my $num = 0;
    for my $test( pairs @{ $tests } ) {
        my @msg  = @{ $test->key };
        my $res  = $test->value;
        my $decoded = $dev->decode_message( scalar $dev->encode_message( @msg ) );
        my $value = ref $res eq 'ARRAY'
            ? $res->[-1]
            : 0;
        is(
            $decoded,
            $res,
            sprintf( "mode %s test %d: decoded 0x%X", $mode, ++$num, $value )
        );
    }
}

sub check_purged {
    ok ! $dev->{ last_event }->{ control_change }, 'CCs purged';
}

$dev->set_14bit_mode( 'midi' );
check_purged;
my $tests = [
    [ control_change => 0x01, 0x06, 0x7F ], undef,
    [ control_change => 0x01, 0x06, 0x26 ], [ control_change => 0x01, 0x06, 0x1300 ],
    [ control_change => 0x01, 0x26, 0x37 ], [ control_change => 0x01, 0x06, 0x1337 ],
    [ control_change => 0x01, 0x06, 0x27 ], [ control_change => 0x01, 0x06, 0x1380 ],
    [ control_change => 0x01, 0x26, 0x37 ], [ control_change => 0x01, 0x06, 0x13B7 ],
    [ control_change => 0x01, 0x26, 0x36 ], [ control_change => 0x01, 0x06, 0x13B6 ],
];
do_tests( $tests );

$dev->set_14bit_mode( 'await' );
check_purged;
$tests = [
    [ control_change => 0x02, 0x06, 0x03 ], undef,
    [ control_change => 0x02, 0x06, 0x57 ], undef,
    [ control_change => 0x02, 0x26, 0x2D ], [ control_change => 0x02, 0x06, 0x2BAD ],
    [ control_change => 0x02, 0x06, 0x77 ], undef,
    [ control_change => 0x02, 0x26, 0x2D ], [ control_change => 0x02, 0x06, 0x3BAD ],
    [ control_change => 0x02, 0x26, 0x2E ], [ control_change => 0x02, 0x06, 0x3BAE ],
];
do_tests( $tests );

$dev->set_14bit_mode( 'backwards' );
check_purged;
$tests = [
    [ control_change => 0x02, 0x28, 0x03 ], undef,
    [ control_change => 0x02, 0x28, 0x6F ], undef,
    [ control_change => 0x02, 0x08, 0x7B ], [ control_change => 0x02, 0x08, 0x3DEF ],
    [ control_change => 0x02, 0x28, 0x03 ], undef,
    [ control_change => 0x02, 0x28, 0x70 ], undef,
    [ control_change => 0x02, 0x08, 0x7C ], [ control_change => 0x02, 0x08, 0x3E70 ],
];
do_tests( $tests );


$dev->set_14bit_mode( 'backwait' );
check_purged;
$tests = [
    [ control_change => 0x02, 0x28, 0x6F ], undef,
    [ control_change => 0x02, 0x08, 0x7B ], [ control_change => 0x02, 0x08, 0x3DEF ],
    # Oops, skipped some fine control ...
    [ control_change => 0x02, 0x28, 0x03 ], undef,
    [ control_change => 0x02, 0x28, 0x23 ], [ control_change => 0x02, 0x08, 0x3DA3 ],
    [ control_change => 0x02, 0x28, 0x5F ], [ control_change => 0x02, 0x08, 0x3DDF ],
    [ control_change => 0x02, 0x28, 0x70 ], [ control_change => 0x02, 0x08, 0x3DF0 ],
    # Real LSB/MSB pair
    [ control_change => 0x02, 0x28, 0x03 ], undef,
    [ control_change => 0x02, 0x08, 0x7C ], [ control_change => 0x02, 0x08, 0x3E03 ],
    # ...with fine control
    [ control_change => 0x02, 0x28, 0x1A ], [ control_change => 0x02, 0x08, 0x3E1A ],
];
do_tests( $tests );

$dev->set_14bit_mode( 'doubleback' );
check_purged;
$tests = [
    [ control_change => 0x0F, 0x3F, 0x21 ], undef,
    [ control_change => 0x0F, 0x1F, 0x5D ], [ control_change => 0x0F, 0x1F, 0x10DD ],
    [ control_change => 0x0F, 0x1F, 0x5E ], [ control_change => 0x0F, 0x1F, 0x10DE ],
    [ control_change => 0x0F, 0x3F, 0x22 ], undef,
    [ control_change => 0x0F, 0x1F, 0x5D ], [ control_change => 0x0F, 0x1F, 0x115D ],
    [ control_change => 0x0F, 0x1F, 0x5E ], [ control_change => 0x0F, 0x1F, 0x115E ],
];
do_tests( $tests );

$dev->set_14bit_mode( 'bassack' );
check_purged;
$tests = [
    [ control_change => 0x0F, 0x3F, 0x75 ], undef,
    [ control_change => 0x0F, 0x1F, 0x44 ], undef,
    [ control_change => 0x0F, 0x3F, 0x75 ], [ control_change => 0x0F, 0x1F, 0x3AC4],
    [ control_change => 0x0F, 0x1F, 0x45 ], undef,
    [ control_change => 0x0F, 0x3F, 0x75 ], [ control_change => 0x0F, 0x1F, 0x3AC5],
    [ control_change => 0x0F, 0x3F, 0x01 ], [ control_change => 0x0F, 0x1F, 0x00C5],
];
do_tests( $tests );

# Check high CCs not effected by 14 bit decoding
$tests = [
    [ control_change => 0x0F, 0x40, 0x7F ], [ control_change => 0x0F, 0x40, 0x7F ],
    [ control_change => 0x0F, 0x40, 0x7E ], [ control_change => 0x0F, 0x40, 0x7E ],
    [ control_change => 0x0F, 0x41, 0x03 ], [ control_change => 0x0F, 0x41, 0x03 ],
    [ control_change => 0x0F, 0x61, 0x7F ], [ control_change => 0x0F, 0x61, 0x7F ],
    [ control_change => 0x0F, 0x41, 0x03 ], [ control_change => 0x0F, 0x41, 0x03 ],
    [ control_change => 0x0F, 0x7F, 0x00 ], [ control_change => 0x0F, 0x7F, 0x00 ],
];
do_tests( $tests );

# Check custom callback
my $callback = sub {
    my ( $device, $channel, $controller, $value ) = @_;
    my $method = $device->resolve_cc_decoder( 'await' );

    # Pass MSB through;
    return $device->$method( $channel, $controller, $value ) if $controller < 32;

    my $last_msb = $device->get_last( control_change => $channel, $controller - 32 );
    # If we start low, we never get a MSB
    my $last_msb_value = $last_msb->{ val } // 0;

    # Pass LSB through if we are not at the low end of the dial
    return $device->$method( $channel, $controller, $value ) if $last_msb_value > 3; # magic number

    # Explicitly set a MSB of 0 if there has been a large jump in LSB
    my $last_lsb = $device->get_last( control_change => $channel, $controller );
    my $diff = abs( $last_lsb->{ val } - $value );
    $device->set_last( control_change => $channel, $controller - 32, 0 ) if $diff > 100;

    # Finally, process the value
    $device->$method( $channel, $controller, $value );
};

$dev->set_14bit_callback( $callback );

$tests = [
    # Repeat 'await' tests
    [ control_change => 0x02, 0x06, 0x03 ], undef,
    [ control_change => 0x02, 0x06, 0x57 ], undef,
    [ control_change => 0x02, 0x26, 0x2D ], [ control_change => 0x02, 0x06, 0x2BAD ],
    [ control_change => 0x02, 0x06, 0x77 ], undef,
    [ control_change => 0x02, 0x26, 0x2D ], [ control_change => 0x02, 0x06, 0x3BAD ],
    [ control_change => 0x02, 0x26, 0x2E ], [ control_change => 0x02, 0x06, 0x3BAE ],

    # Some LSB adjustments
    [ control_change => 0x02, 0x06, 0x03 ], undef,
    [ control_change => 0x02, 0x26, 0x77 ], [ control_change => 0x02, 0x06, 0x01F7 ],
    [ control_change => 0x02, 0x26, 0x7F ], [ control_change => 0x02, 0x06, 0x01FF ],

    # Oops! Large LSB jump without MSB ... zero MSB
    [ control_change => 0x02, 0x26, 0x0A ], [ control_change => 0x02, 0x06, 0x000A ],
    [ control_change => 0x02, 0x26, 0x1A ], [ control_change => 0x02, 0x06, 0x001A ],
];
do_tests( $tests );

my $last = $dev->get_last( control_change => 0x02, 0x06 );
ok $last, "MSB set for 0x02, 0x06";
is $last->{ val }, 0, "MSB 0 set after LSB jump";


# Check low CCs are no longer processed
$dev->disable_14bit_mode;
check_purged;

$tests = [
    [ control_change => 0x02, 0x06, 0x03 ], [ control_change => 0x02, 0x06, 0x03 ],
    [ control_change => 0x02, 0x06, 0x57 ], [ control_change => 0x02, 0x06, 0x57 ],
    [ control_change => 0x02, 0x26, 0x2D ], [ control_change => 0x02, 0x26, 0x2D ],
    [ control_change => 0x02, 0x06, 0x77 ], [ control_change => 0x02, 0x06, 0x77 ],
    [ control_change => 0x02, 0x26, 0x2D ], [ control_change => 0x02, 0x26, 0x2D ],
    [ control_change => 0x02, 0x26, 0x2E ], [ control_change => 0x02, 0x26, 0x2E ],
];
do_tests( $tests );

undef $dev;

done_testing;
