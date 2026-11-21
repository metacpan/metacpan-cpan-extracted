use strict;
use warnings;

# This doesn't test whether panic actually works, just that messages
# were sent/received.

use Test2::V0;
use Test::Lib;
use MIDI::RtMidi::FFI::TestUtils;
use MIDI::RtMidi::FFI::Device;
use Time::HiRes qw/ usleep gettimeofday tv_interval /;

plan skip_all => "Sanity check failed" unless sanity_check;

my $out = RtMidiOut->new;
my $in = RtMidiIn->new( bufsize => 4096 );

connect_devices( $in, $out );


sub count_received {
    my ( $expect, $timeout, $filter ) = @_;
    my $received = 0;
    my $t = [ gettimeofday ];
    while ( $received < $expect ) {
        die "Messages did not arrive in good time $received"
            if ( tv_interval( $t ) > $timeout );
        next unless my $event = $in->get_message_decoded;
        next unless $filter->( $event );
        $received++;
        usleep 200;
    }
    is( $received, $expect, "Received $expect" );
}

$out->panic( 5 );
count_received( 1, .1, sub { shift->[2] == 123 } );

$out->panic;
count_received( 16, .1, sub { shift->[2] == 123 } );

$out->PANIC( 5 );
count_received( 128, .3, sub { shift->[0] eq 'note_off' } );

goto DONE unless $ENV{ RTMIDI_FULL_PANIC_TEST };
$out->PANIC;
count_received( 128 * 16, 5, sub { shift->[0] eq 'note_off' } );

DONE:
done_testing;
