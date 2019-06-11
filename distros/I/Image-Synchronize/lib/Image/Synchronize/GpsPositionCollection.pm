package Image::Synchronize::GpsPositionCollection;

use warnings;
use strict;

use v5.10.0;

use parent 'Exporter';

use Carp;
use Image::Synchronize::Timerange;
use Scalar::Util qw(
  looks_like_number
);
use YAML::Any qw(
  Dump
               );

use overload '""' => \&stringify;

=head1 NAME

Image::Synchronize::GpsPositionCollection - Manage a collection of GPS
positions

=head1 METHODS

The module provides the following methods:

=head2 new

  $gpc = Image::Synchronize::GpsPositionCollection->new;

Creates and returns a new instance of the class.

=cut

sub new {
  my ($class) = @_;
  bless { data => [], reduced => 0 }, $class;
}

=head2 add

  $gpc->add($time, $latitude, $longitude, $altitude, $id, $scope);

Adds a point to the track with the specified C<$id>, for the specified
C<$scope>.  The data of the point include the C<$time> (as from
L<gmtime>), the C<$latitude> in degrees (positive to the north,
negative to the south), the C<$longitude> in degrees (positive to the
east, negative to the west), and the C<$altitude> in meters.

Returns the C<Image::Synchronize::GpsPositionCollection> itself.

=cut

sub add {
  my ( $self, $time, $latitude, $longitude, $altitude, $id, $scope ) = @_;
  $self->{tracks}->{$scope}->{$id} //=
    { data => [], min_time => undef, max_time => undef };
  $self->{track_id2scope}->{$id} = $scope;
  my $track = $self->{tracks}->{$scope}->{$id};
  push @{ $track->{data} }, [ $time, $latitude, $longitude, $altitude ];
  if ( defined $track->{max_time} and $time < $track->{max_time} ) {
    $track->{needs_reduction} = 1;
    $self->{reduced}          = 0;
    $track->{min_time}        = $time if $time < $track->{min_time};
  }
  else {
    $track->{min_time} //= $time;
    $track->{max_time} = $time;
  }

  # TODO: support position bounding box crossing longitude 180 degrees
  $track->{min_longitude} = $longitude
    if $longitude < ( $track->{min_longitude} // 1000 );
  $track->{max_longitude} = $longitude
    if $longitude > ( $track->{max_longitude} // -1000 );
  $track->{min_latitude} = $latitude
    if $latitude < ( $track->{min_latitude} // 1000 );
  $track->{max_latitude} = $latitude
    if $latitude > ( $track->{max_latitude} // -1000 );
  return $self;
}

=head2 ids_for_track

  @ids_for_track = $gpc->ids_for_track($scope);
  @ids_for_track = $gpc->ids_for_track; # all scopes

Returns a list of track IDs for the specified C<$scope>, or for all
scopes.

Note that a given C<$scope> includes all other scopes whose names have
C<$scope> as their prefix.  So, scope 'foo/bar' includes scopes
'foo/barbar' and 'foo/bar/bar', but not scope 'foo/fie'.

=cut

sub ids_for_track {
  my ( $self, $scope ) = @_;
  my @ids;
  foreach my $s ( keys %{ $self->{tracks} } ) {
    if ($scope) {
      next unless $s =~ /^\Q$scope\E/;
    }
    push @ids, keys %{ $self->{tracks}->{$s} };
  }
  return sort { $a cmp $b } @ids;
}

sub track_for_id {
  my ( $self, $track_id ) = @_;
  my $scope = $self->{track_id2scope}->{$track_id};
  return unless defined $scope;
  my $track = $self->{tracks}->{$scope}->{$track_id};
}

=head2 points_for_track

  $points = $gpc->points_for_track($track_id);

Returns a reference to the array of track points for the track with
the specified C<$track_id>, or C<undef> if that track is not known.

=cut

sub points_for_track {
  my ( $self, $track_id ) = @_;
  my $track = $self->track_for_id($track_id);
  return unless $track;
  return $track->{data};
}

=head2 extreme_times_for_track

  ($min_time, $max_time) = $gpc->extreme_times_for_track($track_id);

Returns the least and greatest times of any points in the track with
the specified C<$track_id>, or C<undef> if that track is not known.

=cut

sub extreme_times_for_track {
  my ( $self, $track_id ) = @_;
  my $track = $self->track_for_id($track_id);
  return unless $track;
  return ( $track->{min_time}, $track->{max_time} );
}

=head2 middle_bounding_box_for_track

  ($latitude, $longitude) = $gpc->middle_bounding_box_for_track($track_id);

Returns the coordinates of the middle of the bounding box of the track
with the specified C<$track_id>, or C<undef> if that track is not
known.

The bounding box touches the points with the least and greatest
longitudes and latitudes.

=cut

sub middle_bounding_box_for_track {
  my ( $self, $track_id ) = @_;
  my $track = $self->track_for_id($track_id);
  return unless $track;
  return (
    ( $track->{min_latitude} + $track->{max_latitude} ) / 2,
    ( $track->{min_longitude} + $track->{max_longitude} ) / 2,
  );
}

=head2 reduce

  $gpc->reduce;

Ensures that for each GPS track the points are sorted in ascending
order of time, and that there are no duplicate times.  This is needed
by L<position_for_time>.

=cut

# TODO: ensure that there are no duplicate times

sub reduce {
  my ($self) = @_;
  return if $self->{reduced};
  foreach my $scope ( keys %{ $self->{tracks} } ) {
    foreach my $track_id ( keys %{ $self->{tracks}->{$scope} } ) {
      my $track = $self->{tracks}->{$scope}->{$track_id};
      if ( $track->{needs_reduction} ) {
        @{ $track->{data} } = sort { $a->[0] <=> $b->[0] } @{ $track->{data} };
        delete $track->{needs_reduction};
      }
    }
  }
  $self->{reduced} = 1;
}

=head2 tracks_for_time

  @ids_for_track = $gpc->tracks_for_time($time, $scope);
  @ids_for_track = $gpc->tracks_for_time($time); # all scopes

Returns the C<@ids_for_track>, for the specified C<$scope> or all scopes,
that cover the C<$time>, i.e., for which the C<$time> is greater than
or equal to the oldest time of the track and the C<$time> is less than
or equal to the youngest time of the track.

Note that a given C<$scope> includes all other scopes whose names have
C<$scope> as their prefix.  So, scope 'foo/bar' includes scopes
'foo/barbar' and 'foo/bar/bar', but not scope 'foo/fie'.

Returns the empty list if no tracks cover the time (within the scope,
if specified).

=cut

sub tracks_for_time {
  my ( $self, $time, $scope ) = @_;
  my @matching_ids_for_track;
  foreach my $track_id ( $self->ids_for_track($scope) ) {
    my ( $mintime, $maxtime ) = $self->extreme_times_for_track($track_id);
    push @matching_ids_for_track, $track_id
      if $mintime <= $time && $time <= $maxtime;
  }
  return @matching_ids_for_track;
}

sub interpolate_point_ {
  my ( $point1, $point2, $fraction ) = @_;
  my @point_for_time;
  foreach ( 1 .. 3 ) {
    my $val1 = $point1->[$_];
    my $val2 = $point2->[$_];
    if ( looks_like_number($val1) && looks_like_number($val2) ) {
      push @point_for_time, $val1 * ( 1 - $fraction ) + $val2 * $fraction;
    }
    else {
      push @point_for_time, $val1;
    }
  }
  return @point_for_time;
}

=head2 position_for_time

  %positions = $gpc->position_for_time($time,
                                       scope => $scope,
                                       track => $track_id);

Returns the GPS positions for the indicated C<$time>, C<$scope>,
and/or C<$track_id>, or an empty list if no matching positions are
known.

The returned C<@positions> contains a reference to a hash for each
found position.  The hash contains keys C<'track'>, C<'scope'>, and
C<'position'>.  The value for the first key is the track ID.  The
value for the second key is the scope.  The value for the last key is
a reference to an array with elements C<[$longitude, $latitude,
$altitude]>.  The positions are sorted by decreasing scope length.

=cut

sub position_for_time {
  my ( $self, $time, %options ) = @_;
  my @results;
  foreach my $scope (
    sort { length($b) <=> length($a) or $a cmp $b }
    keys %{ $self->{tracks} }
    )
  {

    # we accept points from GPX files in the same or higher
    # directories as the specified scope
    next
      if defined( $options{scope} )
      and $options{scope} !~ /^\Q$scope\E/;
    my $data_for_scope = $self->{tracks}->{$scope};
    foreach my $track_id ( sort keys %{$data_for_scope} ) {
      next
        if defined( $options{track_id} )
        and $track_id ne $options{track_id};
      my $data_for_track = $data_for_scope->{$track_id};
      next
        if $time < $data_for_track->{min_time}
        or $time > $data_for_track->{max_time};
      my $points = $data_for_track->{data};
      my $index =
        search( $time, scalar @{$points}, sub { $points->[ $_[0] ]->[0] } );

      # now $index is the index into @$points of the last point with
      # time at or before $time

      --$index if $index == scalar( @{$points} ) - 1;
      if ( $index >= 0 ) {
        my $point1 = $points->[$index];
        my $point2 = $points->[ $index + 1 ];
        my $fraction =
          ( $time - $point1->[0] ) / ( $point2->[0] - $point1->[0] );
        my @point_for_time = interpolate_point_( $point1, $point2, $fraction );
        push @results,
          {
          track    => $track_id,
          scope    => $scope,
          position => \@point_for_time
          };
      }
    }
  }
  return @results;
}

sub get_value_ {
  my ( $get, $index ) = @_;
  my $ok;
  my $value;
  if ( ref $get eq 'ARRAY' ) {
    $value = $get->[$index];
  }
  elsif ( ref $get eq 'CODE' ) {
    $value = $get->($index);
  }
  else {
    croak "Cannot search in data of type '"
      . ( ref($get) ? ref($get) : 'scalar' ) . "'\n";
  }
  $value;
}

=head2 search

  $index = search($target, $count, $get);

Searches for the C<$target> in an array of C<$count> elements sorted
in non-descending order.  The array elements are accessed through
C<$get>, which may be an array reference or a code reference.  If it
is a code reference, then the elements of the array are accessed
through C<< $get->($index) >>.

Returns the greatest element C<$index> for which the element is equal
to or less than the C<$target>.  If the C<$target> is less than the
first element of the array, then returns -1.

=cut

sub search {
  use integer;
  my ( $target, $count, $get ) = @_;
  my $imin = 0;
  my $imax = $count;
  while ( $imin < $imax ) {
    my $imid = ( $imin + $imax ) / 2;
    my $value;
    $value = get_value_( $get, $imid );
    if ( $value < $target ) {
      $imin = $imid + 1;
    }
    else {
      $imax = $imid;
    }
  }
  return $count - 1 if $imin == $count;
  my $value = get_value_( $get, $imin );
  return $imin - 1 if $target < $value;
  return $imin;
}

sub display_time_utc {
  my ($time) = @_;
  return unless defined $time;
  my ( $second, $minute, $hour, $day, $month, $year ) = gmtime($time);
  ++$month;
  $year += 1900;
  return sprintf( '%d-%02d-%02dT%02d:%02d:%02dZ',
    $year, $month, $day, $hour, $minute, $second );
}

sub extends {
  my ($self) = @_;
  my @ranges;
  foreach my $track_id ( $self->ids_for_track ) {
    push @ranges,
      {
      times    => [ $self->extreme_times_for_track($track_id) ],
      position => [ $self->middle_bounding_box_for_track($track_id) ]
      };
  }
  @ranges = sort { $a->{times}->[0] <=> $b->{times}->[0] } @ranges;
  foreach my $i ( 0 .. $#ranges ) {
    my $r = $ranges[$i]->{times};
    $ranges[$i]->{times} =
      Image::Synchronize::Timerange->new( $r->[0], $r->[1] );
  }
  return @ranges;
}

sub stringify {
  my ($self) = @_;
  my @r = $self->extends;
  $_ = sprintf( '%-34s %#13.8f %#13.8f', $_->{times}, @{ $_->{position} } )
    foreach @r;
  return Dump( \@r );
}

=head1 DEPENDENCIES

This module uses the following non-core Perl module:

=over

=item

Image::Synchronize::Timerange;

=item

namespace::clean

=item

YAML::Any

=back

=head1 AUTHOR

Louis Strous E<lt>LS@quae.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
