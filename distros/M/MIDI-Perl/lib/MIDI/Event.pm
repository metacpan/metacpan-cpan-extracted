
# Time-stamp: "2010-12-23 09:59:44 conklin"
require 5.004;        # I need BER working right, among other things.
package MIDI::Event;

use strict;
use vars qw($Debug $VERSION @MIDI_events @Text_events @Nontext_meta_events
	    @Meta_events @All_events
	   );
use Carp;

$Debug = 0;
$VERSION = '0.83';

#First 100 or so lines of this module are straightforward.  The actual
# encoding logic below that is scary, tho.

=head1 NAME

MIDI::Event - MIDI events

=head1 SYNOPSIS

  # Dump a MIDI file's text events
  die "No filename" unless @ARGV;
  use MIDI;  # which "use"s MIDI::Event;
  MIDI::Opus->new( {
     "from_file" => $ARGV[0],
     "exclusive_event_callback" => sub{print "$_[2]\n"},
     "include" => \@MIDI::Event::Text_events
   } ); # These options percolate down to MIDI::Event::decode
  exit;

=head1 DESCRIPTION

Functions and lists to do with MIDI events and MIDI event structures.

An event is a list, like:

  ( 'note_on', 141, 4, 50, 64 )

where the first element is the event name, the second is the
delta-time, and the remainder are further parameters, per the
event-format specifications below.

An I<event structure> is a list of references to such events -- a
"LoL".  If you don't know how to deal with LoLs, you I<must> read
L<perllol>.

=head1 GOODIES

For your use in code (as in the code in the Synopsis), this module
provides a few lists:

=over

=item @MIDI_events

a list of all "MIDI events" AKA voice events -- e.g., 'note_on'

=item @Text_events

a list of all text meta-events -- e.g., 'track_name'

=item @Nontext_meta_events

all other meta-events (plus 'raw_data' and F-series events like
'tune_request').

=item @Meta_events

the combination of Text_events and Nontext_meta_events.

=item @All_events

the combination of all the above lists.

=back

=cut

###########################################################################
# Some public-access lists:

@MIDI_events = qw(
  note_off note_on key_after_touch control_change patch_change
  channel_after_touch pitch_wheel_change set_sequence_number
);
@Text_events = qw(
  text_event copyright_text_event track_name instrument_name lyric
  marker cue_point text_event_08 text_event_09 text_event_0a
  text_event_0b text_event_0c text_event_0d text_event_0e text_event_0f
);
@Nontext_meta_events = qw(
  end_track set_tempo smpte_offset time_signature key_signature
  sequencer_specific raw_meta_event sysex_f0 sysex_f7 song_position
  song_select tune_request raw_data
);
# Actually, 'tune_request', for one, is is F-series event, not a
#  strictly-speaking meta-event
@Meta_events = (@Text_events, @Nontext_meta_events);
@All_events = (@MIDI_events, @Meta_events);

=head1 FUNCTIONS

This module provides three functions of interest, which all act upon
event structures.  As an end user, you probably don't need to use any
of these directly, but note that options you specify for
MIDI::Opus->new with a from_file or from_handle options will percolate
down to these functions; so you should understand the options for the
first two of the below functions.  (The casual user should merely skim
this section.)

=over

=item MIDI::Event::decode( \$data, { ...options... } )

This takes a I<reference> to binary MIDI data and decodes it into a
new event structure (a LoL), a I<reference> to which is returned.
Options are:

=over 16

=item 'include' => LISTREF

I<If specified>, listref is interpreted as a reference to a list of
event names (e.g., 'cue_point' or 'note_off') such that only these
events will be parsed from the binary data provided.  Events whose
names are NOT in this list will be ignored -- i.e., they won't end up
in the event structure, and they won't be each passed to any callbacks
you may have specified.

=item 'exclude' => LISTREF

I<If specified>, listref is interpreted as a reference to a list of
event names (e.g., 'cue_point' or 'note_off') that will NOT be parsed
from the binary stream; they'll be ignored -- i.e., they won't end up
in the event structure, and they won't be passed to any callbacks you
may have specified.  Don't specify both an include and an exclude
list.  And if you specify I<neither>, all events will be decoded --
this is what you probably want most of the time.  I've created this
include/exclude functionality mainly so you can scan a file rather
efficiently for just a few specific event types, e.g., just text
events, or just sysexes.

=item 'no_eot_magic' => 0 or 1

See the description of C<'end_track'>, in "EVENTS", below.

=item 'event_callback' => CODEREF

If defined, the code referred to (whether as C<\&wanted> or as
C<sub { BLOCK }>) is called on every event after it's been parsed into
an event list (and any EOT magic performed), but before it's added to
the event structure.  So if you want to alter the event stream on the
way to the event structure (which counts as deep voodoo), define
'event_callback' and have it modify its C<@_>.

=item 'exclusive_event_callback' => CODEREF

Just like 'event_callback'; but if you specify this, the callback is
called I<instead> of adding the events to the event structure.  (So
the event structure returned by decode() at the end will always be
empty.)  Good for cases like the text dumper in the Synopsis, above.

=back

=item MIDI::Event::encode( \@events, {...options...})

This takes a I<reference> to an event structure (a LoL) and encodes it
as binary data, which it returns a I<reference> to.  Options:

=over 16

=item 'unknown_callback' => CODEREF

If this is specified, it's interpreted as a reference to a subroutine
to be called when an unknown event name (say, 'macro_10' or
something), is seen by encode().  The function is fed all of the event
(its name, delta-time, and whatever parameters); the return value of
this function is added to the encoded data stream -- so if you don't
want to add anything, be sure to return ''.

If no 'unknown_callback' is specified, encode() will C<warn> (well,
C<carp>) of the unknown event.  To merely block that, just set
'unknown_callback' to C<sub{return('')}>

=item 'no_eot_magic' => 0 or 1

Determines whether a track-final 0-length text event is encoded as
a end-track event -- since a track-final 0-length text event probably
started life as an end-track event read in by decode(), above.

=item 'never_add_eot' => 0 or 1

If 1, C<encode()> never ever I<adds> an end-track (EOT) event to the
encoded data generated unless it's I<explicitly> there as an
'end_track' in the given event structure.  You probably don't ever
need this unless you're encoding for I<straight> writing to a MIDI
port, instead of to a file.

=item 'no_running_status' => 0 or 1

If 1, disables MIDI's "running status" compression.  Probably never
necessary unless you need to feed your MIDI data to a strange old
sequencer that doesn't understand running status.

=back

Note: If you're encoding just a single event at a time or less than a
whole trackful in any case, then you probably want something like:

          $data_r = MIDI::Event::encode(
            [
              [ 'note_on', 141, 4, 50, 64 ]
            ],
            { 'never_add_eot' => 1} );

which just encodes that one event I<as> an event structure of one
event -- i.e., an LoL that's just a list of one list.

But note that running status will not always apply when you're
encoding less than a whole trackful at a time, since running status
works only within a LoL encoded all at once.  This'll result in
non-optimally compressed, but still effective, encoding.

=item MIDI::Event::copy_structure()

This takes a I<reference> to an event structure, and returns a
I<reference> to a copy of it.  If you're thinking about using this, you
probably should want to use the more straightforward

          $track2 = $track->copy

instead.  But it's here if you happen to need it.

=back

=cut

###########################################################################
sub dump {
  my @event = ref($_[0]) ? @{ $_[0] } : @_;
  # Works as a method (in theory) or as a normal call
  print( "        [", &MIDI::_dump_quote(@event), "],\n" );
}

sub copy_structure {
  # Takes a REFERENCE to an event structure (a ref to a LoL),
  # and returns a REFERENCE to a copy of that structure.
  my $events_r = $_[0];
  croak
    "\$_[0] ($events_r) isn't a reference for MIDI::Event::copy_structure()!!"
    unless ref($events_r);
  return [  map( [@$_], @$events_r )  ];
}

###########################################################################
# The module code below this line is full of frightening things, all to do
# with the actual encoding and decoding of binary MIDI data.
###########################################################################

sub read_14_bit {
  # Decodes to a value 0 to 16383, as is used for some event encoding
  my($b1, $b2) = unpack("C2", $_[0]);
  return ($b1 | ($b2 << 7));
}

sub write_14_bit {
  # encode a 14 bit quantity, as needed for some events
  return
    pack("C2",
         ($_[0] & 0x7F), # lower 7 bits
         (($_[0] >> 7) & 0x7F), # upper 7 bits
	);
}

###########################################################################
#
# One definite assumption is made here: that "variable-length-encoded"
# quantities MUST NOT exceed 0xFFFFFFF (encoded, "\xFF\xFF\xFF\x7F")
# -- i.e., must not take more than 4 bytes to encode.
#
###

sub decode { # decode track data into an event structure
  # Calling format: a REFERENCE to a big chunka MTrk track data.
  # Returns an (unblessed) REFERENCE to an event structure (a LoL)
  # Note that this is a function call, not a constructor method call.

  # Why a references and not the things themselves?  For efficiency's sake.

  my $data_r = $_[0];
  my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};
  my @events = ();
  unless(ref($data_r) eq 'SCALAR') {
    carp "\$_[0] is not a data reference, in MIDI::Event::decode!";
    return [];
  }

  my %exclude = ();
  if(defined($options_r->{ 'exclude' })) {
    if( ref($options_r->{'exclude'}) eq 'ARRAY' ) {
      @exclude{
        @{ $options_r->{'exclude'} }
      } = undef;
    } else {
      croak
        "parameter for MIDI::Event::decode option 'exclude' must be a listref!"
	if $options_r->{'exclude'};
      # If it's false, carry on silently
    }
  } else {
    # If we get an include (and no exclude), make %exclude a list
    #  of all possible events, /minus/ what include specifies
    if(defined($options_r->{ 'include' })) {
      if( ref($options_r->{'include'}) eq 'ARRAY' ) {
	@exclude{ @All_events } = undef; # rack 'em
	delete @exclude{  # and break 'em
	  @{ $options_r->{'include'} }
	};
      } else {
	croak
        "parameter for decode option 'include' must be a listref!"
	  if $options_r->{'include'};
	# If it's false, carry on silently
      }
    }
  }
  print "Exclusions: ", join(' ', map("<$_>", sort keys %exclude)), "\n"
    if $Debug;

  my $event_callback = undef;
  if(defined($options_r->{ 'event_callback' })) {
    if( ref($options_r->{'event_callback'}) eq 'CODE' ) {
      $event_callback = $options_r->{'event_callback'};
    } else {
      carp "parameter for decode option 'event_callback' is not a coderef!\n";
    }
  }
  my $exclusive_event_callback = undef;
  if(defined($options_r->{ 'exclusive_event_callback' })) {
    if( ref($options_r->{'exclusive_event_callback'}) eq 'CODE' ) {
      $exclusive_event_callback = $options_r->{'exclusive_event_callback'};
    } else {
      carp "parameter for decode option 'exclusive_event_callback' is not a coderef!\n";
    }
  }


  my $Pointer = 0; # points to where I am in the data
  ######################################################################
  if($Debug) {
    if($Debug == 1) {
      print "Track data of ", length($$data_r), " bytes.\n";
    } else {
      print "Track data of ", length($$data_r), " bytes: <", $$data_r ,">\n";
    }
  }

=head1 EVENTS AND THEIR DATA TYPES

=head2 DATA TYPES

Events use these data types:

=over

=item channel = a value 0 to 15

=item note = a value 0 to 127

=item dtime = a value 0 to 268,435,455 (0x0FFFFFFF)

=item velocity = a value 0 to 127

=item channel = a value 0 to 15

=item patch = a value 0 to 127

=item sequence = a value 0 to 65,535 (0xFFFF)

=item text = a string of 0 or more bytes of of ASCII text

=item raw = a string of 0 or more bytes of binary data

=item pitch_wheel = a value -8192 to 8191 (0x1FFF)

=item song_pos = a value 0 to 16,383 (0x3FFF)

=item song_number = a value 0 to 127

=item tempo = microseconds, a value 0 to 16,777,215 (0x00FFFFFF)

=back

For data types not defined above, (e.g., I<sf> and I<mi> for
C<'key_signature'>), consult L<MIDI::Filespec> and/or the source for
C<MIDI::Event.pm>.  And if you don't see it documented, it's probably
because I don't understand it, so you'll have to consult a real MIDI
reference.

=head2 EVENTS

And these are the events:

=over

=cut
  # Things I use variously, below.  They're here just for efficiency's sake,
  # to avoid remying on each iteration.
  my($command, $channel, $parameter, $length, $time, $remainder);

  my $event_code = -1; # used for running status

  my $event_count = 0;
 Event:  # Analyze the event stream.
  while($Pointer + 1 < length($$data_r)) {
    # loop while there's anything to analyze ...
    my $eot = 0; # When 1, the event registrar aborts this loop
    ++$event_count;

    my @E = ();
    # E for events -- this is what we'll feed to the event registrar
    #  way at the end.

    # Slice off the delta time code, and analyze it
      #!# print "Chew-code <", substr($$data_r,$Pointer,4), ">\n";
    ($time, $remainder) = unpack("wa*", substr($$data_r,$Pointer,4));
      #!# print "Delta-time $time using ", 4 - length($remainder), " bytes\n"
      #!#  if $Debug > 1;
    $Pointer +=  4 - length($remainder);
      # We do this strangeness with remainders because we don't know 
      #  how many bytes the w-decoding should move the pointer ahead.

    # Now let's see what we can make of the command
    my $first_byte = ord(substr($$data_r, $Pointer, 1));
      # Whatever parses $first_byte is responsible for moving $Pointer
      #  forward.
      #!#print "Event \# $event_count: $first_byte at track-offset $Pointer\n"
      #!#  if $Debug > 1;

    ######################################################################
    if ($first_byte < 0xF0) { # It's a MIDI event ########################
      if($first_byte >= 0x80) {
	print "Explicit event $first_byte" if $Debug > 2;
        ++$Pointer; # It's an explicit event.
        $event_code = $first_byte;
      } else {
        # It's a running status mofo -- just use last $event_code value
        if($event_code == -1) {
          warn "Uninterpretable use of running status; Aborting track."
            if $Debug;
          last Event;
        }
        # Let the argument-puller-offer move Pointer.
      }
      $command = $event_code & 0xF0;
      $channel = $event_code & 0x0F;

      if ($command == 0xC0 || $command == 0xD0) {
        #  Pull off the 1-byte argument
        $parameter = substr($$data_r, $Pointer, 1);
        ++$Pointer;
      } else { # pull off the 2-byte argument
        $parameter = substr($$data_r, $Pointer, 2);
        $Pointer += 2;
      }

      ###################################################################
      # MIDI events

=item ('note_off', I<dtime>, I<channel>, I<note>, I<velocity>)

=cut 
      if ($command      == 0x80) {
	next if $exclude{'note_off'};
        # for sake of efficiency
        @E = ( 'note_off', $time,
          $channel, unpack('C2', $parameter));

=item ('note_on', I<dtime>, I<channel>, I<note>, I<velocity>)

=cut 
      } elsif ($command == 0x90) {
	next if $exclude{'note_on'};
        @E = ( 'note_on', $time,
          $channel, unpack('C2', $parameter));

=item ('key_after_touch', I<dtime>, I<channel>, I<note>, I<velocity>)

=cut 
      } elsif ($command == 0xA0) {
	next if $exclude{'key_after_touch'};
        @E = ( 'key_after_touch', $time,
          $channel, unpack('C2', $parameter));

=item ('control_change', I<dtime>, I<channel>, I<controller(0-127)>, I<value(0-127)>)

=cut 
      } elsif ($command == 0xB0) {
	next if $exclude{'control_change'};
        @E = ( 'control_change', $time,
          $channel, unpack('C2', $parameter));

=item ('patch_change', I<dtime>, I<channel>, I<patch>)

=cut 
      } elsif ($command == 0xC0) {
	next if $exclude{'patch_change'};
        @E = ( 'patch_change', $time,
          $channel, unpack('C', $parameter));

=item ('channel_after_touch', I<dtime>, I<channel>, I<velocity>)

=cut 
      } elsif ($command == 0xD0) {
	next if $exclude{'channel_after_touch'};
        @E = ('channel_after_touch', $time,
          $channel, unpack('C', $parameter));

=item ('pitch_wheel_change', I<dtime>, I<channel>, I<pitch_wheel>)

=cut 
      } elsif ($command == 0xE0) {
	next if $exclude{'pitch_wheel_change'};
        @E = ('pitch_wheel_change', $time,
          $channel, &read_14_bit($parameter) - 0x2000);
      } else {
        warn  # Should be QUITE impossible!
         "SPORK ERROR M:E:1 in track-offset $Pointer\n";
      }

    ######################################################################
    } elsif($first_byte == 0xFF) { # It's a Meta-Event! ##################
      ($command, $length, $remainder) =
        unpack("xCwa*", substr($$data_r, $Pointer, 6));
      $Pointer += 6 - length($remainder);
        # Move past JUST the length-encoded.

=item ('set_sequence_number', I<dtime>, I<sequence>)

=cut 
      if($command      == 0x00) {
         @E = ('set_sequence_number',
	       $time,
	       unpack('n',
		      substr($$data_r, $Pointer, $length)
		     )
	      );

      # Defined text events ----------------------------------------------

=item ('text_event', I<dtime>, I<text>)

=item ('copyright_text_event', I<dtime>, I<text>)

=item ('track_name', I<dtime>, I<text>)

=item ('instrument_name', I<dtime>, I<text>)

=item ('lyric', I<dtime>, I<text>)

=item ('marker', I<dtime>, I<text>)

=item ('cue_point', I<dtime>, I<text>)

=item ('text_event_08', I<dtime>, I<text>)

=item ('text_event_09', I<dtime>, I<text>)

=item ('text_event_0a', I<dtime>, I<text>)

=item ('text_event_0b', I<dtime>, I<text>)

=item ('text_event_0c', I<dtime>, I<text>)

=item ('text_event_0d', I<dtime>, I<text>)

=item ('text_event_0e', I<dtime>, I<text>)

=item ('text_event_0f', I<dtime>, I<text>)

=cut 
      } elsif($command == 0x01) {
         @E = ('text_event',
           $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x02) {
         @E = ('copyright_text_event',
           $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x03) {
         @E = ('track_name',
           $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x04) {
         @E = ('instrument_name',
           $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x05) {
         @E = ('lyric',
           $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x06) {
         @E = ('marker',
           $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x07) {
         @E = ('cue_point',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData

      # Reserved but apparently unassigned text events --------------------
      } elsif($command == 0x08) {
         @E = ('text_event_08',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x09) {
         @E = ('text_event_09',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x0a) {
         @E = ('text_event_0a',
        $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x0b) {
         @E = ('text_event_0b',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x0c) {
         @E = ('text_event_0c',
            $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x0d) {
         @E = ('text_event_0d',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x0e) {
         @E = ('text_event_0e',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData
      } elsif($command == 0x0f) {
         @E = ('text_event_0f',
          $time, substr($$data_r, $Pointer, $length));  # DTime, TData

      # Now the sticky events ---------------------------------------------

=item ('end_track', I<dtime>)

=cut
      } elsif($command == 0x2F) {
         @E = ('end_track', $time );  # DTime
           # The code for handling this oddly comes LATER, in the
           #  event registrar.

=item ('set_tempo', I<dtime>, I<tempo>)

=cut
      } elsif($command == 0x51) {
         @E = ('set_tempo',
	       $time,
	       unpack("N",
		      "\x00" . substr($$data_r, $Pointer, $length)
		     )
	      );  # DTime, Microseconds

=item ('smpte_offset', I<dtime>, I<hr>, I<mn>, I<se>, I<fr>, I<ff>)

=cut
      } elsif($command == 0x54) {
         @E = ('smpte_offset',
           $time,
	   unpack("C*", # there SHOULD be exactly 5 bytes here
		  substr($$data_r, $Pointer, $length)
		 ));
	 # DTime, HR, MN, SE, FR, FF

=item ('time_signature', I<dtime>, I<nn>, I<dd>, I<cc>, I<bb>)

=cut
      } elsif($command == 0x58) {
         @E = ('time_signature',
           $time,
	   unpack("C*", # there SHOULD be exactly 4 bytes here
		  substr($$data_r, $Pointer, $length)
		 ));
	 # DTime, NN, DD, CC, BB

=item ('key_signature', I<dtime>, I<sf>, I<mi>)

=cut
      } elsif($command == 0x59) {
         @E = ('key_signature',
           $time,
	   unpack("cC", # there SHOULD be exactly 2 bytes here
		  substr($$data_r, $Pointer, $length)
		 ));
	 # DTime, SF(signed), MI

=item ('sequencer_specific', I<dtime>, I<raw>)

=cut
      } elsif($command == 0x7F) {
         @E = ('sequencer_specific',
           $time, substr($$data_r, $Pointer, $length));
	 # DTime, Binary Data

=item ('raw_meta_event', I<dtime>, I<command>(0-255), I<raw>)

=cut
      } else {
         @E = ('raw_meta_event',
	       $time,
	       $command,
	       substr($$data_r, $Pointer, $length)
	       # "[uninterpretable meta-event $command of length $length]"
	      );
	 # DTime, Command, Binary Data
           # It's uninterpretable; record it as raw_data.
      } # End of the meta-event ifcase.

      $Pointer += $length; #  Now move Pointer

    ######################################################################
    } elsif($first_byte == 0xF0   # It's a SYSEX
    #########################
        || $first_byte == 0xF7) {
      # Note that sysexes in MIDI /files/ are different than sysexes in
      #  MIDI transmissions!!
      # << The vast majority of system exclusive messages will just use the F0
      # format.  For instance, the transmitted message F0 43 12 00 07 F7 would
      # be stored in a MIDI file as F0 05 43 12 00 07 F7.  As mentioned above,
      # it is required to include the F7 at the end so that the reader of the
      # MIDI file knows that it has read the entire message. >>
      # (But the F7 is omitted if this is a non-final block in a multiblock
      # sysex; but the F7 (if there) is counted in the message's declared
      # length, so we don't have to think about it anyway.)
      ($command, $length, $remainder) =
        unpack("Cwa*", substr($$data_r, $Pointer, 5));
      $Pointer += 5 - length($remainder); # Move past just the encoding

=item ('sysex_f0', I<dtime>, I<raw>)

=item ('sysex_f7', I<dtime>, I<raw>)

=cut
      @E = ( $first_byte == 0xF0 ?
          'sysex_f0' : 'sysex_f7',
          $time, substr($$data_r, $Pointer, $length) );  # DTime, Data
      $Pointer += $length; #  Now move past the data

    ######################################################################
    # Now, the MIDI file spec says:
    #  <track data> = <MTrk event>+
    #  <MTrk event> = <delta-time> <event>
    #  <event> = <MIDI event> | <sysex event> | <meta-event>
    # I know that, on the wire, <MIDI event> can include note_on,
    # note_off, and all the other 8x to Ex events, AND Fx events
    # other than F0, F7, and FF -- namely, <song position msg>,
    # <song select msg>, and <tune request>.
    #
    # Whether these can occur in MIDI files is not clear specified from
    # the MIDI file spec.
    # 
    # So, I'm going to assume that they CAN, in practice, occur.
    # I don't know whether it's proper for you to actually emit these
    # into a MIDI file.
    #
    
    ######################################################################
    } elsif($first_byte == 0xF2) { # It's a Song Position ################

=item ('song_position', I<dtime>)

=cut
      #  <song position msg> ::=     F2 <data pair>
      @E = ('song_position',
        $time, &read_14_bit(substr($$data_r,$Pointer+1,2) )
      ); # DTime, Beats
      $Pointer += 3; # itself, and 2 data bytes

    ######################################################################
    } elsif($first_byte == 0xF3) { # It's a Song Select ##################

=item ('song_select', I<dtime>, I<song_number>)

=cut
      #  <song select msg> ::=       F3 <data singlet>
      @E = ( 'song_select',
        $time, unpack('C', substr($$data_r,$Pointer+1,1) )
      );  # DTime, Thing (?!) ... song number?  whatever that is
      $Pointer += 2;  # itself, and 1 data byte

    ######################################################################
    } elsif($first_byte == 0xF6) { # It's a Tune Request! ################

=item ('tune_request', I<dtime>)

=cut
      #  <tune request> ::=          F6
      @E = ( 'tune_request', $time );
      # DTime
      # What the Sam Scratch would a tune request be doing in a MIDI /file/?
      ++$Pointer;  # itself

###########################################################################
## ADD MORE META-EVENTS HERE
#Done:
# f0 f7 -- sysexes
# f2 -- song position
# f3 -- song select
# f6 -- tune request
# ff -- metaevent
###########################################################################
#TODO:
# f1 -- MTC Quarter Frame Message.   one data byte follows.
#     One data byte follows the Status. It's the time code value, a number
#     from 0 to 127.
# f8 -- MIDI clock.  no data.
# fa -- MIDI start.  no data.
# fb -- MIDI continue.  no data.
# fc -- MIDI stop.  no data.
# fe -- Active sense.  no data.
# f4 f5 f9 fd -- unallocated

    ######################################################################
    } elsif($first_byte > 0xF0) { # Some unknown kinda F-series event ####

=item ('raw_data', I<dtime>, I<raw>)

=cut
      # Here we only produce a one-byte piece of raw data.
      # But the encoder for 'raw_data' accepts any length of it.
      @E = ( 'raw_data',
	     $time, substr($$data_r,$Pointer,1) );
      # DTime and the Data (in this case, the one Event-byte)
      ++$Pointer;  # itself

    ######################################################################
    } else { # Fallthru.  How could we end up here? ######################
      warn
        "Aborting track.  Command-byte $first_byte at track offset $Pointer";
      last Event;
    }
    # End of the big if-group


     #####################################################################
    ######################################################################
    ##
    #   By the Power of Greyskull, I AM THE EVENT REGISTRAR!
    ##
    if( @E and  $E[0] eq 'end_track'  ) {
      # This's the code for exceptional handling of the EOT event.
      $eot = 1;
      unless( defined($options_r->{'no_eot_magic'})
	      and $options_r->{'no_eot_magic'} ) {
        if($E[1] > 0) {
          @E = ('text_event', $E[1], '');
          # Make up a fictive 0-length text event as a carrier
          #  for the non-zero delta-time.
        } else {
          # EOT with a delta-time of 0.  Ignore it!
          @E = ();
        }
      }
    }
    
    if( @E and  exists( $exclude{$E[0]} )  ) {
      if($Debug) {
        print " Excluding:\n";
        &dump(@E);
      }
    } else {
      if($Debug) {
        print " Processing:\n";
        &dump(@E);
      }
      if(@E){
	if( $exclusive_event_callback ) {
	  &{ $exclusive_event_callback }( @E );
	} else {
	  &{ $event_callback }( @E ) if $event_callback;
	  push(@events, [ @E ]);
	}
      }
    }

=back

Three of the above events are represented a bit oddly from the point
of view of the file spec:

The parameter I<pitch_wheel> for C<'pitch_wheel_change'> is a value
-8192 to 8191, although the actual encoding of this is as a value 0 to
16,383, as per the spec.

Sysex events are represented as either C<'sysex_f0'> or C<'sysex_f7'>,
depending on the status byte they are encoded with.

C<'end_track'> is a bit stranger, in that it is almost never actually
found, or needed.  When the MIDI decoder sees an EOT (i.e., an
end-track status: FF 2F 00) with a delta time of 0, it is I<ignored>!
If in the unlikely event that it has a nonzero delta-time, it's
decoded as a C<'text_event'> with whatever that delta-time is, and a
zero-length text parameter.  (This happens before the
C<'event_callback'> or C<'exclusive_event_callback'> callbacks are
given a crack at it.)  On the encoding side, an EOT is added to the
end of the track as a normal part of the encapsulation of track data.

I chose to add this special behavior so that you could add events to
the end of a track without having to work around any track-final
C<'end_track'> event.

However, if you set C<no_eot_magic> as a decoding parameter, none of
this magic happens on the decoding side -- C<'end_track'> is decoded
just as it is.

And if you set C<no_eot_magic> as an encoding parameter, then a
track-final 0-length C<'text_event'> with non-0 delta-times is left as
is.  Normally, such an event would be converted from a C<'text_event'>
to an C<'end_track'> event with thath delta-time.

Normally, no user needs to use the C<no_eot_magic> option either in
encoding or decoding.  But it is provided in case you need your event
LoL to be an absolutely literal representation of the binary data,
and/or vice versa.

=cut

    last Event if $eot;
  }
  # End of the bigass "Event" while-block

  return \@events;
}

###########################################################################

sub encode { # encode an event structure, presumably for writing to a file
  # Calling format:
  #   $data_r = MIDI::Event::encode( \@event_lol, { options } );
  # Takes a REFERENCE to an event structure (a LoL)
  # Returns an (unblessed) REFERENCE to track data.

  # If you want to use this to encode a /single/ event,
  # you still have to do it as a reference to an event structure (a LoL)
  # that just happens to have just one event.  I.e.,
  #   encode( [ $event ] ) or encode( [ [ 'note_on', 100, 5, 42, 64] ] )
  # If you're doing this, consider the never_add_eot track option, as in
  #   print MIDI ${ encode( [ $event], { 'never_add_eot' => 1} ) };

  my $events_r = $_[0];
  my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};
  my @data = (); # what I'll store chunks of data in
  my $data = ''; # what I'll join @data all together into

  croak "MIDI::Event::encode's argument must be an array reference!"
    unless ref($events_r); # better be an array!
  my @events = @$events_r;
  # Yes, copy it.  This is so my end_track magic won't corrupt the original

  my $unknown_callback = undef;
  $unknown_callback = $options_r->{'unknown_callback'}
    if ref($options_r->{'unknown_callback'}) eq 'CODE';

  unless($options_r->{'never_add_eot'}) {
    # One way or another, tack on an 'end_track'
    if(@events) { # If there's any events...
      my $last = $events[ -1 ];
      unless($last->[0] eq 'end_track') { # ...And there's no end_track already
        if($last->[0] eq 'text_event' and length($last->[2]) == 0) {
	  # 0-length text event at track-end.
	  if($options_r->{'no_eot_magic'}) {
	    # Exceptional case: don't mess with track-final
	    # 0-length text_events; just peg on an end_track
	    push(@events, ['end_track', 0]);
	  } else {
	    # NORMAL CASE: replace it with an end_track, leaving the DTime
	    $last->[0] = 'end_track';
	  }
        } else {
          # last event was neither a 0-length text_event nor an end_track
	  push(@events, ['end_track', 0]);
        }
      }
    } else { # an eventless track!
      @events = ['end_track',0];
    }
  }

#print "--\n";
#foreach(@events){ MIDI::Event::dump($_) }
#print "--\n";

  my $maybe_running_status = not $options_r->{'no_running_status'};
  my $last_status = -1;

  # Here so we don't have to re-my on every iteration
  my(@E, $event, $dtime, $event_data, $status, $parameters);
 Event_Encode:
  foreach my $event_r (@events) {
    next unless ref($event_r); # what'd such a thing ever be doing in here?
    @E = @$event_r;
     # Yes, copy it.  Otherwise the shifting'd corrupt the original
    next unless @E;

    $event = shift @E;
    next unless length($event);

    $dtime = int shift @E;

    $event_data = '';

    if(   # MIDI events -- eligible for running status
       $event    eq 'note_on'
       or $event eq 'note_off'
       or $event eq 'control_change'
       or $event eq 'key_after_touch'
       or $event eq 'patch_change'
       or $event eq 'channel_after_touch'
       or $event eq 'pitch_wheel_change'  )
    {
#print "ziiz $event\n";
      # $status = $parameters = '';
      # This block is where we spend most of the time.  Gotta be tight.

      if($event eq 'note_off'){
	$status = 0x80 | (int($E[0]) & 0x0F);
	$parameters = pack('C2',
			   int($E[1]) & 0x7F, int($E[2]) & 0x7F);
      } elsif($event eq 'note_on'){
	$status = 0x90 | (int($E[0]) & 0x0F);
	$parameters = pack('C2',
			   int($E[1]) & 0x7F, int($E[2]) & 0x7F);
      } elsif($event eq 'key_after_touch'){
	$status = 0xA0 | (int($E[0]) & 0x0F);
	$parameters = pack('C2',
			   int($E[1]) & 0x7F, int($E[2]) & 0x7F);
      } elsif($event eq 'control_change'){
	$status = 0xB0 | (int($E[0]) & 0x0F);
	$parameters = pack('C2',
			   int($E[1]) & 0xFF, int($E[2]) & 0xFF);
      } elsif($event eq 'patch_change'){
	$status = 0xC0 | (int($E[0]) & 0x0F);
	$parameters = pack('C',
			   int($E[1]) & 0xFF);
      } elsif($event eq 'channel_after_touch'){
	$status = 0xD0 | (int($E[0]) & 0x0F);
	$parameters = pack('C',
			   int($E[1]) & 0xFF);
      } elsif($event eq 'pitch_wheel_change'){
	$status = 0xE0 | (int($E[0]) & 0x0F);
        $parameters =  &write_14_bit(int($E[1]) + 0x2000);
      } else {
        die "BADASS FREAKOUT ERROR 31415!";
      }
      # And now the encoding
      push(@data,
	($maybe_running_status  and  $status == $last_status) ?
        pack('wa*', $dtime, $parameters) :  # If we can use running status.
	pack('wCa*', $dtime, $status, $parameters)  # If we can't.
      );
      $last_status = $status;
      next;
    } else {
      # Not a MIDI event.
      # All the code in this block could be more efficient, but frankly,
      # this is not where the code needs to be tight.
      # So we wade thru the cases and eventually hopefully fall thru
      # with $event_data set.
#print "zaz $event\n";
      $last_status = -1;

      if($event eq 'raw_meta_event') {
	$event_data = pack("CCwa*", 0xFF, int($E[0]), length($E[1]), $E[1]);

      # Text meta-events...
      } elsif($event eq 'text_event') {
	$event_data = pack("CCwa*", 0xFF, 0x01, length($E[0]), $E[0]);
      } elsif($event eq 'copyright_text_event') {
	$event_data = pack("CCwa*", 0xFF, 0x02, length($E[0]), $E[0]);
      } elsif($event eq 'track_name') {
	$event_data = pack("CCwa*", 0xFF, 0x03, length($E[0]), $E[0]);
      } elsif($event eq 'instrument_name') {
	$event_data = pack("CCwa*", 0xFF, 0x04, length($E[0]), $E[0]);
      } elsif($event eq 'lyric') {
	$event_data = pack("CCwa*", 0xFF, 0x05, length($E[0]), $E[0]);
      } elsif($event eq 'marker') {
	$event_data = pack("CCwa*", 0xFF, 0x06, length($E[0]), $E[0]);
      } elsif($event eq 'cue_point') {
	$event_data = pack("CCwa*", 0xFF, 0x07, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_08') {
	$event_data = pack("CCwa*", 0xFF, 0x08, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_09') {
	$event_data = pack("CCwa*", 0xFF, 0x09, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_0a') {
	$event_data = pack("CCwa*", 0xFF, 0x0a, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_0b') {
	$event_data = pack("CCwa*", 0xFF, 0x0b, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_0c') {
	$event_data = pack("CCwa*", 0xFF, 0x0c, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_0d') {
	$event_data = pack("CCwa*", 0xFF, 0x0d, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_0e') {
	$event_data = pack("CCwa*", 0xFF, 0x0e, length($E[0]), $E[0]);
      } elsif($event eq 'text_event_0f') {
	$event_data = pack("CCwa*", 0xFF, 0x0f, length($E[0]), $E[0]);
      # End of text meta-events

      } elsif($event eq 'end_track') {
	$event_data = "\xFF\x2F\x00";

      } elsif($event eq 'set_tempo') {
 	$event_data = pack("CCwa*", 0xFF, 0x51, 3,
			    substr( pack('N', $E[0]), 1, 3
                          ));
      } elsif($event eq 'smpte_offset') {
 	$event_data = pack("CCwCCCCC", 0xFF, 0x54, 5, @E[0,1,2,3,4] );
      } elsif($event eq 'time_signature') {
 	$event_data = pack("CCwCCCC",  0xFF, 0x58, 4, @E[0,1,2,3] );
      } elsif($event eq 'key_signature') {
 	$event_data = pack("CCwcC",    0xFF, 0x59, 2, @E[0,1]);
      } elsif($event eq 'sequencer_specific') {
 	$event_data = pack("CCwa*",    0xFF, 0x7F, length($E[0]), $E[0]);
      # End of Meta-events

      # Other Things...
      } elsif($event eq 'sysex_f0') {
 	$event_data = pack("Cwa*", 0xF0, length($E[0]), $E[0]);
      } elsif($event eq 'sysex_f7') {
 	$event_data = pack("Cwa*", 0xF7, length($E[0]), $E[0]);

      } elsif($event eq 'song_position') {
 	$event_data = "\xF2" . &write_14_bit( $E[0] );
      } elsif($event eq 'song_select') {
 	$event_data = pack('CC', 0xF3, $E[0] );
      } elsif($event eq 'tune_request') {
 	$event_data = "\xF6";
      } elsif($event eq 'raw_data') {
 	$event_data = $E[0];
      # End of Other Stuff

      } else {
	# The Big Fallthru
        if($unknown_callback) {
	  push(@data, &{ $unknown_callback }( @$event_r ));
        } else {
          warn "Unknown event: \'$event\'\n";
          # To surpress complaint here, just set
          #  'unknown_callback' => sub { return () }
        }
	next;
      }

#print "Event $event encoded part 2\n";
      push(@data, pack('wa*', $dtime, $event_data))
        if length($event_data); # how could $event_data be empty
    }
  }
  $data = join('', @data);
  return \$data;
}

###########################################################################

###########################################################################

=head1 MIDI BNF

For your reference (if you can make any sense of it), here is a copy
of the MIDI BNF, as I found it in a text file that's been floating
around the Net since the late 1980s.

Note that this seems to describe MIDI events as they can occur in
MIDI-on-the-wire.  I I<think> that realtime data insertion (i.e., the
ability to have E<lt>realtime byteE<gt>s popping up in the I<middle>
of messages) is something that can't happen in MIDI files.

In fact, this library, as written, I<can't> correctly parse MIDI data
that has such realtime bytes inserted in messages.  Nor does it
support representing such insertion in a MIDI event structure that's
encodable for writing to a file.  (Although you could theoretically
represent events with embedded E<lt>realtime byteE<gt>s as just
C<raw_data> events; but then, you can always stow anything
at all in a C<raw_data> event.)

 1.  <MIDI Stream> ::=           <MIDI msg> < MIDI Stream>
 2.  <MIDI msg> ::=              <sys msg> | <chan msg>
 3.  <chan msg> ::=              <chan 1byte msg> |
                                 | <chan 2byte msg>
 4.  <chan 1byte msg> ::=        <chan stat1 byte> <data singlet>
                                   <running singlets>
 5.  <chan 2byte msg> ::=        <chan stat2 byte> <data pair>
                                   <running pairs>
 6.  <chan stat1 byte> ::=       <chan voice stat1 nibble>
                                   <hex nibble>
 7.  <chan stat2 byte> ::=       <chan voice stat2 nibble>
                                   <hex nibble>
 8.  <chan voice stat1 nyble>::= C | D
 9.  <chan voice stat2 nyble>::= 8 | 9 | A | B | E
 10. <hex nyble> ::=             0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
                                 | 8 | 9 | A | B | C | D | E | F
 11. <data pair> ::=             <data singlet> <data singlet>
 12. <data singlet> ::=          <realtime byte> <data singlet> |
                                 | <data byte>
 13. <running pairs> ::=         <empty> | <data pair> <running pairs>
 14. <running singlets> ::=      <empty> |
                                 | <data singlet> <running singlets>
 15. <data byte> ::=             <data MSD> <hex nyble>
 16. <data MSD> ::=              0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
 17. <realtime byte> ::=         F8 | FA | FB | FC | FE | FF
 18. <sys msg> ::=               <sys common msg> |
                                 | <sysex msg> |
                                 | <sys realtime msg>
 19. <sys realtime msg> ::=      <realtime byte>
 20. <sysex msg> ::=             <sysex data byte>
                                   <data singlet> <running singlets>
                                   <eox byte>
 21. <sysex stat byte> ::=       F0
 22. <eox byte> ::=              F7
 23. <sys common msg> ::=        <song position msg> |
                                 | <song select msg> |
                                 | <tune request>
 24. <tune request> ::=          F6
 25. <song position msg> ::=     <song position stat byte>
                                   <data pair>
 26. <song select msg> ::=       <song select stat byte>
                                   <data singlet>
 27. <song position stat byte>::=F2
 28. <song select stat byte> ::= F3

=head1 COPYRIGHT 

Copyright (c) 1998-2005 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>  (Except the BNF --
who knows who's behind that.)

=cut

1;

__END__
