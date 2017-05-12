
# Time-stamp: "2010-12-23 10:00:01 conklin"
require 5;
package MIDI::Opus;
use strict;
use vars qw($Debug $VERSION);
use Carp;

$Debug = 0;
$VERSION = 0.83;

=head1 NAME

MIDI::Opus -- functions and methods for MIDI opuses

=head1 SYNOPSIS

 use MIDI; # uses MIDI::Opus et al
 foreach $one (@ARGV) {
   my $opus = MIDI::Opus->new({ 'from_file' => $one, 'no_parse' => 1 });
   print "$one has ", scalar( $opus->tracks ) " tracks\n";
 }
 exit;

=head1 DESCRIPTION

MIDI::Opus provides a constructor and methods for objects
representing a MIDI opus (AKA "song").  It is part of the MIDI suite.

An opus object has three attributes: a format (0 for MIDI Format 0), a
tick parameter (parameter "division" in L<MIDI::Filespec>), and a list
of tracks objects that are the real content of that opus.

Be aware that options specified for the encoding or decoding of an
opus may not be documented in I<this> module's documentation, as they
may be (and, in fact, generally are) options just passed down to the
decoder/encoder in MIDI::Event -- so see L<MIDI::Event> for an
explanation of most of them, actually.

=head1 CONSTRUCTOR AND METHODS

MIDI::Opus provides...

=over

=cut

###########################################################################

=item the constructor MIDI::Opus->new({ ...options... })

This returns a new opus object.  The options, which are optional, is
an anonymous hash.  By default, you get a new format-0 opus with no
tracks and a tick parameter of 96.  There are six recognized options:
C<format>, to set the MIDI format number (generally either 0 or 1) of
the new object; C<ticks>, to set its ticks parameter; C<tracks>, which
sets the tracks of the new opus to the contents of the list-reference
provided; C<tracks_r>, which is an exact synonym of C<tracks>;
C<from_file>, which reads the opus from the given filespec; and
C<from_handle>, which reads the opus from the the given filehandle
reference (e.g., C<*STDIN{IO}>), after having called binmode() on that
handle, if that's a problem.

If you specify either C<from_file> or C<from_handle>, you probably
don't want to specify any of the other options -- altho you may well
want to specify options that'll get passed down to the decoder in
MIDI::Events, such as 'include' => ['sysex_f0', 'sysex_f7'], just for
example.

Finally, the option C<no_parse> can be used in conjuction with either
C<from_file> or C<from_handle>, and, if true, will block MTrk tracks'
data from being parsed into MIDI events, and will leave them as track
data (i.e., what you get from $track->data).  This is useful if you
are just moving tracks around across files (or just counting them in
files, as in the code in the Synopsis, above), without having to deal
with any of the events in them.  (Actually, this option is implemented
in code in MIDI::Track, but in a routine there that I've left
undocumented, as you should access it only thru here.)

=cut

sub new {
  # Make a new MIDI opus object.
  my $class = shift;
  my $options_r = (defined($_[0]) and ref($_[0]) eq 'HASH') ? $_[0] : {};

  my $this = bless( {}, $class );

  print "New object in class $class\n" if $Debug;

  return $this if $options_r->{'no_opus_init'}; # bypasses all init.
  $this->_init( $options_r );

  if(
     exists( $options_r->{'from_file'} ) &&
     defined( $options_r->{'from_file'} ) &&
     length( $options_r->{'from_file'} )
  ){
    $this->read_from_file( $options_r->{'from_file'}, $options_r );
  } elsif(
     exists( $options_r->{'from_handle'} ) &&
     defined( $options_r->{'from_handle'} ) &&
     length( $options_r->{'from_handle'} )
  ){
    $this->read_from_handle( $options_r->{'from_handle'}, $options_r );
  }
  return $this;
}
###########################################################################

=item the method $new_opus = $opus->copy

This duplicates the contents of the given opus, and returns
the duplicate.  If you are unclear on why you may need this function,
read the documentation for the C<copy> method in L<MIDI::Track>.

=cut

sub copy {
  # Duplicate a given opus.  Even dupes the tracks.
  # Call as $new_one = $opus->copy
  my $opus = shift;

  my $new = bless( { %{$opus} }, ref $opus );
  # a first crude dupe.
  # yes, bless it into whatever class the original came from

  $new->{'tracks'} =  # Now dupe the tracks.
    [ map( $_->copy,
	   @{ $new->{'tracks'} }
	 )
     ] if $new->{'tracks'}; # (which should always be true anyhoo)

  return $new;
}

sub _init {
  # Init a MIDI object -- (re)set it with given parameters, or defaults
  my $this = shift;
  my $options_r = ref($_[0]) eq 'HASH' ? $_[0] : {};

  print "_init called against $this\n" if $Debug;
  if($Debug) {
    if(%$options_r) {
      print "Parameters: ", map("<$_>", %$options_r), "\n";
    } else {
      print "Null parameters for opus init\n";
    }
  }
  $this->{'format'} =
    defined($options_r->{'format'}) ? $options_r->{'format'} : 1;
  $this->{'ticks'}  =
    defined($options_r->{'ticks'}) ? $options_r->{'ticks'} : 96;

  $options_r->{'tracks'} = $options_r->{'tracks_r'}
    if( exists( $options_r->{'tracks_r'} ) and not
	exists( $options_r->{'tracks'} )
      );
  # so tracks_r => [ @tracks ] is a synonym for 
  #    tracks   => [ @tracks ]
  # as on option for new()

  $this->{'tracks'}  =
    ( defined($options_r->{'tracks'})
      and ref($options_r->{'tracks'}) eq 'ARRAY' )
    ? $options_r->{'tracks'} : []
  ;
  return;
}
#########################################################################

=item the method $opus->tracks( @tracks )

Returns the list of tracks in the opus, possibly after having set it
to @tracks, if specified and not empty.  (If you happen to want to set
the list of tracks to an empty list, for whatever reason, you have to
use "$opus->tracks_r([])".)

In other words: $opus->tracks(@tracks) is how to set the list of
tracks (assuming @tracks is not empty), and @tracks = $opus->tracks is
how to read the list of tracks.

=cut

sub tracks {
  my $this = shift;
  $this->{'tracks'} = [ @_ ] if @_;
  return @{ $this->{'tracks'} };
}

=item the method $opus->tracks_r( $tracks_r )

Returns a reference to the list of tracks in the opus, possibly after
having set it to $tracks_r, if specified.  "$tracks_r" can actually be
any listref, whether it comes from a scalar as in C<$some_tracks_r>,
or from something like C<[@tracks]>, or just plain old C<\@tracks>

Originally $opus->tracks was the only way to deal with tracks, but I
added $opus->tracks_r to make possible 1) setting the list of tracks
to (), for whatever that's worth, 2) parallel structure between
MIDI::Opus::tracks[_r] and MIDI::Tracks::events[_r] and 3) so you can
directly manipulate the opus's tracks, without having to I<copy> the
list of tracks back and forth.  This way, you can say:

          $tracks_r = $opus->tracks_r();
          @some_stuff = splice(@$tracks_r, 4, 6);

But if you don't know how to deal with listrefs like that, that's OK,
just use $opus->tracks.

=cut

sub tracks_r {
  my $this = shift;
  $this->{'tracks'} = $_[0] if ref($_[0]);
  return $this->{'tracks'};
}

=item the method $opus->ticks( $tick_parameter )

Returns the tick parameter from $opus, after having set it to
$tick_parameter, if provided.

=cut

sub ticks {
  my $this = shift;
  $this->{'ticks'} = $_[0] if defined($_[0]);
  return $this->{'ticks'};
}

=item the method $opus->format( $format )

Returns the MIDI format for $opus, after having set it to
$format, if provided.

=cut

sub format {
  my $this = shift;
  $this->{'format'} = $_[0] if defined($_[0]);
  return $this->{'format'};
}

sub info { # read-only
  # Hm, do I really want this routine?  For ANYTHING at all?
  my $this = shift;
  return (
    'format' => $this->{'format'},# I want a scalar
    'ticks'  => $this->{'ticks'}, # I want a scalar
    'tracks' => $this->{'tracks'} # I want a ref to a list
  );
}

=item the method $new_opus = $opus->quantize

This grid quantizes an opus.  It simply calls MIDI::Score::quantize on
every track.  See docs for MIDI::Score::quantize.  Original opus is
destroyed, use MIDI::Opus::copy if you want to take a copy first.

=cut

sub quantize {
  my $this = $_[0];
  my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};
  my $grid = $options_r->{grid};
  if ($grid < 1) {carp "bad grid $grid in MIDI::Opus::quantize!"; return;}
  return if ($grid eq 1); # no quantizing to do
  my $qd = $options_r->{durations}; # quantize durations?
  my $new_tracks_r = [];
  foreach my $track ($this->tracks) {
      my $score_r = MIDI::Score::events_r_to_score_r($track->events_r);
      my $new_score_r = MIDI::Score::quantize($score_r,{grid=>$grid,durations=>$qd});
      my $events_r = MIDI::Score::score_r_to_events_r($new_score_r);
      my $new_track = MIDI::Track->new({events_r=>$events_r});
      push @{$new_tracks_r}, $new_track;
  }
  $this->tracks_r($new_tracks_r);
}

###########################################################################

=item the method $opus->dump( { ...options...} )

Dumps the opus object as a bunch of text, for your perusal.  Options
include: C<flat>, if true, will have each event in the opus as a
tab-delimited line -- or as delimited with whatever you specify with
option C<delimiter>; I<otherwise>, dump the data as Perl code that, if
run, would/should reproduce the opus.  For concision's sake, the track data
isn't dumped, unless you specify the option C<dump_tracks> as true.

=cut

sub dump { # method; read-only
  my $this = $_[0];
  my %info = $this->info();
  my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};

  if($options_r->{'flat'}) { # Super-barebones dump mode
    my $d = $options_r->{'delimiter'} || "\t";
    foreach my $track ($this->tracks) {
      foreach my $event (@{ $track->events_r }) {
	print( join($d, @$event), "\n" );
      }
    }
    return;
  }

  print "MIDI::Opus->new({\n",
    "  'format' => ", &MIDI::_dump_quote($this->{'format'}), ",\n",
    "  'ticks'  => ", &MIDI::_dump_quote($this->{'ticks'}), ",\n";

  my @tracks = $this->tracks;
  if( $options_r->{'dump_tracks'} ) {
    print "  'tracks' => [   # ", scalar(@tracks), " tracks...\n\n";
    foreach my $x (0 .. $#tracks) {
      my $track = $tracks[$x];
      print "    # Track \#$x ...\n";
      if(ref($track)) {
        $track->dump($options_r);
      } else {
        print "    # \[$track\] is not a reference!!\n";
      }
    }
    print "  ]\n";
  } else {
    print "  'tracks' => [ ],  # ", scalar(@tracks), " tracks (not dumped)\n";
  }
  print "});\n";
  return 1;
}

###########################################################################
# And now the real fun...
###########################################################################

=item the method $opus->write_to_file('filespec', { ...options...} )

Writes $opus as a MIDI file named by the given filespec.
The options hash is optional, and whatever you specify as options
percolates down to the calls to MIDI::Event::encode -- which see.
Currently this just opens the file, calls $opus->write_to_handle
on the resulting filehandle, and closes the file.

=cut

sub write_to_file { # method
  # call as $opus->write_to_file("../../midis/stuff1.mid", { ..options..} );
  my $opus = $_[0];
  my $destination = $_[1];
  my $options_r = ref($_[2]) eq 'HASH' ?  $_[2] : {};

  croak "No output file specified" unless length($destination);
  unless(open(OUT_MIDI, ">$destination")) {
    croak "Can't open $destination for writing\: \"$!\"\n";
  }
  $opus->write_to_handle( *OUT_MIDI{IO}, $options_r);
  close(OUT_MIDI)
    || croak "Can't close filehandle for $destination\: \"$!\"\n";
  return; # nothing useful to return
}

sub read_from_file { # method, surprisingly enough
  # $opus->read_from_file("ziz1.mid", {'stuff' => 1}).
  #  Overwrites the contents of $opus with the contents of the file ziz1.mid
  #  $opus is presumably newly initted.
  #  The options hash is optional.
  #  This is currently meant to be called by only the
  #   MIDI::Opus->new() constructor.

  my $opus = $_[0];
  my $source = $_[1];
  my $options_r = ref($_[2]) eq 'HASH' ?  $_[2] : {};

  croak "No source file specified" unless length($source);
  unless(open(IN_MIDI, "<$source")) {
    croak "Can't open $source for reading\: \"$!\"\n";
  }
  my $size = -s $source;
  $size = undef unless $size;

  $opus->read_from_handle(*IN_MIDI{IO}, $options_r, $size);
  # Thanks to the EFNet #perl cabal for helping me puzzle out "*IN_MIDI{IO}"
  close(IN_MIDI) ||
    croak "error while closing filehandle for $source\: \"$!\"\n";

  return $opus;
}

=item the method $opus->write_to_handle(IOREF, { ...options...} )

Writes $opus as a MIDI file to the IO handle you pass a reference to
(example: C<*STDOUT{IO}>).
The options hash is optional, and whatever you specify as options
percolates down to the calls to MIDI::Event::encode -- which see.
Note that this is probably not what you'd want for sending music
to C</dev/sequencer>, since MIDI files are not MIDI-on-the-wire.

=cut

###########################################################################
sub write_to_handle { # method
  # Call as $opus->write_to_handle( *FH{IO}, { ...options... });
  my $opus = $_[0];
  my $fh = $_[1];
  my $options_r = ref($_[2]) eq 'HASH' ?  $_[2] : {};

  binmode($fh);

  my $tracks = scalar( $opus->tracks );
  carp "Writing out an opus with no tracks!\n" if $tracks == 0;

  my $format;
  if( defined($opus->{'format'}) ) {
    $format = $opus->{'format'};
  } else { # Defaults
    if($tracks == 0) {
      $format = 2; # hey, why not?
    } elsif ($tracks == 1) {
      $format = 0;
    } else {
      $format = 1;
    }
  }
  my $ticks =
   defined($opus->{'ticks'}) ? $opus->{'ticks'} : 96 ;
    # Ninety-six ticks per quarter-note seems a pleasant enough default.

  print $fh (
    "MThd\x00\x00\x00\x06", # header; 6 bytes follow
    pack('nnn', $format, $tracks, $ticks)
  );
  foreach my $track (@{ $opus->{'tracks'} }) {
    my $data = '';
    my $type = substr($track->{'type'} . "\x00\x00\x00\x00", 0, 4);
      # Force it to be 4 chars long.
    $data =  ${ $track->encode( $options_r ) };
      # $track->encode will handle the issue of whether
      #  to use the track's data or its events
    print $fh ($type, pack('N', length($data)), $data);
  }
  return;
}

############################################################################
sub read_from_handle { # a method, surprisingly enough
  # $opus->read_from_handle(*STDIN{IO}, {'stuff' => 1}).
  #  Overwrites the contents of $opus with the contents of the MIDI file
  #   from the filehandle you're passing a reference to.
  #  $opus is presumably newly initted.
  #  The options hash is optional.

  #  This is currently meant to be called by only the
  #   MIDI::Opus->new() constructor.

  my $opus = $_[0];
  my $fh = $_[1];
  my $options_r = ref($_[2]) eq 'HASH' ?  $_[2] : {};
  my $file_size_left;
  $file_size_left = $_[3] if defined $_[3];

  binmode($fh);

  my $in = '';

  my $track_size_limit;
  $track_size_limit = $options_r->{'track_size'}
   if exists $options_r->{'track_size'};

  croak "Can't even read the first 14 bytes from filehandle $fh"
    unless read($fh, $in, 14);
    # 14 = The expected header length.

  if(defined $file_size_left) {
    $file_size_left -= 14;
  }

  my($id, $length, $format, $tracks_expected, $ticks) = unpack('A4Nnnn', $in);

  croak "data from handle $fh doesn't start with a MIDI file header"
    unless $id eq 'MThd';
  croak "Unexpected MTHd chunk length in data from handle $fh"
    unless $length == 6;
  $opus->{'format'} = $format;
  $opus->{'ticks'}  = $ticks;   # ...which may be a munged 'negative' number
  $opus->{'tracks'} = [];

  print "file header from handle $fh read and parsed fine.\n" if $Debug;
  my $track_count = 0;

 Track_Chunk:
  until( eof($fh) ) {
    ++$track_count;
    print "Reading Track \# $track_count into a new track\n" if $Debug;

    if(defined $file_size_left) {
      $file_size_left -= 2;
      croak "reading further would exceed file_size_limit"
	if $file_size_left < 0;
    }

    my($header, $data);
    croak "Can't read header for track chunk \#$track_count"
      unless read($fh, $header, 8);
    my($type, $length) = unpack('A4N', $header);

    if(defined $track_size_limit and $track_size_limit > $length) {
      croak "Track \#$track_count\'s length ($length) would"
       . " exceed track_size_limit $track_size_limit";
    }

    if(defined $file_size_left) {
      $file_size_left -= $length;
      croak "reading track \#$track_count (of length $length) " 
        . "would exceed file_size_limit"
       if $file_size_left < 0;
    }

    read($fh, $data, $length);   # whooboy, actually read it now

    if($length == length($data)) {
      push(
        @{ $opus->{'tracks'} },
        &MIDI::Track::decode( $type, \$data, $options_r )
      );
    } else {
      croak
        "Length of track \#$track_count is off in data from $fh; "
        . "I wanted $length\, but got "
        . length($data);
    }
  }

  carp
    "Header in data from $fh says to expect $tracks_expected tracks, "
    . "but $track_count were found\n"
    unless $tracks_expected == $track_count;
  carp "No tracks read in data from $fh\n" if $track_count == 0;

  return $opus;
}
###########################################################################

=item the method $opus->draw({ ...options...})

This currently experimental method returns a new GD image object that's
a graphic representation of the notes in the given opus.  Options include:
C<width> -- the width of the image in pixels (defaults to 600);
C<bgcolor> -- a six-digit hex RGB representation of the background color
for the image (defaults to $MIDI::Opus::BG_color, currently '000000');
C<channel_colors> -- a reference to a list of colors (in six-digit hex RGB)
to use for representing notes on given channels.
Defaults to @MIDI::Opus::Channel_colors.
This list is a list of pairs of colors, such that:
the first of a pair (color N*2) is the color for the first pixel in a
note on channel N; and the second (color N*2 + 1) is the color for the
remaining pixels of that note.  If you specify only enough colors for
channels 0 to M, notes on a channels above M will use 'recycled'
colors -- they will be plotted with the color for channel
"channel_number % M" (where C<%> = the MOD operator).

This means that if you specify

          channel_colors => ['00ffff','0000ff']

then all the channels' notes will be plotted with an aqua pixel followed
by blue ones; and if you specify

          channel_colors => ['00ffff','0000ff', 'ff00ff','ff0000']

then all the I<even> channels' notes will be plotted with an aqua
pixel followed by blue ones, and all the I<odd> channels' notes will
be plotted with a purple pixel followed by red ones.

As to what to do with the object you get back, you probably want
something like:

          $im = $chachacha->draw;
          open(OUT, ">$gif_out"); binmode(OUT);
          print OUT $im->gif;
          close(OUT);

Using this method will cause a C<die> if it can't successfully C<use GD>.

I emphasise that C<draw> is expermental, and, in any case, is only meant
to be a crude hack.  Notably, it does not address well some basic problems:
neither volume nor patch-selection (nor any notable aspects of the
patch selected)
are represented; pitch-wheel changes are not represented;
percussion (whether on percussive patches or on channel 10) is not
specially represented, as it probably should be;
notes overlapping are not represented at all well.

=cut

sub draw { # method
  my $opus = $_[0];
  my $options_r = ref($_[1]) ? $_[1] : {};

  &use_GD(); # will die at runtime if we call this function but it can't use GD

  my $opus_time = 0;
  my @scores = ();
  foreach my $track ($opus->tracks) {
    my($score_r, $track_time) = MIDI::Score::events_r_to_score_r(
      $track->events_r );
    push(@scores, $score_r) if @$score_r;
    $opus_time = $track_time if $track_time > $opus_time;
  }

  my $width = $options_r->{'width'} || 600;

  croak "opus can't be drawn because it takes no time" unless $opus_time;
  my $pixtix = $opus_time / $width; # Number of ticks a pixel represents

  my $im = GD::Image->new($width,127);
  # This doesn't handle pitch wheel, nor does it tread things on channel 10
  #  (percussion) as specially as it probably should.
  # The problem faced here is how to map onto pixel color all the
  #  characteristics of a note (say, Channel, Note, Volume, and Patch).
  # I'll just do it for channels.  Rewrite this on your own if you want
  #  something different.

  my $bg_color =
    $im->colorAllocate(unpack('C3', pack('H2H2H2',unpack('a2a2a2',
	( length($options_r->{'bg_color'}) ? $options_r->{'bg_color'}
          : $MIDI::Opus::BG_color)
							 ))) );
  @MIDI::Opus::Channel_colors = ( '00ffff' , '0000ff' )
    unless @MIDI::Opus::Channel_colors;
  my @colors =
    map( $im->colorAllocate(
			    unpack('C3', pack('H2H2H2',unpack('a2a2a2',$_)))
			   ), # convert 6-digit hex to a scalar tuple
	 ref($options_r->{'channel_colors'}) ?
           @{$options_r->{'channel_colors'}} : @MIDI::Opus::Channel_colors
       );
  my $channels_in_palette = int(@colors / 2);
  $im->fill(0,0,$bg_color);
  foreach my $score_r (@scores) {
    foreach my $event_r (@$score_r) {
      next unless $event_r->[0] eq 'note';
      my($time, $duration, $channel, $note, $volume) = @{$event_r}[1,2,3,4,5];
      my $y = 127 - $note;
      my $start_x = $time / $pixtix;
      $im->line($start_x, $y, ($time + $duration) / $pixtix, $y,
                $colors[1 + ($channel % $channels_in_palette)] );
      $im->setPixel($start_x , $y, $colors[$channel % $channels_in_palette] );
    }
  }
  return $im; # Returns the GD object, which the user then dumps however
}

#--------------------------------------------------------------------------
{ # Closure so we can use this wonderful variable:
  my $GD_used = 0;
  sub use_GD {
    return if $GD_used;
    eval("use GD;"); croak "You don't seem to have GD installed." if $@;
    $GD_used = 1; return;
  }
  # Why use GD at runtime like this, instead of at compile-time like normal?
  # So we can still use everything in this module except &draw even if we
  # don't have GD on this system.
}

######################################################################
# This maps channel number onto colors for draw(). It is quite unimaginative,
#  and reuses colors two or three times.  It's a package global.  You can
#  change it by assigning to @MIDI::Simple::Channel_colors.

@MIDI::Opus::Channel_colors =
  (
   'c0c0ff', '6060ff',  # start / sustain color, channel 0
   'c0ffc0', '60ff60',  # start / sustain color, channel 1, etc...
   'ffc0c0', 'ff6060',  'ffc0ff', 'ff60ff',  'ffffc0', 'ffff60',
   'c0ffff', '60ffff',
   
   'c0c0ff', '6060ff',  'c0ffc0', '60ff60',  'ffc0c0', 'ff6060', 
   'c0c0c0', '707070', # channel 10
   
   'ffc0ff', 'ff60ff',  'ffffc0', 'ffff60',  'c0ffff', '60ffff',
   'c0c0ff', '6060ff',  'c0ffc0', '60ff60',  'ffc0c0', 'ff6060',
  );
$MIDI::Opus::BG_color = '000000'; # Black goes with everything, you know.

###########################################################################

=back

=head1 WHERE'S THE DESTRUCTOR?

Because MIDI objects (whether opuses or tracks) do not contain any
circular data structures, you don't need to explicitly destroy them in
order to deallocate their memory.  Consider this code snippet:

 use MIDI;
 foreach $one (@ARGV) {
   my $opus = MIDI::Opus->new({ 'from_file' => $one, 'no_parse' => 1 });
   print "$one has ", scalar( $opus->tracks ) " tracks\n";
 }

At the end of each iteration of the foreach loop, the variable $opus
goes away, along with its contents, a reference to the opus object.
Since no other references to it exist (i.e., you didn't do anything like
push(@All_opuses,$opus) where @All_opuses is a global), the object is
automagically destroyed and its memory marked for recovery.

If you wanted to explicitly free up the memory used by a given opus
object (and its tracks, if those tracks aren't used anywhere else) without
having to wait for it to pass out of scope, just replace it with a new
empty object:

 $opus = MIDI::Opus->new;

or replace it with anything at all -- or even just undef it:

 undef $opus;

Of course, in the latter case, you can't then use $opus as an opus
object anymore, since it isn't one.

=head1 NOTE ON TICKS

If you want to use "negative" values for ticks (so says the spec: "If
division is negative, it represents the division of a second
represented by the delta-times in the file,[...]"), then it's up to
you to figure out how to represent that whole ball of wax so that when
it gets C<pack()>'d as an "n", it comes out right.  I think it'll involve
something like:

  $opus->ticks(  (unpack('C', pack('c', -25)) << 8) & 80  );

for bit resolution (80) at 25 f/s.

But I've never tested this.  Let me know if you get it working right,
OK?  If anyone I<does> get it working right, and tells me how, I'll
try to support it natively.

=head1 NOTE ON WARN-ING AND DIE-ING

In the case of trying to parse a malformed MIDI file (which is not a
common thing, in my experience), this module (or MIDI::Track or
MIDI::Event) may warn() or die() (Actually, carp() or croak(), but
it's all the same in the end).  For this reason, you shouldn't use
this suite in a case where the script, well, can't warn or die -- such
as, for example, in a CGI that scans for text events in a uploaded
MIDI file that may or may not be well-formed.  If this I<is> the kind
of task you or someone you know may want to do, let me know and I'll
consider some kind of 'no_die' parameter in future releases.
(Or just trap the die in an eval { } around your call to anything you
think you could die.)

=head1 COPYRIGHT 

Copyright (c) 1998-2002 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHORS

Sean M. Burke C<sburke@cpan.org> (until 2010)

Darrell Conklin C<conklin@cpan.org> (from 2010)

=cut

1;
__END__
