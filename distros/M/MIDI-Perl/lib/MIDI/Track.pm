
# Time-stamp: "2013-02-01 22:40:38 conklin"
require 5;
package MIDI::Track;
use strict;
use vars qw($Debug $VERSION);
use Carp;

$Debug = 0;
$VERSION = '0.83';

=head1 NAME

MIDI::Track -- functions and methods for MIDI tracks

=head1 SYNOPSIS

 use MIDI; # ...which "use"s MIDI::Track et al
 $taco_track = MIDI::Track->new;
 $taco_track->events(
  ['text_event', 0, "I like tacos!"],
  ['note_on',    0, 4, 50, 96 ],
  ['note_off', 300, 4, 50, 96 ],
 );
 $opus = MIDI::Opus->new(
  {  'format' => 0,  'ticks' => 240,  'tracks' => [ $taco_track ] }
 );
   ...etc...

=head1 DESCRIPTION

MIDI::Track provides a constructor and methods for objects
representing a MIDI track.  It is part of the MIDI suite.

MIDI tracks have, currently, three attributes: a type, events, and
data.  Almost all tracks you'll ever deal with are of type "MTrk", and
so this is the type by default.  Events are what make up an MTrk
track.  If a track is not of type MTrk, or is an unparsed MTrk, then
it has (or better have!) data.

When an MTrk track is encoded, if there is data defined for it, that's
what's encoded (and "encoding data" means just passing it thru
untouched).  Note that this happens even if the data defined is ""
(but it won't happen if the data is undef).  However, if there's no
data defined for the MTrk track (as is the general case), then the
track's events are encoded, via a call to C<MIDI::Event::encode>.

(If neither events not data are defined, it acts as a zero-length
track.)

If a non-MTrk track is encoded, its data is encoded.  If there's no
data for it, it acts as a zero-length track.

In other words, 1) events are meaningful only in an MTrk track, 2) you
probably don't want both data and events defined, and 3) 99.999% of
the time, just worry about events in MTrk tracks, because that's all
you ever want to deal with anyway.

=head1 CONSTRUCTOR AND METHODS

MIDI::Track provides...

=over

=cut

###########################################################################

=item the constructor MIDI::Track->new({ ...options... })

This returns a new track object.  By default, the track is of type
MTrk, which is probably what you want.  The options, which are
optional, is an anonymous hash.  There are four recognized options:
C<data>, which sets the data of the new track to the string provided;
C<type>, which sets the type of the new track to the string provided;
C<events>, which sets the events of the new track to the contents of
the list-reference provided (i.e., a reference to a LoL -- see
L<perllol> for the skinny on LoLs); and C<events_r>, which is an exact
synonym of C<events>.

=cut

sub new {
  # make a new track.
  my $class = shift;
  my $this = bless( {}, $class );
  print "New object in class $class\n" if $Debug;
  $this->_init( @_ );
  return $this;
}

sub _init {
  # You can specify options:
  #  'event' => [a list of events],  AKA 'event_r'
  #  'type'  => 'Whut', # default is 'MTrk'
  #  'data'  => 'scads of binary data as you like it'
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

  $this->{'type'} =
    defined($options_r->{'type'}) ? $options_r->{'type'} : 'MTrk';
  $this->{'data'} = $options_r->{'data'}
    if defined($options_r->{'data'});

  $options_r->{'events'} = $options_r->{'events_r'}
    if( exists( $options_r->{'events_r'} ) and not
	exists( $options_r->{'events'} )
      );
  # so events_r => [ @events ] is a synonym for 
  #    events   => [ @events ]
  # as on option for new()

  $this->{'events'} =
    ( defined($options_r->{'events'})
      and ref($options_r->{'events'}) eq 'ARRAY' )
    ? $options_r->{'events'} : []
  ;
  return;
}

=item the method $new_track = $track->copy

This duplicates the contents of the given track, and returns
the duplicate.  If you are unclear on why you may need this function,
consider:

          $funk  = MIDI::Opus->new({'from_file' => 'funk1.mid'});
          $samba = MIDI::Opus->new({'from_file' => 'samba1.mid'});
          
          $bass_track = ( $funk->tracks )[-1]; # last track
          push(@{ $samba->tracks_r }, $bass_track );
               # make it the last track
          
          &funk_it_up(  ( $funk->tracks )[-1]  );
               # modifies the last track of $funk
          &turn_it_out(  ( $samba->tracks )[-1]  );
               # modifies the last track of $samba
          
          $funk->write_to_file('funk2.mid');
          $samba->write_to_file('samba2.mid');
          exit;

So you have your routines funk_it_up and turn_it_out, and they each
modify the track they're applied to in some way.  But the problem is that
the above code probably does not do what you want -- because the last
track-object of $funk and the last track-object of $samba are the
I<same object>.  An object, you may be surprised to learn, can be in
different opuses at the same time -- which is fine, except in cases like
the above code.  That's where you need to do copy the object.  Change
the above code to read:

          push(@{ $samba->tracks_r }, $bass_track->copy );

and what you want to happen, will.

Incidentally, this potential need to copy also occurs with opuses (and
in fact any reference-based data structure, altho opuses and tracks
should cover almost all cases with MIDI stuff), which is why there's
$opus->copy, for copying entire opuses.

(If you happen to need to copy a single event, it's just $new = [@$old] ;
and if you happen to need to copy an event structure (LoL) outside of a
track for some reason, use MIDI::Event::copy_structure.)

=cut

sub copy {
  # Duplicate a given track.  Even dupes the events.
  # Call as $new_one = $track->copy
  my $track = shift;

  my $new = bless( { %{$track} }, ref $track );
  # a first crude dupe
  $new->{'events'} = &MIDI::Event::copy_structure( $new->{'events'} )
    if $new->{'events'};
  return $new;
}

###########################################################################

=item track->skyline({ ...options... })

skylines the entire track.  Modifies the track.  See MIDI::Score for
documentation on skyline

=cut

sub skyline {
    my $track = shift;
    my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};
    my $score_r = MIDI::Score::events_r_to_score_r($track->events_r);
    my $new_score_r = MIDI::Score::skyline($score_r,$options_r);
    my $events_r = MIDI::Score::score_r_to_events_r($new_score_r);
    $track->events_r($events_r);
}

###########################################################################
# These three modify all the possible attributes of a track

=item the method $track->events( @events )

Returns the list of events in the track, possibly after having set it
to @events, if specified and not empty.  (If you happen to want to set
the list of events to an empty list, for whatever reason, you have to use
"$track->events_r([])".)

In other words: $track->events(@events) is how to set the list of events
(assuming @events is not empty), and @events = $track->events is how to
read the list of events.

=cut

sub events { # list or set events in this object
  my $this = shift;
  $this->{'events'} = [ @_ ] if @_;
  return @{ $this->{'events'} };
}

=item the method $track->events_r( $event_r )

Returns a reference to the list of events in the track, possibly after
having set it to $events_r, if specified.  Actually, "$events_r" can be
any listref to a LoL, whether it comes from a scalar as in
C<$some_events_r>, or from something like C<[@events]>, or just plain
old C<\@events>

Originally $track->events was the only way to deal with events, but I
added $track->events_r to make possible 1) setting the list of events
to (), for whatever that's worth, and 2) so you can directly
manipulate the track's events, without having to I<copy> the list of
events (which might be tens of thousands of elements long) back
and forth.  This way, you can say:

          $events_r = $track->events_r();
          @some_stuff = splice(@$events_r, 4, 6);

But if you don't know how to deal with listrefs outside of LoLs,
that's OK, just use $track->events.

=cut

sub events_r {
  # return (maybe set) a list-reference to the event-structure for this track
  my $this = shift;
  if(@_) {
    croak "parameter for MIDI::Track::events_r must be an array-ref"
      unless ref($_[0]);
    $this->{'events'} = $_[0];
  }
  return $this->{'events'};
}

=item the method $track->type( 'MFoo' )

Returns the type of $track, after having set it to 'MFoo', if provided.
You probably won't ever need to use this method, other than in
a context like:

          if( $track->type eq 'MTrk' ) { # The usual case
            give_up_the_funk($track);
          } # Else just keep on walkin'!

Track types must be 4 bytes long; see L<MIDI::Filespec> for details.

=cut

sub type {
  my $this = shift;
  $this->{'type'} = $_[0] if @_; # if you're setting it
  return $this->{'type'};
}

=item the method $track->data( $kooky_binary_data )

Returns the data from $track, after having set it to
$kooky_binary_data, if provided -- even if it's zero-length!  You
probably won't ever need to use this method.  For your information,
$track->data(undef) is how to undefine the data for a track.

=cut

sub data {
  # meant for reading/setting generally non-MTrk track data
  my $this = shift;
  $this->{'data'} = $_[0] if @_;
  return $this->{'data'};
}

###########################################################################

=item the method $track->new_event('event', ...parameters... )

This adds the event ('event', ...parameters...) to the end of the
event list for $track.  It's just sugar for:

          push( @{$this_track->events_r}, [ 'event', ...params... ] )

If you want anything other than the equivalent of that, like some
kinda splice(), then do it yourself with $track->events_r or
$track->events.

=cut

sub new_event {
  # Usage:
  #  $this_track->new_event('text_event', 0, 'Lesbia cum Prono');

  my $track = shift;
  push( @{$track->{'events'}}, [ @_ ] );
  # this returns the new number of events in that event list, if that
  # interests you.
}

###########################################################################

=item the method $track->dump({ ...options... })

This dumps the track's contents for your inspection.  The dump format
is code that looks like Perl code that you'd use to recreate that track.
This routine outputs with just C<print>, so you can use C<select> to
change where that'll go.  I intended this to be just an internal
routine for use only by the method MIDI::Opus::dump, but I figure it
might be useful to you, if you need to dump the code for just a given
track.
Read the source if you really need to know how this works.

=cut

sub dump { # dump a track's contents
  my $this = $_[0];
  my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};
  my $type = $this->type;

  my $indent = '    ';
  my @events = $this->events;
  print(
	$indent, "MIDI::Track->new({\n",
	$indent, "  'type' => ", &MIDI::_dump_quote($type), ",\n",
	defined($this->{'data'}) ?
	  ( $indent, "  'data' => ",
	    &MIDI::_dump_quote($this->{'data'}), ",\n" )
	  : (),
	$indent, "  'events' => [  # ", scalar(@events), " events.\n",
       );
  foreach my $event (@events) {
    &MIDI::Event::dump(@$event);
    # was: print( $indent, "    [", &MIDI::_dump_quote(@$event), "],\n" );
  }
  print( "$indent  ]\n$indent}),\n$indent\n" );
  return;
}

###########################################################################

# CURRENTLY UNDOCUMENTED -- no end-user ever needs to call this as such
#
sub encode { # encode a track object into track data (not a chunk)
  # Calling format:
  #  $data_r = $track->encode( { .. options .. } )
  # The (optional) argument is an anonymous hash of options.
  # Returns a REFERENCE to track data.
  #
  my $track  = $_[0];
  croak "$track is not a track object!" unless ref($track);
  my $options_r = ref($_[1]) eq 'HASH' ? $_[1] : {};

  my $data = '';

  if( exists( $track->{'data'} )  and  defined( $track->{'data'} ) ) {
    # It might be 0-length, by the way.  Might this be problematic?
    $data = $track->{'data'};
    # warn "Encoding 0-length track data!" unless length $data;
  } else { # Data is not defined for this track.  Parse the events
    if( ($track->{'type'} eq 'MTrk'  or  length($track->{'type'}) == 0)
        and defined($track->{'events'})
             # not just exists -- but DEFINED!
        and ref($track->{'events'})
    ) {
      print "Encoding ", $track->{'events'}, "\n" if $Debug;
      return
        &MIDI::Event::encode($track->{'events'}, $options_r );
    } else {
      $data = ''; # what else to do?
      warn "Spork 8851\n" if $Debug;
    }
  }
  return \$data;
}
###########################################################################

# CURRENTLY UNDOCUMENTED -- no end-user ever needs to call this as such
#
sub decode { # returns a new object, but doesn't accept constructor syntax
  # decode track data (not a chunk) into a new track object
  # Calling format:
  #  $new_track = 
  #   MIDI::Track::decode($type, \$track_data, { .. options .. })
  # Returns a new track_object.
  # The anonymous hash of options is, well, optional

  my $track = MIDI::Track->new();

  my ($type, $data_r, $options_r)  = @_[0,1,2];
  $options_r = {} unless ref($options_r) eq 'HASH';

  die "\$_[0] \"$_[0]\" is not a data reference!"
    unless ref($_[1]) eq 'SCALAR';

  $track->{'type'} = $type;
  if($type eq 'MTrk' and not $options_r->{'no_parse'}) {
    $track->{'events'} =
      &MIDI::Event::decode($data_r, $options_r);
        # And that's where all the work happens
  } else {
    $track->{'data'} = $$data_r;
  }
  return $track;
}

###########################################################################

=back

=head1 COPYRIGHT 

Copyright (c) 1998-2002 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org> (until 2010)

Darrell Conklin C<conklin@cpan.org> (from 2010)

=cut

1;

__END__
