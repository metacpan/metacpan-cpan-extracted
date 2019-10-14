use strict;
use warnings;

use Test::More;
use Time::HiRes qw/ usleep /;

use FindBin;
use lib "$FindBin::RealBin/lib/";

use MIDI::RtMidi::FFI::TestUtils;

my ( $in, $out ) = ( newdevice( 'in' ), newdevice() );
isa_ok( $_, 'MIDI::RtMidi::FFI::Device' ) for ( $in, $out );

my @msgs = ( "\x90\x40\x5A", "\x80\x40\x5A" );
$in->set_callback( sub {
        my ( $timestamp, $msg, $data ) = @_;
        is( $data, 'test data', 'callback data buffer handled' );
        my $msghex = msg2hex( shift @msgs );
        my $inhex = msg2hex( $msg );
        is( $inhex, $msghex, 'callback message order' );
    },
    'test data'
);

subtest callback => sub {
    plan skip_all => 'Cannot open virtual ports on MS-Windows' if $^O eq 'MSWin32';

    connect_devices( $in, $out );

    for ( @msgs ) {
        $out->send_message( $_ );
        usleep 10_000;
    }
};

done_testing;
