use Test2::V0;
use Test::Lib;
use MIDI::Stream::Test;

use experimental qw/ signatures /;

use MIDI::Stream::Decoder;
use MIDI::Stream::Encoder;

my @events = (
    [ control_change => 0xf, 0x3f, 0x7f, 0x3e, 0x20 ],
    [ note_on => 0x2, 0x40, 0x40, 0x43, 0x35 ],
    [ pitch_bend => 0xe, 0x1a2b ],
    { name => 'clock' },
    { name => 'tune_request' },
);

my @midi = MIDI::Stream::Encoder->new->encode_events( @events );

# Simple callback passed in constructor
subtest instance_callback => sub {
    my @tests = (
        [ control_change => 0xf, 0x3f, 0x7f ],
        [ control_change => 0xf, 0x3e, 0x20 ],
        [ note_on => 0x2, 0x40, 0x40 ],
        [ note_on => 0x2, 0x43, 0x35 ],
        [ pitch_bend => 0xe, 0x1a2b ],
        [ 'clock' ],
        [ 'tune_request' ]
    );

    plan scalar @tests;

    MIDI::Stream::Decoder->new(
        callback => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    )->decode( @midi );
};

# Callback for a single event type
subtest single_event_type => sub {
    my @tests = ( [ 'clock' ] );

    plan scalar @tests;

    my $decoder = MIDI::Stream::Decoder->new;
    $decoder->attach_callback(
        clock => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    );
    $decoder->decode( @midi );
};

# Callback for multiple event types
subtest multi_event_type => sub {
    my @tests = (
        [ control_change => 0xf, 0x3f, 0x7f ],
        [ control_change => 0xf, 0x3e, 0x20 ],
        [ pitch_bend => 0xe, 0x1a2b ],
    );

    plan scalar @tests;
    my $decoder = MIDI::Stream::Decoder->new;
    $decoder->attach_callback(
        [ qw/ control_change pitch_bend / ] => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    );
    $decoder->decode( @midi );
};

# Callback for cancelled event type
subtest multi_event_type => sub {
    my @tests = (
        [ control_change => 0xf, 0x3f, 0x7f ],
        [ control_change => 0xf, 0x3e, 0x20 ],
    );

    plan scalar @tests;
    my $decoder = MIDI::Stream::Decoder->new;
    $decoder->attach_callback(
        [ qw/ control_change pitch_bend / ] => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    );
    $decoder->cancel_event_callback('pitch_bend');
    $decoder->decode( @midi );
};

# ->stop stops callbacks for one event type,
# global callback also called
subtest stop_and_type_global => sub {
    my @tests = (
        [ control_change => 0xf, 0x3f, 0x7f ],
        [ control_change => 0xf, 0x3f, 0x7f ],
        [ control_change => 0xf, 0x3e, 0x20 ],
        [ control_change => 0xf, 0x3e, 0x20 ],
        [ note_on => 0x2, 0x40, 0x40 ],
        [ note_on => 0x2, 0x40, 0x40 ],
        [ note_on => 0x2, 0x43, 0x35 ],
        [ note_on => 0x2, 0x43, 0x35 ],
        [ pitch_bend => 0xe, 0x1a2b ],
        [ 'clock' ],
        [ 'tune_request' ]
    );

    plan scalar @tests;

    my $decoder = MIDI::Stream::Decoder->new(
        callback => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    );

    $decoder->attach_callback(
        control_change => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
            $decoder->stop;
        }
     );

     # This callback should no be called (@tests untouched)
     $decoder->attach_callback(
        control_change => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    );

    $decoder->attach_callback(
        note_on => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
     );

    $decoder->decode( @midi );
};

subtest cancel_multi => sub {
    my @tests = (
        [ control_change => 0xf, 0x3f, 0x7f ],
        [ control_change => 0xf, 0x3e, 0x20 ],
        [ note_on => 0x2, 0x40, 0x40 ],
        [ note_on => 0x2, 0x43, 0x35 ],
    );

    my $cb_spec = [ 'control_change', qr/^note/ ];

    plan scalar @tests;

    my $decoder = MIDI::Stream::Decoder->new;

    $decoder->attach_event_callback(
        $cb_spec => sub( $event ) {
            is( $event->as_arrayref, shift @tests );
        }
    );

    $decoder->decode( @midi );

    $decoder->cancel_event_callback( $cb_spec );

    $decoder->decode( @midi );
};

done_testing;
