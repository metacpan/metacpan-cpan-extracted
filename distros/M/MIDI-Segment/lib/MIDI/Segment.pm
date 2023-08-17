# -*- Perl -*-
# a means to segment MIDI by equal duration
package MIDI::Segment;
our $VERSION = '0.03';
use 5.10.0;
use strict;
use warnings;

use constant {
    # index into MIDI::Event events
    NAME  => 0,    # note_on, etc
    DTIME => 1,    # delta time
    VELO  => 4,    # velocity (volume or loudness)

    # velocity less or equal to this will not be considered a notable
    # "note_on". this may need to be a user-supplied parameter
    MINVELO => 0,
};

sub _durations {
    my ($opus) = @_;
    my ( $maxdur, $vague ) = ( 0, 0 );
    my ( @all_onsets, @links, @track_lens );
    for my $track ( @{ $opus->tracks_r } ) {
        my @onsets = (0);
        my %onset2index;
        my $notes  = 0;
        my $when   = 0;
        my $evlist = $track->events_r;
        for my $tindex ( 0 .. $#$evlist ) {
            my $event = $evlist->[$tindex];
            # TODO may need a "minimum duration" so that too-small
            # durations are not found, but the user could also ignore
            # those when calling split
            if (    $event->[NAME] eq 'note_on'
                and $event->[VELO] > MINVELO
                and $when > $onsets[-1] ) {
                push @onsets, $when;
                $onset2index{$when} = $tindex;
                $notes = 1;
            }
            $when += $event->[DTIME];
        }
        # more complicated would be to skip these tracks, but that would
        # require a sparse list of tracks to apply the subsequent
        # calculations to
        die "no note_on in track" unless $notes;
        push @track_lens, $when;
        $maxdur = $when if $when > $maxdur;
        my $last = $evlist->[-1];
        $vague = 1
          if $last->[DTIME] == 0
          and $last->[NAME] eq 'note_on'
          and $last->[VELO] > MINVELO;
        shift @onsets;
        push @all_onsets, \@onsets;
        push @links,      \%onset2index;
    }
    # TODO can this be reached with the "no note_on in track" limitation?
    #die "no events in MIDI" if $maxdur <= 0;
    my $ragged = 0;
    if ( @track_lens > 1 ) {
        for my $i ( 1 .. $#track_lens ) {
            if ( $track_lens[0] != $track_lens[$i] ) {
                $ragged = $i;
                last;
            }
        }
    }
    return {
        links         => \@links,
        onsets        => \@all_onsets,
        opus          => $opus,
        maximum       => $maxdur,
        ragged        => $ragged,        # track lengths differ?
        segments      => [],
        track_lengths => \@track_lens,
        vague         => $vague,         # track ends on 0 dtime note_on?
    };
}

sub _possible_segments {
    my ( $max, $tracks ) = @_;
    my $half = int( $max / 2 );
    my %possible;
  TRACK: for my $onsets (@$tracks) {
        # TODO or die here, if this is reachable somehow sane
        #next unless @$onsets;
        my ( $lower, $upper ) = ( 0, $#$onsets );
        my $midpoint;
        while ( $lower <= $upper ) {
            $midpoint = ( $lower + $upper ) >> 1;
            if ( $half < $onsets->[$midpoint] ) {
                $upper = $midpoint - 1;
            } elsif ( $half > $onsets->[$midpoint] ) {
                $lower = $midpoint + 1;
            } else {
                @possible{ @{$onsets}[ 0 .. $midpoint ] } = ();
                next TRACK;
            }
        }
        @possible{ @{$onsets}[ 0 .. $midpoint - 1 ] } = ();
    }
    # and only those possible that evenly split the duration
    return [ sort { $a <=> $b } grep { $max % $_ == 0 } keys %possible ];
}

sub new {
    my ( $class, $opus ) = @_;
    my $self = _durations($opus);
    # TODO maybe user-supplied parameters could auto-correct some of
    # these cases, e.g. to extend the tracks to some duration?
    die "problematic MIDI v=$self->{vague} r=$self->{ragged}"
      if $self->{vague} or $self->{ragged};
    my $potential =
      _possible_segments( $self->{maximum}, $self->{onsets} );
  DURATION: for my $dur (@$potential) {
        my $window = $dur;
        while ( $window < $self->{maximum} ) {
            for my $links ( @{ $self->{links} } ) {
                next DURATION unless exists $links->{$window};
            }
            $window += $dur;
        }
        push @{ $self->{segments} }, $dur;
    }
    return bless( $self, $class ), $self->{segments};
}

sub split {
    my ( $self, $dur ) = @_;
    my @segtracks;
    my $links  = $self->{links};
    my $tracks = $self->{opus}->tracks_r;
    for my $tidx ( 0 .. $#$tracks ) {
        my @segments;
        my $evlist = $tracks->[$tidx]->events_r;
        my $start  = 0;
        my $window = $dur;
        my $sidx   = 0;
        while ( $window < $self->{maximum} ) {
            my $end = $links->[$tidx]{$window}
              // die "no onset at $window track $tidx";
            # TODO how create this situation for a test?
            #die "cannot end before start ($start, $end)" if $end <= $start;
            $segtracks[ $sidx++ ][$tidx] = [ @{$evlist}[ $start .. $end - 1 ] ];
            $window += $dur;
            $start = $end;
        }
        $segtracks[$sidx][$tidx] = [ @{$evlist}[ $start .. $#$evlist ] ];
    }
    return \@segtracks;
}

1;
__END__

=head1 NAME

MIDI::Segment - means to segment MIDI by equal duration

=head1 SYNOPSIS

  use MIDI;
  use MIDI::Segment;

  my $opus = MIDI::Opus->new( { from_file => 'cowbell.midi' } );

  my ( $mis, $durations ) = MIDI::Segment->new($opus);
  die "not possible to split equally" unless @$durations;

  for my $dur (@$durations) {
    my $segments = $mis->split($dur);
    warn "duration $dur has " . scalar(@$segments) . " segments\n";
    for my $seg (@$segments) {
      # deal with @$seg which are array references for each track that
      # in turn contain some number of MIDI::Event arrays ...
    }
  }

See also C<eg/melody-shuffle>.

=head1 DESCRIPTION

This module provides a means to split L<MIDI::Opus> into L<MIDI::Event>
segments of equal duration, assuming that is possible. Typical uses
would be to display the possible segments or to shuffle them into a new
composition with e.g. the B<shuffle> call in L<List::Util>.

MIDI does not contain durations; the I<dtime> or "delta time" of the
last C<note_on> event of track may be C<0>; if that C<note_on> is the
last event of the track then the duration of that note is unknown. Also
MIDI tracks may be of different durations. These cases are not handled
by this module; the user will need to alter the MIDI so that the tracks
are of equal duration and the last C<note_on> events have a suitable
I<dtime> set. L<MIDI::Event> may be helpful to study if this paragraph
did not make much sense, and inspecting the contents of MIDI files with
C<eg/midi-dump>.

  $ perl ./eg/midi-dump t/cowbell.midi

Other problems with MIDI include that zero I<dtime> events can be
associated with either some previous or next event; worse, these might
be ordered so that the control change for the future note happens prior
to the off event of the previous note. This has been a long way to say
that random MIDI may not segment itself cleanly.

Lilypond MIDI files in particular contain a control track that will need
to be removed as this track contains no note_on events.

  my $opus = MIDI::Opus->new( { from_file => 'lilypond.midi' } );
  shift @{ $opus->tracks_r };
  my ( $mis, $durations ) = ...

=head1 METHODS

These will throw an exception if anything goes awry.

=over 4

=item B<new> I<opus>

Creates a new object and performs duration calculations on the given
L<MIDI::Opus> object. Returns the object and an array reference of
durations that the I<opus> can be B<split> on, if any.

=item B<split> I<duration>

Splits the I<opus> into segments of the given I<duration>, assuming that
is possible. The returned array reference of segments consists of array
references for each track, which in turn contain one or more MIDI event
array references.

=back

=head1 BUGS

Probably, given the lack of real world MIDI that has been thrown
at the code.

=head1 SEE ALSO

L<MIDI>, L<MIDI::Ngram>, L<MIDI::Util>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
