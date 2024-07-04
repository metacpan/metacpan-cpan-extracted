use strict;
use warnings;

use Test2::V0;
use Test::Lib;
use Time::HiRes qw/ usleep time /;

use MIDI::RtMidi::FFI::Device;
use MIDI::RtMidi::FFI::TestUtils;

plan skip_all => "Sanity check failed" unless sanity_check;
plan skip_all => 'Cannot open virtual ports on this platform' if no_virtual;

my ( $in, $out ) = ( RtMidiIn->new, RtMidiOut->new );
connect_devices( $in, $out );

$out->open_rpn( 0x01, 0x00, 0x01 );
$out->open_nrpn( 0x01, 0x00, 0x01 );
$out->open_rpn( 0x01, 0x00, 0x01 );

# The above calls should result in this sequence of messages:
my $tests = [
    {
        out => [],
        in  => [ [ 0x01, 101, 0x7F ], [ 0x01, 100, 0x7F ],
                 [ 0x01, 101, 0x00 ], [ 0x01, 100, 0x01 ],
                 [ 0x01, 101, 0x7F ], [ 0x01, 100, 0x7F ],
                 [ 0x01, 99,  0x00 ], [ 0x01, 98,  0x01 ],
                 [ 0x01, 101, 0x7F ], [ 0x01, 100, 0x7F ],
                 [ 0x01, 101, 0x00 ], [ 0x01, 100, 0x01 ] ],
    }
];
test_cc( $in, $out, $tests );

$out->cc( 0x01, 0x06, 0x1337 );

$tests = [
    {   # No 14 bit mode set for RPN - only LSB should be recvd
        # - This is not reliable or well defined behaviour
        #   Unexpected bytes > 0x7F may be interpreted as
        #   unwanted messages! Set your modes correctly
        out => [],
        in  => [ [ 0x01, 0x06, 0x37 ] ],
    }
];

$out->set_rpn_14bit_mode( 'midi' );

$tests = [
    {   # No 14 bit mode set for RPN - only LSB should be recvd
        out => [],
        in  => [ [ 0x01, 0x06, 0x37 ] ],
    }
];
test_cc( $in, $out, $tests );

$out->set_rpn_14bit_mode( 'midi' );
$out->cc( 0x01, 0x07, 0x1337 );
$out->cc( 0x01, 0x06, 0x1337 );

$tests = [
    {   # No CC 14 bit mode set, RPN should be 14 bit
        out => [],
        in  => [ [ 0x01, 0x07, 0x37 ],
                 [ 0x01, 0x06, 0x26 ], [ 0x01, 0x06 | 0x20, 0x37 ] ],
    }
];
test_cc( $in, $out, $tests );

$out->open_nrpn( 0x01, 0x03, 0x05 );
$tests = [
    {
        out => [],
        in  => [ [ 0x01, 101, 0x7F ], [ 0x01, 100, 0x7F ],
                 [ 0x01, 99,  0x03 ], [ 0x01, 98,  0x05 ] ]
    }
];
test_cc( $in, $out, $tests );

$out->set_nrpn_14bit_mode( 'midi' );
$out->set_14bit_mode( 'backwards' );

$out->cc( 0x01, 0x07, 0x1337 );
$out->cc( 0x01, 0x06, 0x1337 );
$out->cc( 0x01, 0x7F, 0x1337 );
$tests = [
    {   # All CCs < 32 should be 14 bit, though with different modes
        out => [],
        in  => [ [ 0x01, 0x07 | 0x20, 0x37 ], [ 0x01, 0x07, 0x26 ],
                 [ 0x01, 0x06, 0x26 ], [ 0x01, 0x06 | 0x20, 0x37 ],
                 [ 0x01, 0x7F, 0x37 ] ],
    }
];
test_cc( $in, $out, $tests );

$out->close_nrpn( 0x01 );

$out->cc( 0x01, 0x07, 0x1337 );
$out->cc( 0x01, 0x06, 0x1337 );
$out->cc( 0x01, 0x7F, 0x1337 );
$tests = [
    {   # All CCs < 32 should be handled by global 14 bit mode 'backwards'
        out => [],
        in  => [ [ 0x01, 101, 0x7F ], [ 0x01, 100, 0x7F ],
                 [ 0x01, 0x07 | 0x20, 0x37 ], [ 0x01, 0x07, 0x26 ],
                 [ 0x01, 0x06 | 0x20, 0x37 ], [ 0x01, 0x06, 0x26 ],
                 [ 0x01, 0x7F, 0x37 ] ],
    }
];
test_cc( $in, $out, $tests );

$out->disable_rpn_14bit_mode;
$out->set_14bit_mode('midi');

$out->rpn( 0x05, 0x02, 0x03, 0x3F );

$tests = [
    {   # A complete 7 bit RPN transaction
        out => [],
        in  => [ [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ],
                 [ 0x05, 101, 0x02 ], [ 0x05, 100, 0x03 ],
                 [ 0x05, 0x06, 0x3F ],
                 [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ] ]
    }
];
test_cc( $in, $out, $tests );

$out->set_rpn_14bit_mode( 'midi' );
$out->rpn( 0x05, 0x02, 0x03, 0x3FFF );

$tests = [
    {   # A complete 14 bit RPN transaction
        out => [],
        in  => [ [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ],
                 [ 0x05, 101, 0x02 ], [ 0x05, 100, 0x03 ],
                 [ 0x05, 0x06, 0x3FFF >> 7 ], [ 0x05, 0x06 | 0x20, 0x3FFF & 0x7F ],
                 [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ] ]
    }
];
test_cc( $in, $out, $tests );

$out->disable_nrpn_14bit_mode;

$out->nrpn( 0x05, 0x02, 0x03, 0x3F );

$tests = [
    {   # A complete 7 bit NRPN transaction
        out => [],
        in  => [ [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ],
                 [ 0x05, 99,  0x02 ], [ 0x05, 98,  0x03 ],
                 [ 0x05, 0x06, 0x3F ],
                 [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ] ]
    }
];
test_cc( $in, $out, $tests );

$out->set_nrpn_14bit_mode( 'midi' );
$out->nrpn( 0x05, 0x02, 0x03, 0x3FFF );

$tests = [
    {   # A complete 14 bit NRPN transaction
        out => [],
        in  => [ [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ],
                 [ 0x05, 99,  0x02 ], [ 0x05, 98,  0x03 ],
                 [ 0x05, 0x06, 0x3FFF >> 7 ], [ 0x05, 0x06 | 0x20, 0x3FFF & 0x7F ],
                 [ 0x05, 101, 0x7F ], [ 0x05, 100, 0x7F ] ]
    }
];
test_cc( $in, $out, $tests );

done_testing;
