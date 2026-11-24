#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Texttospeech::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Texttospeech::V1::TextToSpeechClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Texttospeech::V1::TextToSpeechLongAudioSynthesizeClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Texttospeech::V1 $Google::Cloud::Texttospeech::V1::VERSION, Perl $], $^X" );
