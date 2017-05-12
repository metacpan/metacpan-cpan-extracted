
# Time-stamp: "2010-02-14 21:39:10 conklin"
require 5;
package MIDI;
use strict;
use vars qw($Debug $VERSION %number2note %note2number %number2patch
	    %patch2number %notenum2percussion %percussion2notenum);
use MIDI::Opus;
use MIDI::Track;
use MIDI::Event;
use MIDI::Score;

# Doesn't use MIDI::Simple -- but MIDI::Simple uses this

$Debug = 0; # currently doesn't do anything
$VERSION = '0.83';

# MIDI.pm doesn't do much other than 1) 'use' all the necessary submodules
# 2) provide some publicly useful hashes, 3) house a few private routines
# common to the MIDI::* modules, and 4) contain POD, glorious POD.

=head1 NAME

MIDI - read, compose, modify, and write MIDI files

=head1 SYNOPSIS

 use MIDI;
 use strict;
 use warnings;
 my @events = (
   ['text_event',0, 'MORE COWBELL'],
   ['set_tempo', 0, 450_000], # 1qn = .45 seconds
 );

 for (1 .. 20) {
   push @events,
     ['note_on' , 90,  9, 56, 127],
     ['note_off',  6,  9, 56, 127],
   ;
 }
 foreach my $delay (reverse(1..96)) {
   push @events,
     ['note_on' ,      0,  9, 56, 127],
     ['note_off', $delay,  9, 56, 127],
   ;
 }

 my $cowbell_track = MIDI::Track->new({ 'events' => \@events });
 my $opus = MIDI::Opus->new(
  { 'format' => 0, 'ticks' => 96, 'tracks' => [ $cowbell_track ] } );
 $opus->write_to_file( 'cowbell.mid' );


=head1 DESCRIPTION

This suite of modules provides routines for reading, composing, modifying,
and writing MIDI files.

From FOLDOC (C<http://wombat.doc.ic.ac.uk/foldoc/>):

=over

B<MIDI, Musical Instrument Digital Interface>
                                       
E<lt>multimedia, file formatE<gt> (MIDI /mi'-dee/, /mee'-dee/) A
hardware specification and protocol used to communicate note and
effect information between synthesisers, computers, music keyboards,
controllers and other electronic music devices. [...]

The basic unit of information is a "note on/off" event which includes
a note number (pitch) and key velocity (loudness). There are many
other message types for events such as pitch bend, patch changes and
synthesizer-specific events for loading new patches etc.

There is a file format for expressing MIDI data which is like a dump
of data sent over a MIDI port. [...]

=back

=head1 COMPONENTS

The MIDI-Perl suite consists of these modules:

L<MIDI> (which you're looking at), L<MIDI::Opus>, L<MIDI::Track>, 
L<MIDI::Event>, L<MIDI::Score>, and
L<MIDI::Simple>.  All of these contain documentation in pod format.
You should read all of these pods.

The order you want to read them in will depend on what you want to do
with this suite of modules: if you are focused on manipulating the
guts of existing MIDI files, read the pods in the order given above.

But if you aim to compose music with this suite, read this pod, then
L<MIDI::Score> and L<MIDI::Simple>, and then skim the rest.


=head1 INTRODUCTION

This suite of modules is basically object-oriented, with the exception
of MIDI::Simple.  MIDI opuses ("songs") are represented as objects
belonging to the class MIDI::Opus.  An opus contains tracks, which are
objects belonging to the class MIDI::Track.  A track will generally
contain a list of events, where each event is a list consisting of a
command, a delta-time, and some number of parameters.  In other words,
opuses and tracks are objects, and the events in a track comprise a
LoL (and if you don't know what an LoL is, you must read L<perllol>).

Furthermore, for some purposes it's useful to analyze the totality of
a track's events as a "score" -- where a score consists of notes where
each event is a list consisting of a command, a time offset from the
start of the track, and some number of parameters.  This is the level
of abstraction that MIDI::Score and MIDI::Simple deal with.

While this suite does provide some functionality accessible only if
you're comfortable with various kinds of references, and while there
are some options that deal with the guts of MIDI encoding, you can (I
hope) get along just fine with just a basic grasp of the MIDI
"standard", and a command of LoLs.  I have tried, at various points in
this documentation, to point out what things are not likely to be of
use to the casual user.

=head1 GOODIES

The bare module MIDI.pm doesn't I<do> much more than C<use> the
necessary component submodules (i.e., all except MIDI::Simple).  But
it does provide some hashes you might find useful:

=over

=cut

###########################################################################
# Note numbers => a representation of them

=item C<%MIDI::note2number> and C<%MIDI::number2note>

C<%MIDI::number2note> correponds MIDI note numbers to a more
comprehensible representation (e.g., 68 to 'Gs4', for G-sharp, octave
4); C<%MIDI::note2number> is the reverse.  Have a look at the source
to see the contents of the hash.

=cut
@number2note{0 .. 127} = (
# (Do)        (Re)         (Mi)  (Fa)         (So)         (La)        (Ti)
 'C0', 'Cs0', 'D0', 'Ds0', 'E0', 'F0', 'Fs0', 'G0', 'Gs0', 'A0', 'As0', 'B0',
 'C1', 'Cs1', 'D1', 'Ds1', 'E1', 'F1', 'Fs1', 'G1', 'Gs1', 'A1', 'As1', 'B1',
 'C2', 'Cs2', 'D2', 'Ds2', 'E2', 'F2', 'Fs2', 'G2', 'Gs2', 'A2', 'As2', 'B2',
 'C3', 'Cs3', 'D3', 'Ds3', 'E3', 'F3', 'Fs3', 'G3', 'Gs3', 'A3', 'As3', 'B3',
 'C4', 'Cs4', 'D4', 'Ds4', 'E4', 'F4', 'Fs4', 'G4', 'Gs4', 'A4', 'As4', 'B4',
 'C5', 'Cs5', 'D5', 'Ds5', 'E5', 'F5', 'Fs5', 'G5', 'Gs5', 'A5', 'As5', 'B5',
 'C6', 'Cs6', 'D6', 'Ds6', 'E6', 'F6', 'Fs6', 'G6', 'Gs6', 'A6', 'As6', 'B6',
 'C7', 'Cs7', 'D7', 'Ds7', 'E7', 'F7', 'Fs7', 'G7', 'Gs7', 'A7', 'As7', 'B7',
 'C8', 'Cs8', 'D8', 'Ds8', 'E8', 'F8', 'Fs8', 'G8', 'Gs8', 'A8', 'As8', 'B8',
 'C9', 'Cs9', 'D9', 'Ds9', 'E9', 'F9', 'Fs9', 'G9', 'Gs9', 'A9', 'As9', 'B9',
 'C10','Cs10','D10','Ds10','E10','F10','Fs10','G10',
  # Note number 69 reportedly == A440, under a default tuning.
  # and note 60 = Middle C
);
%note2number = reverse %number2note;
# Note how I deftly avoid having to figure out how to represent a flat mark
#  in ASCII.

###########################################################################
#  ****     TABLE 1  -  General MIDI Instrument Patch Map      ****
# (groups sounds into sixteen families, w/8 instruments in each family)
#  Note that I call the map 0-127, not 1-128.

=item C<%MIDI::patch2number> and C<%MIDI::number2patch>

C<%MIDI::number2patch> correponds General MIDI patch numbers
(0 to 127) to English names (e.g., 79 to 'Ocarina');
C<%MIDI::patch2number> is the reverse.  Have a look at the source
to see the contents of the hash.

=cut
@number2patch{0 .. 127} = (   # The General MIDI map: patches 0 to 127
#0: Piano
 "Acoustic Grand", "Bright Acoustic", "Electric Grand", "Honky-Tonk",
 "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clav",
# Chrom Percussion
 "Celesta", "Glockenspiel", "Music Box", "Vibraphone",
 "Marimba", "Xylophone", "Tubular Bells", "Dulcimer",

#16: Organ
 "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
 "Reed Organ", "Accordion", "Harmonica", "Tango Accordion",
# Guitar
 "Acoustic Guitar(nylon)", "Acoustic Guitar(steel)",
 "Electric Guitar(jazz)", "Electric Guitar(clean)",
 "Electric Guitar(muted)", "Overdriven Guitar",
 "Distortion Guitar", "Guitar Harmonics",

#32: Bass
 "Acoustic Bass", "Electric Bass(finger)",
 "Electric Bass(pick)", "Fretless Bass",
 "Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2",
# Strings
 "Violin", "Viola", "Cello", "Contrabass",
 "Tremolo Strings", "Pizzicato Strings", "Orchestral Strings", "Timpani",

#48: Ensemble
 "String Ensemble 1", "String Ensemble 2", "SynthStrings 1", "SynthStrings 2",
 "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit",
# Brass
 "Trumpet", "Trombone", "Tuba", "Muted Trumpet",
 "French Horn", "Brass Section", "SynthBrass 1", "SynthBrass 2",

#64: Reed
 "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax",
 "Oboe", "English Horn", "Bassoon", "Clarinet",
# Pipe
 "Piccolo", "Flute", "Recorder", "Pan Flute",
 "Blown Bottle", "Skakuhachi", "Whistle", "Ocarina",

#80: Synth Lead
 "Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)", "Lead 4 (chiff)",
 "Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass+lead)",
# Synth Pad
 "Pad 1 (new age)", "Pad 2 (warm)", "Pad 3 (polysynth)", "Pad 4 (choir)",
 "Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)",

#96: Synth Effects
 "FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)",
 "FX 5 (brightness)", "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)",
# Ethnic
 "Sitar", "Banjo", "Shamisen", "Koto",
 "Kalimba", "Bagpipe", "Fiddle", "Shanai",

#112: Percussive
 "Tinkle Bell", "Agogo", "Steel Drums", "Woodblock",
 "Taiko Drum", "Melodic Tom", "Synth Drum", "Reverse Cymbal",
# Sound Effects
 "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet",
 "Telephone Ring", "Helicopter", "Applause", "Gunshot",
);
%patch2number = reverse %number2patch;

###########################################################################
#     ****    TABLE 2  -  General MIDI Percussion Key Map    ****
# (assigns drum sounds to note numbers. MIDI Channel 9 is for percussion)
# (it's channel 10 if you start counting at 1.  But WE start at 0.)

=item C<%MIDI::notenum2percussion> and C<%MIDI::percussion2notenum>

C<%MIDI::notenum2percussion> correponds General MIDI Percussion Keys
to English names (e.g., 56 to 'Cowbell') -- but note that only numbers
35 to 81 (inclusive) are defined; C<%MIDI::percussion2notenum> is the
reverse.  Have a look at the source to see the contents of the hash.

=cut

@notenum2percussion{35 .. 81} = (
 'Acoustic Bass Drum', 'Bass Drum 1', 'Side Stick', 'Acoustic Snare',
 'Hand Clap',

 # the forties 
 'Electric Snare', 'Low Floor Tom', 'Closed Hi-Hat', 'High Floor Tom',
 'Pedal Hi-Hat', 'Low Tom', 'Open Hi-Hat', 'Low-Mid Tom', 'Hi-Mid Tom',
 'Crash Cymbal 1',

 # the fifties
 'High Tom', 'Ride Cymbal 1', 'Chinese Cymbal', 'Ride Bell', 'Tambourine',
 'Splash Cymbal', 'Cowbell', 'Crash Cymbal 2', 'Vibraslap', 'Ride Cymbal 2',

 # the sixties
 'Hi Bongo', 'Low Bongo', 'Mute Hi Conga', 'Open Hi Conga', 'Low Conga',
 'High Timbale', 'Low Timbale', 'High Agogo', 'Low Agogo', 'Cabasa',

 # the seventies
 'Maracas', 'Short Whistle', 'Long Whistle', 'Short Guiro', 'Long Guiro',
 'Claves', 'Hi Wood Block', 'Low Wood Block', 'Mute Cuica', 'Open Cuica',

 # the eighties
 'Mute Triangle', 'Open Triangle',
);
%percussion2notenum = reverse %notenum2percussion;

###########################################################################

=back

=head1 BRIEF GLOSSARY

This glossary defines just a few terms, just enough so you can
(hopefully) make some sense of the documentation for this suite of
modules.  If you're going to do anything serious with these modules,
however, you I<should really> invest in a good book about the MIDI
standard -- see the References.

B<channel>: a logical channel to which control changes and patch
changes apply, and in which MIDI (note-related) events occur.

B<control>: one of the various numeric parameters associated with a
given channel.  Like S registers in Hayes-set modems, MIDI controls
consist of a few well-known registers, and beyond that, it's
patch-specific and/or sequencer-specific.

B<delta-time>: the time (in ticks) that a sequencer should wait
between playing the previous event and playing the current event.

B<meta-event>: any of a mixed bag of events whose common trait is
merely that they are similarly encoded.  Most meta-events apply to all
channels, unlike events, which mostly apply to just one channel.

B<note>: my oversimplistic term for items in a score structure.

B<opus>: the term I prefer for a piece of music, as represented in
MIDI.  Most specs use the term "song", but I think that this
falsely implies that MIDI files represent vocal pieces.

B<patch>: an electronic model of the sound of a given notional
instrument.

B<running status>: a form of modest compression where an event lacking
an event command byte (a "status" byte) is to be interpreted as having
the same event command as the preceding event -- which may, in turn,
lack a status byte and may have to be interpreted as having the same
event command as I<its> previous event, and so on back.

B<score>: a structure of notes like an event structure, but where
notes are represented as single items, and where timing of items is
absolute from the beginning of the track, instead of being represented
in delta-times.

B<song>: what some MIDI specs call a song, I call an opus.

B<sequencer>: a device or program that interprets and acts on MIDI
data.  This prototypically refers to synthesizers or drum machines,
but can also refer to more limited devices, such as mixers or even
lighting control systems.

B<status>: a synonym for "event".

B<sysex>: a chunk of binary data encapsulated in the MIDI data stream,
for whatever purpose.

B<text event>: any of the several meta-events (one of which is
actually called 'text_event') that conveys text.  Most often used to
just label tracks, note the instruments used for a track, or to
provide metainformation about copyright, performer, and piece title
and author.

B<tick>: the timing unit in a MIDI opus.

B<variable-length encoding>: an encoding method identical to what Perl
calls the 'w' (BER, Basic Encoding Rules) pack/unpack format for
integers.

=head1 SEE ALSO

L<http://interglacial.com/~sburke/midi-perl/> -- the MIDI-Perl homepage
on the Interwebs!

L<http://search.cpan.org/search?m=module&q=MIDI&n=100> -- All the MIDI
things in CPAN!

=head1 REFERENCES

Christian Braut.  I<The Musician's Guide to Midi.>  ISBN 0782112854.
[This one is indispensible, but sadly out of print.  Look at abebooks.com
for it maybe --SMB]

Langston, Peter S.  1998. "Little Music Languages", p.587-656 in:
Salus, Peter H,. editor in chief, /Handbook of Programming Languages/,
vol.  3.  MacMillan Technical, 1998.  [The volume it's in is probably
not worth the money, but see if you can at least glance at this
article anyway.  It's not often you see 70 pages written on music
languages. --SMB]

=head1 COPYRIGHT 

Copyright (c) 1998-2005 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHORS

Sean M. Burke C<sburke@cpan.org> (until 2010)

Darrell Conklin C<conklin@cpan.org> (from 2010)
=cut

###########################################################################
sub _dump_quote {
  # Used variously by some MIDI::* modules.  Might as well keep it here.
  my @stuff = @_;
  return
    join(", ",
	map
	 { # the cleaner-upper function
	   if(!length($_)) { # empty string
	     "''";
	   } elsif(
                   $_ eq '0' or m/^-?(?:[1-9]\d*)$/s  # integers

		   # Was just: m/^-?\d+(?:\.\d+)?$/s
                   # but that's over-broad, as let "0123" thru, which is
                   # wrong, since that's octal 0123, == decimal 83.

                   # m/^-?(?:(?:[1-9]\d*)|0)(?:\.\d+)?$/s and $_ ne '-0'
                   # would let thru all well-formed numbers, but also
                   # non-canonical forms of them like 0.3000000.
                   # Better to just stick to integers I think.
	   ) {
	     $_;
	   } elsif( # text with junk in it
	      s<([^\x20\x21\x23\x27-\x3F\x41-\x5B\x5D-\x7E])>
	       <'\\x'.(unpack("H2",$1))>eg
	     ) {
	     "\"$_\"";
	   } else { # text with no junk in it
	     s<'><\\'>g;
	     "\'$_\'";
	   }
	 }
	 @stuff
	);
}
###########################################################################

1;

__END__
