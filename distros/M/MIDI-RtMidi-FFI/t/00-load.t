use Test::More;

my @requires = ( qw/ MIDI::RtMidi::FFI MIDI::RtMidi::FFI::Device / );

for my $require ( @requires ) {
    require_ok $require or BAIL_OUT "Can't load $require - is librtmidi installed?";
}

done_testing
