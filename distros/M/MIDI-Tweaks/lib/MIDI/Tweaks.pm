#! perl

package MIDI::Tweaks;

use warnings;
use strict;

=head1 NAME

MIDI::Tweaks - Enhancements to MIDI.pm.

=cut

our $VERSION = '1.01';

use MIDI;
use Carp;

# These are valid for all events.
use constant EV_TYPE	     => 0;
use constant EV_TIME	     => 1;
# These are for events that apply to a channel only.
use constant EV_CHAN	     => 2;
# These are for note events.
use constant EV_NOTE_PITCH   => 3;
use constant EV_NOTE_VELO    => 4;
# These if for track_name events.
use constant EV_MARKER_NAME  => 2;

# Drum channel
use constant MIDI_CHAN_PERCUSSION => 10;

use base qw(Exporter);

our @EXPORT;
our @EXPORT_OK;

BEGIN {
    @EXPORT = qw(EV_TYPE EV_TIME EV_CHAN EV_NOTE_PITCH EV_NOTE_VELO EV_MARKER_NAME);
    @EXPORT_OK = qw(is_note_event is_note_on is_note_off is_channel_event);
}

=head1 SYNOPSIS

This module implements a number of MIDI tweaks using the Sean Burke's
MIDI module.

    # Read midi data.
    my $op = new MIDI::Tweaks::Opus ({ from_file => "orig.mid" });

    # Reset all volume controls.
    $_->change_volume({ value => 100 }) foreach $op->tracks;

    # Slowdown a bit.
    $op->change_tempo({ ratio => 0.9 });

    # Prepare the individual tracks.
    my $track0  = $op->tracks_r->[0];
    my $acc	= $op->tracks_r->[1]->change_velocity({ value =>  30 });
    my $solo    = $op->tracks_r->[2]->change_velocity({ value => 110 });
    my $high    = $op->tracks_r->[3]->change_velocity({ value => 100 });
    my $low	= $op->tracks_r->[4]->change_velocity({ value => 100 });

    # $low contains the middle + lower parts. Split.
    (my $mid, $low) = $low->split_hilo;

    # Produce a midi for low voice only.
    $op->tracks($track0, $acc, $low);
    $op->write_to_file("low.mid");


Warning: This module is still under development. The interface to the
methods may change when new features are added.

Two scripts are provided when installing this module:

  midi-tweak: applies some tweaks to MIDI files

  midi-dump: dumps contents of a MIDI file in an understandable format

=head1 CONSTANTS

The following constants will be exported by default.

=head2 EV_TYPE

The offset in an event (array ref) of the type information.

=head2 EV_TIME

The offset in an event (array ref) of the delta time.

=head2 EV_CHAN

The offset in an event (array ref) of the channel.

=head2 EV_NOTE_PITCH

The offset in a note event of the pitch.

=head2 EV_NOTE_VELO

The offset in a note event of the velocity.

=head2 EV_MARKER_NAME

The offset in a marker event of the name.

=head1 FUNCTIONS

The following functions can be exported on demand.

=head2 MIDI::Tweaks::is_note_event

Function. Takes an event (array reference) as argument.
Returns true if the event is a 'note on' or 'note off' event.

=cut

sub is_note_event {
    my ($e) = shift;
    $e->[EV_TYPE] =~ /^note_o(n|ff)$/;
}

=head2 MIDI::Tweaks::is_note_on

Function. Takes an event (array reference) as argument.
Returns true if the event is a 'note on' event with a non-zero velocity.

=cut

sub is_note_on {
    my ($e) = shift;
    $e->[EV_TYPE] eq 'note_on' && $e->[EV_NOTE_VELO];
}

=head2 MIDI::Tweaks::is_note_off

Function. Takes an event (array reference) as argument.
Returns true if the event is a 'note off' event, or a 'note on' event
with zero velocity.

=cut

sub is_note_off {
    my ($e) = shift;
    $e->[EV_TYPE] eq 'note_off'
      || $e->[EV_TYPE] eq 'note_on' && !$e->[EV_NOTE_VELO];
}

=head2 MIDI::Tweaks::is_channel_event

Function. Takes an event (array reference) as argument.
Returns true if the event aqpplies to specific channel.

=cut

my $evpat;
INIT {
    $evpat = qr/^
		  note_off
		| note_on
		| key_after_touch
		| control_change
		| patch_change
		| channel_after_touch
		| pitch_wheel_change
		$/x;
}

sub is_channel_event {
    my ($e) = shift;
    $e->[EV_TYPE] =~ $evpat;
}

=head1 OPUS METHODS

=cut

package MIDI::Tweaks::Opus;

use strict;
use warnings;
use base qw(MIDI::Opus);
use MIDI::Tweaks;
use Carp;

=head2 MIDI::Tweaks::Opus::new

Method. Does whatever MIDI::Opus::new does, but checks for sanity and
produces an Opus with absolute time stamps.

The options hash may contain a key C<require_sanity> that controls the
level of sanity checking:

  0:    no checking
  1:    normal checking
  warn: normal checking, but warn instead of die

=cut

sub new {
    my $pkg = shift;

    my $args = $_[0] ? { %{$_[0]} } : {};
    my $require_sanity = delete($args->{require_sanity});
    $require_sanity = 1 unless defined $require_sanity;

    my $op = $pkg->SUPER::new($args);

    $op->delta2time;
    $op->check_sanity({ strict => $require_sanity }) if $require_sanity;

    return $op;
}

=head2 MIDI::Tweaks::Opus::write_to_handle

Method. Copies the Opus, converts the time stamps to delta times and
passes the result to MIDI::Opus::write_to_handle.

Note that this method is used internally by write_to_file.

=cut

sub write_to_handle {
    my $op = shift->copy;
    $op->time2delta;
    $op->SUPER::write_to_handle(@_);
}

=head2 MIDI::Tweaks::Opus::dump

Method. Copies the Opus, converts the time stamps to delta times and
passes the result to MIDI::Opus::dump.

=cut

sub dump {
    my $op = shift->copy;
    $op->time2delta;
    $op->SUPER::dump(@_);
}

=head2 MIDI::Tweaks::Opus::check_sanity

Method, internal. Verifies that the MIDI data obeys certain criteria
that make it suitable for tweaking. In particular, there must be a
one-to-one relationship between tracks and channels.

This method is called internally by the MIDI::Tweaks::Opus::new method.

=cut

sub check_sanity {
    my ($self, $args) = @_;
    $args ||= {};

    my $strict = 1;
    if ( $args->{strict} ) {
	$strict = delete $args->{strict};	# 1, or 'warn'
    }

    my @channel_seen;
    my $fail;
    my $tn = 1;
    foreach my $track ( $self->tracks ) {
	my $chan;
	my $noteon;
	foreach ( $track->events ) {
	    next unless MIDI::Tweaks::is_channel_event($_);
	    if ( defined $chan ) {
		if ( $_->[EV_CHAN] != $chan ) {
		    carp("Sanity check: track $tn controls channels ",
			 $chan+1,
			 " and ",
			 $_->[EV_CHAN]+1);
		    $fail++;
		}
	    }
	    else {
		$chan = $_->[EV_CHAN];
		if ( $channel_seen[$chan] ) {
		    carp("Sanity check: channel ",
			 $chan+1,
			 " is controlled by tracks ",
			 $channel_seen[$chan],
			 " and $tn");
		    $fail++;
		}
		$channel_seen[$chan] = $tn;
	    }
	    if ( MIDI::Tweaks::is_note_on($_) ) {
		if ( defined $noteon->[$_->[EV_NOTE_PITCH]] ) {
		    carp("Sanity warning: track $tn, time $_->[EV_TIME], "
			 . "note $_->[EV_NOTE_PITCH] already on (since "
			 . $noteon->[$_->[EV_NOTE_PITCH]] . ")");
		}
		else {
		    $noteon->[$_->[EV_NOTE_PITCH]] = $_->[EV_TIME];
		}
	    }
	    elsif ( MIDI::Tweaks::is_note_off($_) ) {
		if ( defined $noteon->[$_->[EV_NOTE_PITCH]] ) {
		    $noteon->[$_->[EV_NOTE_PITCH]] = undef;
		}
		else {
		    carp("Sanity warning: track $tn, time $_->[EV_TIME], "
			 . "note $_->[EV_NOTE_PITCH] not on");
		}
	    }
	}
	foreach my $i ( 0 .. $#{$noteon} ) {
	    next unless defined $noteon->[$i];
	    carp("Sanity check: track $tn, "
		 . "unfinished note $i (on since $noteon->[$i])");
	    $fail++;
	}
	$tn++;
    }
    if ( $fail ) {
	return if $strict eq 'warn';
	croak("Sanity check failed");
    }
    return 1;
}

=head2 MIDI::Tweaks::Opus::delta2time

Method, internal. Modifies the Opus by changing the delta times of all
events of all tracks to an absolute time value.

This method is called internally by the MIDI::Tweaks::Opus::new method.

THIS MAKES THE OPUS NO LONGER DIRECTLY VALID FOR MIDI. When this
method has been applied to an Opus it should be undone later by a call
to time2delta. This is handled transparently by the
MIDI::Tweaks::Opus::write_to_file and MIDI::Tweaks::Opus::dump
methods.

=cut

sub delta2time {
    my ($self) = @_;
    foreach my $track ( $self->tracks ) {
	$track->delta2time;
    }
}

=head2 MIDI::Tweaks::Opus::time2delta

Method, internal. Modifies the Opus by making all time events relative
(delta times).

This method undoes the effect of a previous delta2time, making the
Opus valid MIDI data again.

This method is called internally by MIDI::Tweaks::Opus::write_to_file and
MIDI::Tweaks::Opus::dump methods.

=cut

sub time2delta {
    my ($self) = @_;
    foreach my $track ( $self->tracks ) {
	$track->time2delta;
    }
}

=head2 MIDI::Tweaks::Opus::change_pitch

Method. One argument, the options hash.

Modifies the pitch of the Opus.

This method just calls MIDI::Track::change_pitch on all tracks. See
L<MIDI::Track::change_pitch> for details. It skips the track
associated with channel 9 which is typically associated with
percussion.

=cut

sub change_pitch {
    my $self = shift;
    foreach my $track ( $self->tracks ) {
	next if $track->channel == MIDI::Tweaks::MIDI_CHAN_PERCUSSION; # skip drums
	$track->change_pitch(@_);
    }
}

=head2 MIDI::Tweaks::Opus::change_tempo

Method. One argument, the options hash.

Modifies the tempo settings of the Opus.

The options has must contain either C<< value => number >> or C<<
ratio => number >>. In the first case, the tempo is set to the
specified value (beats per minute). In the second case, the tempo is
changed according to the ratio.

=cut

sub change_tempo {
    my $self = shift;
    foreach my $track ( $self->tracks ) {
	$track->change_tempo(@_);
    }
}

# We need to override MIDI::Opus::dump for this to work...

no warnings qw(redefine once);

sub MIDI::Opus::dump { # method; read-only
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

  # This is the only change to the original code: replace the
  # hard-wired class name MIDI::Opus with ref($this), so derived
  # classes work.
  # WAS: print "MIDI::Opus->new({\n",
  # IS NOW:
  print ref($this), "->new({\n",
  # End of change.
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

=head1 TRACK METHODS

=cut

# We cannot use package MIDI::Track, since that is owbed by MIDI.pm.
package MIDI::Tweaks;

use strict;
use warnings;
use Carp;

=head2 MIDI::Track::name

Method. Returns the first track name as designated by an 'track name' event.
If none was found, returns undef.

=cut

sub MIDI::Track::name {
    my $track = shift;
    foreach my $e ( $track->events ) {
	return $e->[EV_MARKER_NAME]
	  if $e->[EV_TYPE] eq 'track_name';
    }
    return;
}

=head2 MIDI::Track::channel

Method. Returns the channel controlled by this track.
If none was found, returns zero.

Note that channels are numbered from one, as per MIDI standard.

=cut

sub MIDI::Track::channel {
    my $track = shift;
    foreach my $e ( $track->events ) {
	next unless MIDI::Tweaks::is_channel_event($e);
	return $e->[EV_CHAN] + 1;
    }
    return 0;
}

=head2 MIDI::Track::delta2time

Method, internal. Modifies the track by changing the delta times of
all events to an absolute time value.

THIS MAKES THE TRACK NO LONGER VALID FOR MIDI. When this method has
been applied to a track it should be undone later by a call to
time2delta.

=cut

sub MIDI::Track::delta2time {
    my ($self, $force) = @_;

    if ( $self->{_tweaky_abstime} ) {
	croak("MIDI::Track::delta2time: Already abstime")
	  unless $force;
    }

    my $time = 0;		# time until now
    foreach my $e ( $self->events ) {
	$time = $e->[EV_TIME] += $time;
    }

    $self->{_tweaky_abstime} = 1;

    # For convenience:
    return $self;
}

=head2 MIDI::Track::time2delta

Method, internal. Modifies the track by making all time events
relative (delta times).

This method undoes the effect of a previous delta2time, making the
track valid MIDI data again.

=cut

sub MIDI::Track::time2delta {
    my ($self, $force) = @_;

    unless ( $self->{_tweaky_abstime} ) {
	croak("MIDI::Track::delta2time: Already delta time")
	  unless $force;
    }

    my $time = 0;		# time until now
    foreach my $e ( $self->events ) {
	carp("NEGATIVE DELTA \@ $time: @{[$e->[EV_TIME]-$time]}\n")
	  if $e->[EV_TIME] < $time;
	# Make time relative.
	($time, $e->[EV_TIME]) = ($e->[EV_TIME], $e->[EV_TIME]-$time);
    }

    delete $self->{_tweaky_abstime};

    # For convenience:
    return $self;
}

=head2 MIDI::Track::has_deltatime

Method, internal. Returns true if the track events have delta time
stamps.

This method is not fail safe, i.e., it can return thw wrong result if
a track does not have sensible events.

=cut

sub MIDI::Track::has_deltatime {
    my ($self) = @_;
    my $time = 0;
    foreach my $e ( $self->events ) {
	return 1 if $e->[EV_TIME] < $time;
	$time = $e->[EV_TIME];
    }
    return;
}

=head2 MIDI::Track::mapper

Method. One or two arguments.
First argument is optional: an options hash.
Second, or only, argument must be a code ref.

Applies to code ref to all events of
the track. Returns the track (for convenience);

Note that if the code ref modifies the event, this actually modifies
the track. If this is not desired, copy it first, or use
C<< copy => 1 >> in the options hash.

The code ref gets two arguments, the event (an array ref), and the
remainder of the options hash.

Examples:

   $track->mapper(sub { print $_->[0] });
   $new = $track->mapper({ copy => 1 },
                         sub { $_->[1] += 10 });

=cut

sub MIDI::Track::mapper {
    my $track = shift;

    my $opts = {};
    $opts = {%{shift()}} if ref($_[0]) eq 'HASH';

    my $mapper = shift;
    croak("MIDI::Track::mapper requires a CODE argument")
      unless ref($mapper) eq 'CODE';

    $track = $track->copy if delete $opts->{copy};

    foreach ( $track->events ) {
	$mapper->($_, $opts);
    }

    $track;
}

=head2 MIDI::Track::change_pitch

Method. One argument, the options hash.

Changes the pitch of each 'note on' event according to the options.

The options has must contain C<< int => number >>. The number
indicates the number of half-tones the pitch should be raised. A
negative number will lower the pitch.
Any remaining options are passed to the mapper function.

Note that key signatures will be changed as well.

=cut

sub MIDI::Track::change_pitch {
    my ($track, $args) = @_;
    croak("MIDI::Track::change_pitch requires a HASH argument")
      unless ref($args) eq 'HASH';
    $args = {%$args};

    my $mapper_func;
    #         C   Db  D   Es  E   F   Gb  G   As  A   Bb  B
    my @k = ( 0, -5,  2, -3,  4, -1, -6,  1, -4,  3, -2,  5);
    my %k; $k{$k[$_]} = $_ for 0 .. $#k;

    if ( $args->{int} ) {
	my $value = int(delete $args->{int});

	$mapper_func = sub {
	    if ( MIDI::Tweaks::is_note_event($_[0]) ) {
		$_[0]->[EV_NOTE_PITCH] += $value;
		croak("MIDI::Track::change_pitch: transposed pitch out of range")
		  unless $_[0]->[EV_NOTE_PITCH] >= 0 && $_[0]->[EV_NOTE_PITCH] <= 127;
		return;
	    }
	    if ( $_[0]->[0] eq 'key_signature' ) {
		# Warning: ugly code ahead.
		# This is expected to be run only a few times.
		# Don't spent much effort on elegance and optimizing.
		my $f = $_[0]->[2];	 # current #sharps
		$f -= 12 if $f >= 6;	 # normalize
		$f += 12 if $f < -6;
		$f = $k{$f};		 # get note
		$f += $value;		 # transpose
		$f -= 12 while $f >= 12; # normalize
		$f += 12 while $f < 0;
		$_[0]->[2] = $k[$f];	 # get #sharps
		return;
	    }
	};
    }

    croak("MIDI::Track::change_pitch: Missing 'value' or 'ratio' option")
      unless $mapper_func;

    $track->mapper($args, $mapper_func);
}

=head2 MIDI::Track::change_velocity

Method. One argument, the options hash.

Changes the velocity of each 'note on' event according to the options.

The options has must contain either C<< value => number >> or
C<< ratio => number >>. In the first case, the velocity is set to the
specified value (which must be a number between 0 and 127). In the
second case, the velocity is changed according to the ratio.

Any remaining options are passed to the mapper function.

Note that setting the velocity to zero effectively turns the 'note on'
events into 'note off' events.

Also note that tracks usually have an initial 'control_change' event
that controls the overall volume for a channel. Use change_volume to
change this setting.

=cut

sub MIDI::Track::change_velocity {
    my ($track, $args) = @_;
    croak("MIDI::Track::change_velocity requires a HASH argument")
      unless ref($args) eq 'HASH';
    $args = {%$args};

    my $mapper_func;

    if ( $args->{value} ) {
	my $value = int(delete $args->{value});
	croak("MIDI::Track::change_velocity: value should be between 0 and 127")
	  unless $value >= 0 && $value <= 127;

	$mapper_func = sub {
	    return unless MIDI::Tweaks::is_note_on($_[0]);
	    $_[0]->[EV_NOTE_VELO] = $value;
	};
    }
    elsif ( $args->{ratio} ) {
	my $ratio = delete $args->{ratio};
	$mapper_func = sub {
	    return unless MIDI::Tweaks::is_note_on($_[0]);
	    $_[0]->[EV_NOTE_VELO] = int($_[0]->[EV_NOTE_VELO] * $ratio);
	    $_[0]->[EV_NOTE_VELO] = 127 if $_[0]->[EV_NOTE_VELO] > 127;
	};
    }

    croak("MIDI::Track::change_velocity: Missing 'value' or 'ratio' option")
      unless $mapper_func;

    $track->mapper($args, $mapper_func);
}

=head2 MIDI::Track::change_tempo

Method. One argument, the options hash.

Changes the tempo of a trackaccording to the options.

The options has must contain either C<< value => number >> or C<<
ratio => number >>. In the first case, each occurence of a tempo event
is changed to the specified value. In the second case, the tempo is
changed according to the ratio.

Any remaining options are passed to the mapper function.

Note that usually track 0 controls the tempi for an opus.

=cut

sub MIDI::Track::change_tempo {
    my ($track, $args) = @_;
    croak("MIDI::Track::change_tempo requires a HASH argument")
      unless ref($args) eq 'HASH';
    $args = {%$args};

    my $mapper_func;

    if ( $args->{value} ) {
	my $value = int(60000000 / int(delete $args->{value}));

	$mapper_func = sub {
	    return unless $_[0]->[0] eq 'set_tempo';
	    $_[0]->[2] = $value;
	};
    }
    elsif ( $args->{ratio} ) {
	my $ratio = delete $args->{ratio};
	$mapper_func = sub {
	    return unless $_[0]->[0] eq 'set_tempo';
	    $_[0]->[2] = int($_[0]->[2] / $ratio);
	};
    }

    croak("MIDI::Track::change_tempo: Missing 'value' or 'ratio' option")
      unless $mapper_func;

    $track->mapper($args, $mapper_func);
}

=head2 MIDI::Track::change_volume

Method. One argument, the options hash.

Changes the volume of the channel.

The options has must contain either C<< value => number >> or
C<< ratio => number >>. In the first case, the volume is set to the
specified value (which must be a number between 0 and 127). In the
second case, the volume is changed according to the ratio.

Any remaining options are passed to the mapper function.

=cut

sub MIDI::Track::change_volume {
    my ($track, $args) = @_;
    croak("MIDI::Track::change_volume requires a HASH argument")
      unless ref($args) eq 'HASH';
    $args = {%$args};

    my $mapper_func;

    if ( $args->{value} ) {
	my $value = int(delete $args->{value});
	croak("MIDI::Track::change_volume: value should be between 0 and 127")
	  unless $value >= 0 && $value <= 127;

	$mapper_func = sub {
	    return unless
	      $_[0]->[0] eq 'control_change'
	      && $_[0]->[3] == 7;
	    $_[0]->[4] = $value;
	};
    }
    elsif ( $args->{ratio} ) {
	my $ratio = delete $args->{ratio};
	$mapper_func = sub {
	    return unless
	      $_[0]->[0] eq 'control_change'
	      && $_[0]->[3] == 7;
	    $_[0]->[4] = int($_[0]->[4] * $ratio);
	    $_[0]->[4] = 127 if $_[0]->[4] > 127;
	};
    }

    croak("MIDI::Track::change_volume: Missing 'value' or 'ratio' option")
      unless $mapper_func;

    $track->mapper($args, $mapper_func);
}

=head2 MIDI::Track::split_pitch

Method. One argument, the options hash.

The track is split into two tracks, depending on whether the pitch of
a note event is lower than a preset value. Non-note events are copied
to both tracks.

The options hash may contain C<< pitch => number >> to specify the
pitch value to split on. All notes whose pitches are less than the
split value are copied to the lower track, all other notes are copied
to the upper track.

Default value is 56. This is a suitable value to split a single MIDI
track containing a piano part into left hand and right hand tracks.

All events are copied, and the track is not modified.

This method returns a list, the higher track and the lower track.

=cut

sub MIDI::Track::split_pitch {
    my ($track, $args) = @_;
    $args ||= {};
    croak("MIDI::Track::split_pitch requires a HASH argument")
      unless ref($args) eq 'HASH';
    $args = {%$args};

    my $split ||= 56;

    if ( $args->{pitch} ) {
	$split = delete $args->{pitch};
	croak("MIDI::Track::split_pitch: split value should be between 0 and 127")
	  unless $split >= 0 && $split <= 127;
    }

    croak("MIDI::Track::split_pitch: unknown options: ".
	  join(" ", sort keys %$args)) if %$args;

    croak("MIDI::Track::split_pitch: FATAL: track has delta times")
      unless $track->{_tweaky_abstime};

    my @hi;
    my @lo;

    foreach ( $track->events ) {
	unless ( MIDI::Tweaks::is_note_event($_) ) {
	    # Copy.
	    push(@hi, [@$_]);
	    push(@lo, [@$_]);
	    next;
	}

	if ( $_->[EV_NOTE_PITCH] >= $split ) {
	    push(@hi, [@$_]);
	}
	else {
	    push(@lo, [@$_]);
	}
    }

    my $hi = MIDI::Track->new;
    $hi->type($track->type);
    $hi->events(@hi);
    $hi->{_tweaky_abstime} = 1;

    my $lo = MIDI::Track->new;
    $lo->type($track->type);
    $lo->events(@lo);
    $lo->{_tweaky_abstime} = 1;

    return ( $hi, $lo );
}

=head2 MIDI::Track::split_hilo

Method. No arguments.

The track is split into two tracks, high and low.

If there are two 'note on' (or 'note off') events at the same time,
the event with the highest pitch gets copied to the high track and the
other to the low track. If there's only one note, or if it is not a
note event, it gets copied to both tracks.

All events are copied, and the track is not modified.

This method returns a list (high track, low track).

NOTE: This process assumes that if there are two notes, they start and
end at the same time.

NOTE: This process discards all non-note events from the resultant
tracks. Sorry.

=cut

sub MIDI::Track::split_hilo {
    my ($track) = @_;

    croak("MIDI::Track::split_hilo: FATAL: track has delta times")
      unless $track->{_tweaky_abstime};

    my @hi;
    my @lo;
    my $eqtimes = sub { $_[0]->[EV_TIME] == $_[1]->[EV_TIME] };

    my @events = $track->events;
    while ( @events ) {
	my $this_event = shift(@events);
	my $next_event = $events[0];

	# Skip lyrics.
	next if $this_event->[EV_TYPE] =~ /^lyric$/;

	# Assert we're still in phase.
	unless ( @hi == @lo ) {
	    croak("!t1 = ", scalar(@hi), " events\n",
		  "!t2 = ", scalar(@lo), " events\n");
	}

	unless ( MIDI::Tweaks::is_note_event($this_event)
		 && @events && $eqtimes->($this_event, $next_event) ) {
	    # Copy.
	    push(@hi, [@$this_event]);
	    push(@lo, [@$this_event]);
	    next;
	}

	if ( MIDI::Tweaks::is_note_on($this_event)
	     && MIDI::Tweaks::is_note_on($next_event)
	     or
	     MIDI::Tweaks::is_note_off($this_event)
	     && MIDI::Tweaks::is_note_off($next_event) ) {

	    # Remove from events.
	    shift(@events);

	    if ( $this_event->[EV_NOTE_PITCH] > $next_event->[EV_NOTE_PITCH] ) {
		push(@hi, [@$this_event]);
		push(@lo, [@$next_event]);
	    }
	    else {
		push(@hi, [@$next_event]);
		push(@lo, [@$this_event]);
	    }
	}
	else {
	    # Not a multi-note, copy.
	    push(@hi, [@$this_event]);
	    push(@lo, [@$this_event]);
	}
    }

    my $hi = MIDI::Track->new;
    $hi->type($track->type);
    $hi->events(@hi);
    $hi->{_tweaky_abstime} = 1;

    my $lo = MIDI::Track->new;
    $lo->type($track->type);
    $lo->events(@lo);
    $lo->{_tweaky_abstime} = 1;

    return ( $hi, $lo );
}

=head2 MIDI::Track::split_hml

Method. No arguments.

The track is split into three tracks, high, middle and low.

If there are three 'note on' (or 'note off') events at the same time,
the event with the highest pitch gets copied to the high track, the
event with the lowest pitch gets copied to the low track, and the
other to the middle track.

If there are two 'note on' (or 'note off') events at the same time,
the event with the highest pitch gets copied to the high track and the
other to the middle and low tracks.

If there's only one note event at that time, or if it is not a note
event, it gets copied to all tracks.

All events are copied, and the track is not modified.

This method returns a list (high track, middle track, low track).

NOTE: This process assumes that if there are two or three notes, they
start and end at the same time.

NOTE: This process discards all non-note events from the resultant
tracks. Sorry.

=cut

sub MIDI::Track::split_hml {
    my ($track) = @_;

    croak("MIDI::Track::split_hml: FATAL: track has delta times")
      unless $track->{_tweaky_abstime};

    my @hi;
    my @md;
    my @lo;
    my $eqtimes = sub { $_[0]->[EV_TIME] == $_[1]->[EV_TIME] };

    my @events = $track->events;
    my $time = 0;

    while ( @events ) {
	my $this_event = shift(@events);
	my $next_event = $events[0];
	next if $this_event->[EV_TYPE] =~ /^lyric$/;

	unless ( @hi == @md && @md == @lo ) {
	    croak("!t1 = ", scalar(@hi), " events\n",
		  "!t2 = ", scalar(@md), " events\n",
		  "!t3 = ", scalar(@lo), " events\n");
	}

	$time = $this_event->[EV_TIME];

	if ( MIDI::Tweaks::is_note_event($this_event) ) {
	    # Check if there's a note already at this time.
	    if ( MIDI::Tweaks::is_note_on($this_event)
		 && @events && MIDI::Tweaks::is_note_on($next_event)
		 && $eqtimes->($this_event, $next_event) ) {
		if ( MIDI::Tweaks::is_note_on($events[1])
		     && $eqtimes->($this_event, $events[1]) ) {
		    # Remove next from events.
		    shift(@events);
		    # Store higher in hi, lower in md, etc.
		    # (also removes afternext from events)
		    my @a = sort {
			$b->[EV_NOTE_PITCH] <=> $a->[EV_NOTE_PITCH]
		    } ( [@$this_event], [@$next_event], [@{shift(@events)}] );
		    push(@hi, $a[0]);
		    push(@md, $a[1]);
		    push(@lo, $a[2]);
		}
		else {
		    # Remove next from events.
		    shift(@events);
		    my @a = sort {
			$b->[EV_NOTE_PITCH] <=> $a->[EV_NOTE_PITCH]
		    } ( [@$this_event], [@$next_event] );
		    push(@hi, $a[0]);
		    push(@md, $a[1]);
		    push(@lo, $a[1]);
		}
		$hi[-1]->[EV_TIME] = $time;
		$md[-1]->[EV_TIME] = $time;
		$lo[-1]->[EV_TIME] = $time;
	    }
	    elsif ( MIDI::Tweaks::is_note_off($this_event)
		    && @events && MIDI::Tweaks::is_note_off($next_event)
		    && $eqtimes->($this_event, $next_event) ) {
		if ( MIDI::Tweaks::is_note_off($events[1])
		     && $eqtimes->($this_event, $events[1]) ) {
		    # Remove next from events.
		    shift(@events);
		    # Store higher in hi, lower in md, etc.
		    # (also removes afternext from events)
		    my @a = sort {
			$b->[EV_NOTE_PITCH] <=> $a->[EV_NOTE_PITCH]
		    } ( [@$this_event], [@$next_event], [@{shift(@events)}] );
		    push(@hi, $a[0]);
		    push(@md, $a[1]);
		    push(@lo, $a[2]);
		}
		else {
		    # Remove next from events.
		    shift(@events);
		    my @a = sort {
			$b->[EV_NOTE_PITCH] <=> $a->[EV_NOTE_PITCH]
		    } ( [@$this_event], [@$next_event] );
		    push(@hi, $a[0]);
		    push(@md, $a[1]);
		    push(@lo, $a[1]);
		}
		$hi[-1]->[EV_TIME] = $time;
		$md[-1]->[EV_TIME] = $time;
		$lo[-1]->[EV_TIME] = $time;
	    }
	    else {
		# Not a multi-note, copy.
		push(@hi, [@$this_event]);
		push(@md, [@$this_event]);
		push(@lo, [@$this_event]);
	    }
	}
	else {
	    # Not a note, copy.
	    push(@hi, [@$this_event]);
	    push(@md, [@$this_event]);
	    push(@lo, [@$this_event]);
	}
    }

    my $hi = MIDI::Track->new;
    $hi->type($track->type);
    $hi->events(@hi);
    $hi->{_tweaky_abstime} = 1;

    my $md = MIDI::Track->new;
    $md->type($track->type);
    $md->events(@md);
    $md->{_tweaky_abstime} = 1;

    my $lo = MIDI::Track->new;
    $lo->type($track->type);
    $lo->events(@lo);
    $lo->{_tweaky_abstime} = 1;

    return ( $hi, $md, $lo );
}

package main;

=head1 AUTHOR

Johan Vromans, C<< <jvromans at squirrel.nl> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-midi-tweaks at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIDI-Tweaks>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<MIDI>, L<MIDI::Opus>, L<midi-dump>, L<midi-tweak>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MIDI::Tweaks

Development of this module is hosted on GitHub:
L<https://github.com/sciurius/perl-MIDI-Tweaks>. Feel free to fork and
contribute.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008,2017 Johan Vromans, Squirrel Consultancy. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
