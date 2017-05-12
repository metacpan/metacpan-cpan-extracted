package GSM::SMS::OTA::RTTTL;

# Author: Johan Van den Brande <johan@vandenbrande.com>

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( OTARTTTL_makestream
              OTARTTTL_check
              OTARTTTL_PORT );

$VERSION = '0.1';

use strict;
use constant OTARTTTL_PORT => 5505;

# Parse defaults
use constant RTTTL_DEF_DURATION => 4;
use constant RTTTL_DEF_SCALE    => 6;
use constant RTTTL_DEF_BPM      => 63;
use constant RTTTL_DEF_LOOP		=> "0000";

# Bit string constants

# Command-Part encoding
use constant RTTTL_CANCEL_COMMAND              => "0000101";
use constant RTTTL_RINGING_TONE_PROGRAMMING    => "0100101";
use constant RTTTL_SOUND                       => "0011101";
use constant RTTTL_UNICODE                     => "0100010";
use constant RTTTL_COMMAND_END                 => "00000000";

# Song Type Encoding
use constant RTTTL_BASIC_SONG_TYPE             => "001";
use constant RTTTL_TEMPORARY_SONG_TYPE         => "010";
use constant RTTTL_MIDI_SONG_TYPE              => "011";
use constant RTTTL_DIGITIZED_SONG_TYPE         => "100";

# Pattern ID encoding
use constant RTTTL_A_PART      => "00";
use constant RTTTL_B_PART      => "01";
use constant RTTTL_C_PART      => "10";
use constant RTTTL_D_PART      => "11";

# Instruction ID Encoding
use constant RTTTL_PATTERN_HEADER_ID           => "000";
use constant RTTTL_NOTE_INSTRUCTION_ID         => "001";
use constant RTTTL_SCALE_INSTRUCTION_ID        => "010";
use constant RTTTL_STYLE_INSTRUCTION_ID        => "011";
use constant RTTTL_TEMPO_INSTRUCTION_ID        => "100";
use constant RTTTL_VOLUME_INSTRUCTION_ID       => "101";

# Note Value encoding
use constant RTTTL_PAUSE    => "0000";

use constant RTTTL_C        => "0001";

use constant RTTTL_Cis      => "0010";
use constant RTTTL_Des      => "0010";

use constant RTTTL_D        => "0011";

use constant RTTTL_Dis      => "0100";
use constant RTTTL_Es       => "0100";

use constant RTTTL_E        => "0101";

use constant RTTTL_F        => "0110";

use constant RTTTL_Fis      => "0111";
use constant RTTTL_Ges      => "0111";

use constant RTTTL_G        => "1000";

use constant RTTTL_Gis      => "1001";
use constant RTTTL_As       => "1001";

use constant RTTTL_A        => "1010";

use constant RTTTL_Ais      => "1011";
use constant RTTTL_B        => "1100";

use constant RTTTL_H        => "1100";

# Note duration encoding
use constant RTTTL_FULL        => "000";
use constant RTTTL_12          => "001";
use constant RTTTL_14          => "010";
use constant RTTTL_18          => "011";
use constant RTTTL_116         => "100";
use constant RTTTL_132         => "101";

# Note duration specifier
use constant RTTTL_NO_SPECIAL_DURATION => "00";
use constant RTTTL_DOTTED_NOTE         => "01";
use constant RTTTL_DOUBLEDOTTED_NOTE   => "10";
use constant RTTTL_23_LENGTH           => "11";

# Note scale encoding
use constant RTTTL_SCALE_1     => "00";
use constant RTTTL_SCALE_2     => "01";
use constant RTTTL_SCALE_3     => "10";
use constant RTTTL_SCALE_4     => "11";

# Style-value encoding
use constant RTTTL_NATURAL_STYLE       => "00";
use constant RTTTL_CONTINUOUS_STYLE    => "01";
use constant RTTTL_STACCATO_STYLE      => "10";

# Beats per minute
use constant RTTTL_BPM_25      => "00000";
use constant RTTTL_BPM_28      => "00001";
use constant RTTTL_BPM_31      => "00010";
use constant RTTTL_BPM_35      => "00011";
use constant RTTTL_BPM_40      => "00100";
use constant RTTTL_BPM_45      => "00101";
use constant RTTTL_BPM_50      => "00110";
use constant RTTTL_BPM_56      => "00111";
use constant RTTTL_BPM_63      => "01000";
use constant RTTTL_BPM_70      => "01001";
use constant RTTTL_BPM_80      => "01010";
use constant RTTTL_BPM_90      => "01011";
use constant RTTTL_BPM_100     => "01100";
use constant RTTTL_BPM_112     => "01101";
use constant RTTTL_BPM_125     => "01110";
use constant RTTTL_BPM_140     => "01111";
use constant RTTTL_BPM_160     => "10000";
use constant RTTTL_BPM_180     => "10001";
use constant RTTTL_BPM_200     => "10010";
use constant RTTTL_BPM_225     => "10011";
use constant RTTTL_BPM_250     => "10100";
use constant RTTTL_BPM_285     => "10101";
use constant RTTTL_BPM_320     => "10110";
use constant RTTTL_BPM_355     => "10111";
use constant RTTTL_BPM_400     => "11000";
use constant RTTTL_BPM_450     => "11001";
use constant RTTTL_BPM_500     => "11010";
use constant RTTTL_BPM_565     => "11011";
use constant RTTTL_BPM_635     => "11100";
use constant RTTTL_BPM_715     => "11101";
use constant RTTTL_BPM_800     => "11110";
use constant RTTTL_BPM_900     => "11111";

# Volume encoding
use constant RTTTL_LEVEL_0     => "0000";
use constant RTTTL_LEVEL_1     => "0001";
use constant RTTTL_LEVEL_2     => "0010";
use constant RTTTL_LEVEL_3     => "0011";
use constant RTTTL_LEVEL_4     => "0100";
use constant RTTTL_LEVEL_5     => "0101";
use constant RTTTL_LEVEL_6     => "0110";
use constant RTTTL_LEVEL_7     => "0111";
use constant RTTTL_LEVEL_8     => "1000";
use constant RTTTL_LEVEL_9     => "1001";
use constant RTTTL_LEVEL_10    => "1010";
use constant RTTTL_LEVEL_11    => "1011";
use constant RTTTL_LEVEL_12    => "1100";
use constant RTTTL_LEVEL_13    => "1101";
use constant RTTTL_LEVEL_14    => "1110";
use constant RTTTL_LEVEL_15    => "1111";

# hash constants

use constant RTTTL_TO_NOKIA_DURATIONS =>
 {
  "1"       =>      RTTTL_FULL,
  "2"       =>      RTTTL_12,
  "4"       =>      RTTTL_14,
  "8"       =>      RTTTL_18,
  "16"      =>      RTTTL_116,
  "32"      =>      RTTTL_132
 };

use constant RTTTL_TO_NOKIA_NOTES =>
 {
  "P"     =>  RTTTL_PAUSE,
  "C"     =>  RTTTL_C,
  "C#"    =>  RTTTL_Cis,
  "D"     =>  RTTTL_D,
  "D#"    =>  RTTTL_Dis,
  "E"     =>  RTTTL_E,
  "F"     =>  RTTTL_F,
  "F#"    =>  RTTTL_Fis,
  "G"     =>  RTTTL_G,
  "G#"    =>  RTTTL_Gis,
  "A"     =>  RTTTL_A,
  "A#"    =>  RTTTL_Ais,
  "B"     =>  RTTTL_B,
  "H"     =>  RTTTL_H
 };

use constant RTTTL_TO_NOKIA_TEMPOS =>
 {
  "25"  => RTTTL_BPM_25,
  "28"  => RTTTL_BPM_28,
  "31"  => RTTTL_BPM_31,
  "35"  => RTTTL_BPM_35,
  "40"  => RTTTL_BPM_40,
  "45"  => RTTTL_BPM_45,
  "50"  => RTTTL_BPM_50,
  "56"  => RTTTL_BPM_56,
  "63"  => RTTTL_BPM_63,
  "70"  => RTTTL_BPM_70,
  "80"  => RTTTL_BPM_80,
  "90"  => RTTTL_BPM_90,
  "100" => RTTTL_BPM_100,
  "112" => RTTTL_BPM_112,
  "125" => RTTTL_BPM_125,
  "140" => RTTTL_BPM_140,
  "160" => RTTTL_BPM_160,
  "180" => RTTTL_BPM_180,
  "200" => RTTTL_BPM_200,
  "225" => RTTTL_BPM_225,
  "250" => RTTTL_BPM_250,
  "285" => RTTTL_BPM_285,
  "320" => RTTTL_BPM_320,
  "355" => RTTTL_BPM_355,
  "400" => RTTTL_BPM_400,
  "450" => RTTTL_BPM_450,
  "500" => RTTTL_BPM_500,
  "565" => RTTTL_BPM_565,
  "635" => RTTTL_BPM_635,
  "715" => RTTTL_BPM_715,
  "800" => RTTTL_BPM_800,
  "900" => RTTTL_BPM_900
 };

use constant RTTTL_TO_NOKIA_SCALES =>
{
 "4" => RTTTL_SCALE_1,
 "5" => RTTTL_SCALE_2,
 "6" => RTTTL_SCALE_3,
 "7" => RTTTL_SCALE_4
};


sub OTARTTTL_check {
    my ($rt) = @_;

    my ($name, $defaults, $notes) = split /:/, $rt;

    unless ( $name=~/[a-zA-Z0-9]/ && length($name) < 32 ) {
        return "Error on name\n";
    }

    my %def;
    map { my ($n,$v) = split /=/, $_; $def{$n} = $v; } split /,/, $defaults;

    unless ( $def{"d"} =~ /\d+/ ) {
         return "Error on 'd' default.\n";
    }
    unless ( $def{"o"} =~ /\d+/ ) {
         return "Error on 'o' default.\n";
    }
    unless ( $def{"b"} =~ /\d+/ ) {
         return "Error on 'b' default.\n";
    }
	
	unless ( $def{"l"} =~ /\d*/ ) {
	 	return "Error on 'l' default.\n";
	}
    
	$notes = _correct_dotted_durations( $notes );

     my @notes = split /,/, $notes;
     my $cnt = 1;
     foreach my $note ( @notes ) {

         my ( $d, $n, $s, $x  ) = ( $note =~ /(\d*)([a-z]#?)(\d*)(\.?)/ );

         unless ( $n ) {
             return "Error: no note in '$note' ($cnt)\n";
         }

         unless ( $d =~ /\d*/ ) {
             return "Error on duration in note '$note' ($cnt)\n";
         }

         unless ( $n =~ /([a-g]|p)#?/ ) {
             return "Error on note in note '$note' ($cnt)\n";
         }

         unless ( $s =~ /\d*/ ) {
             return "Error on scale in note '$note' ($cnt)\n";
         }

         unless ( $x =~ /\.?/ ) {
             return "Error on dot in note '$note' ($cnt)\n";
         }
         $cnt++;
     }
     return;
 }

 sub OTARTTTL_makestream {
     my ($rtttl) = @_;

     # Split into <name>:<defaults>:<notecommands>
     my ($name, $defaults, $notes) = split /:/, $rtttl;

     # there seem to be two 'rtttls' around: those where
     # the scale precedes the dot, and vice versa.
     # we use the former, because that's what the specs seem to say
     $notes = _correct_dotted_durations( $notes );

     my $default_duration = ($defaults=~/d=(\d+)/ && $1) || RTTTL_DEF_DURATION;
     my $default_scale    = ($defaults=~/o=(\d+)/ && $1) || RTTTL_DEF_SCALE;
     my $default_bpm      = ($defaults=~/b=(\d+)/ && $1) || RTTTL_DEF_BPM;
	 my $default_loop	  = ($defaults=~/l=(\d+)/ && $1) || RTTTL_DEF_LOOP;

     my $bitstream;

     # Songtitle
     $bitstream .= encodeSongTitle($name);

     # how many sequences? 
     $bitstream .= "00000001";

     $bitstream .= _encode_pattern_header( $default_loop );

     my($nstream,$count) = _encode_notes($notes, $default_duration,
                                         $default_scale, $default_bpm);

     $bitstream =~ s/X/dec2bin($count, 8)/e;

     $bitstream = "00000010" . 
         padBits(RTTTL_RINGING_TONE_PROGRAMMING,8) . 
             padBits(RTTTL_SOUND . RTTTL_BASIC_SONG_TYPE  . $bitstream . $nstream, 8) . 
                 RTTTL_COMMAND_END;

     my $music = bitstreamToHex($bitstream);
     return $music;
 }

 sub _correct_dotted_durations {
     my $notes = shift;

     $notes =~ s/(\.)(\d)/$2$1/g;
     return $notes;
 }
 sub _encode_notes {
     my ($notes, $default_duration, $default_scale, $default_bpm) = @_;
     my $nstream;

     # these two are both instructions, hence we set the count to 2
     # encode scale
     $nstream = encodeScale($default_scale);

     # encode tempo
     $nstream .= encodeBpm($default_bpm);

     my $count = 2;
     ############################################################

     # Parse notes
     my @notes = split /,\s*/s, $notes;

     my $last_scale = 0;

     foreach my $note (@notes) {

         my ($n_duration, $n_note, $n_scale, $n_special ) = $note =~/(\d*)(\w#?)(\d*)(\.?)/;

         $n_scale ||= $default_scale;

         if ( $n_scale != $last_scale ) {
             $nstream .= encodeScale($n_scale);
             $count++;
         }

         $last_scale = $n_scale;

         $n_duration ||= $default_duration;

         $nstream .= encodeNote($n_duration, $n_note, $n_special); 
         $count++;
     }
     return ($nstream,$count);
 }
 sub _encode_pattern_header {
 	 my ( $loop ) = @_;
     my $ph;
     # encode the pattern ...
     # We only assume pattern A 
     $ph = RTTTL_PATTERN_HEADER_ID . RTTTL_A_PART;
     $ph .= sprintf( "%04d", $loop );
     # length of the new pattern (we do not know that upfront?)
     $ph .= "X";
     return $ph;
 }
 sub encodeSongTitle {
     my ($title) = @_;

     my $bitstream = dec2bin(length($title), 4);
     foreach my $char (split /|/, $title) {
         $bitstream.= dec2bin( ord($char), 8 );
     }
     return $bitstream;
 }
 sub encodeScale {
     my ($scale) = @_;

     my $bs = RTTTL_SCALE_INSTRUCTION_ID;
     $bs .= RTTTL_TO_NOKIA_SCALES->{$scale};
#     print STDERR "setting scale to $scale binary: $bs\n";

     return $bs;
 }
 sub encodeBpm {
     my ($bpm) = @_;

     my $bs = RTTTL_TEMPO_INSTRUCTION_ID;
     $bs .= RTTTL_TO_NOKIA_TEMPOS->{$bpm};
     #     print STDERR "setting tempo to $bpm binary: $bs\n";
     return $bs;
 }

 sub encodeNote {
     my ($d, $n, $dot) = @_;
     my $bs;

     # encode the scale in the for loop, that will make it easier 
     # to "compress" the song 
     $bs= RTTTL_NOTE_INSTRUCTION_ID; 

     my $_dot =  ( $dot eq "." ) ? RTTTL_DOTTED_NOTE : RTTTL_NO_SPECIAL_DURATION;

     $bs .= RTTTL_TO_NOKIA_NOTES->{ uc($n) };
     $bs .= RTTTL_TO_NOKIA_DURATIONS->{$d};
     $bs .=$_dot;
#     print STDERR "setting note as ",uc($n), " binary: note ", RTTTL_TO_NOKIA_NOTES->{ uc($n) },       " duration ", RTTTL_TO_NOKIA_DURATIONS->{$d},  "dot $_dot\n";

     return $bs;
 }
 sub dec2bin {
     my ($d, $l) = @_;
     my $str = substr( unpack("B32", pack("N", $d)), 32-$l, $l);
     return $str;
 }
 sub bitstreamToHex {
     my ($bits) = @_;
     my $hex;

     while (length($bits)) {
         my $run8 = substr($bits, 0, 8);
         $bits = substr($bits, 8, length($bits)-8);
         $run8.="0" x 8-length($run8) if ( length($run8)<8 );
         $hex.=sprintf("%.2X", unpack("N", pack( "B32", substr("0" x 32 . $run8, -32))));
     }
     return $hex;
 }
 sub padBits {
     my ($stream, $len) = @_;
     $stream.= "0" x ( $len - (length($stream) % $len) ); 
     return $stream;
 }

 1;

=head1 NAME

GSM::SMS::OTA::RTTTL - Convert RTTTL composed songs to Nokia Smart Messaging Specs

=head1 SYNOPSIS

use GSM::SMS::OTA::RTTTL;

my $tone = OTARTTTL_makestream("<rtttl string>");
my $port = OTARTTTL_PORT;

=head1  DESCRIPTION

This converts RTTTL strings into a binary format, ready to get send to a mobile
phone. For the moment it assumes:

=over
=item   1 pattern (pattern A)
=item   no loop
=back

=head1 METHODS

=head2 OTARTTTL_makestream

        $stream = OTARTTTL_makestream( $rtttl_string );

Create a RTTTL stream from a RTTTL syntax string.

=head2 OTARTTTL_PORT

NSB Port number for a RTTTL message.

=head1 AUTHORS
Johan Van den Brande <johan@vandenbrande.com>
David Wright <david@hybyte.com> 
