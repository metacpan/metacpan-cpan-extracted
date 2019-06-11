package Image::Synchronize::CameraOffsets;

=head1 NAME

Image::Synchronize::CameraOffsets - Manage time offsets for a range of
times

=head1 METHODS

The module provides the following methods:

=cut

use warnings;
use strict;

use v5.10.0;

use Carp;
use Image::Synchronize::Timestamp;
use Scalar::Util qw(
  looks_like_number
);
use Time::Local qw(
  timegm
);
use YAML::Any qw(
  Load
  Dump
);

=head2 new

  $co = Image::Synchronize::CameraOffsets->new;

Creates and returns a new instance of this class.

=cut

sub new {
  my ( $class, %options ) = @_;

  # all three hash references have structure
  # $camera_id => { $time => $offset }
  bless {
    base         => {},
    added        => {},
    effective    => {},
    synchronized => 0,
    exists( $options{log_callback} )
    ? ( log_callback => $options{log_callback} )
    : (),
  }, $class;
}

=head2 set

  $co = $co->set($camera_id, $time, $offset);
  $co = $co->set($camera_id, $time, $offset, $file);

Declares a time offset for a particular time for a particular camera.

C<$camera_id> is the ID of the camera that took the image for which an
offset is specified.

C<$time> is the time (either in seconds since the epoch, as for
L<gmtime>, or else as an L<Image::Synchronize::Timestamp>) of the
image for which the offset is specified.

C<$offset> is the time offset in seconds that is valid at the
specified C<$time>.

C<$file> is the optional file name.  If it is defined, then it is used
in any generated messages.

In scalar context, returns the object itself.  In list context,
returns the object and also a true or false value that says whether an
offset for that camera and time already existed and was replaced.
That second element has a false value if there was no offset yet, and
also if there was already an offset but it wasn't changed.

=cut

sub set {
  my ( $self, $camera_id, $time, $offset, $file ) = @_;
  if ( Image::Synchronize::Timestamp->istypeof($time) ) {
    $time = $time->time_utc // $time->time_local;
  }
  croak 'Offset must be a scalar but was a '
    . ref($offset)
    . ( $file ? " for $file" : '' ) . "\n"
    if ref $offset;
  my $changed = 0;
  if ( not defined $self->{added}->{$camera_id}->{$time} ) {
    $changed = 1;
  }
  elsif ( $self->{added}->{$camera_id}->{$time}->{offset} != $offset ) {
    if ( not wantarray ) {    # print message here
      my $t = Image::Synchronize::Timestamp->new($time);
      my $message =
          "Replacing offset $self->{added}->{$camera_id}->{$time}->{offset} "
        . "of camera $camera_id "
        . ( $file ? "for $file " : '' ) . "at "
        . $t->clone_to_local_timezone
        . " with $offset\n";
      if ( $self->{log_callback} ) {
        $self->{log_callback}->($message);
      }
      else {
        print $message;
      }
    }    # otherwise we assume that the caller prints a message if needed
    $changed = 2;
  }
  if ($changed) {
    $self->{added}->{$camera_id}->{$time} = {
      offset => $offset,
      $file ? ( file => $file ) : ()
    };
  }
  $self->{synchronized}   = 0;
  $self->{min_added_time} = $time
    if not( defined $self->{min_added_time} )
    || $time < $self->{min_added_time};
  $self->{max_added_time} = $time
    if not( defined $self->{max_added_time} )
    || $time > $self->{max_added_time};
  $self->{accessed_cameras}->{$camera_id} = 1;
  return wantarray ? ( $self, ( $changed == 2 ) ) : $self;
}

=head2 cameras

  @cameras = $co->cameras;

Returns the IDs of the cameras for which time offsets have been
registered.

=cut

sub cameras {
  my ($self) = @_;
  $self->make_effective;
  my %cameras;
  for my $key ( keys %{ $self->{effective} } ) {
    $cameras{$key} = 1 if keys %{ $self->{effective}->{$key} };
  }
  return sort keys %cameras;
}

=head2 camera_count

  $count = $co->camera_count;

Returns the count of cameras represented in C<$co>.

=cut

sub camera_count {
  my ($self) = @_;
  my @cameras = $self->cameras;
  return scalar @cameras;
}

=head2 added_time_range

  ($min_added_time, $max_added_time) = $co->added_time_range;

Returns the oldest and youngest time that have been added to C<$co>.
The timestamps are returned as L<Image::Synchronize::Timestamp>s.

=cut

sub added_time_range {
  my ($self) = @_;
  return ( $self->{min_added_time}, $self->{max_added_time} );
}

# merge 'added' into 'base' to produce 'effective'
sub make_effective {
  my ($self) = @_;
  if ( not $self->{synchronized} ) {
    my ( $min_time, $max_time ) = $self->added_time_range;
    if ( defined($max_time) ) {
      my $sa = $self->{added};

      # tried to use "while (my ($camera_id, $r) = each %{$sa}" here,
      # but it seems to restart if a sibling hash element (such as
      # $self->{effective}) is modified
      foreach my $camera_id ( keys %{$sa} ) {
        my $r = $sa->{$camera_id};
        my %effective = %{ $self->{base}->{$camera_id} // {} };

        # Add the new entries for the period of interest
        foreach ( keys %{$r} ) {
          if ( defined( $effective{$_} )
            && $effective{$_} != $r->{$_}->{offset} )
          {
            my $message =
                "Replacing offset $effective{$_} "
              . "of camera $camera_id at "
              . Image::Synchronize::Timestamp->new($_)
              ->clone_to_local_timezone->display_iso
              . " with $r->{$_}->{offset}\n";
            if ( exists $self->{log_callback} ) {
              $self->{log_callback}->($message);
            }
            else {
              print $message;
            }
          }
          $effective{$_} = $r->{$_}->{offset};
        }

        # Then normalize: remove all but the first of sequences of
        # entries with the same offset -- except for the very last
        # offset, which should remain if it is a duplicate so we can
        # tell the range of times for which offsets are known.
        my $offset;
        my @times = sort { $a <=> $b } keys %effective;
        foreach my $i ( 0 .. $#times ) {
          if ( defined($offset) and $effective{ $times[$i] } == $offset ) {
            delete $effective{ $times[$i] } unless $i == $#times && $i > 0;
          }
          else {
            $offset = $effective{ $times[$i] };
          }
        }

        $self->{effective}->{$camera_id} = \%effective;
      }
    }
    $self->{synchronized} = 1;
  }
  return $self;
}

=head2 get

  $offset = $co->get($camera_id, $time);
  ($offset, $file) = $co->get($camera_id, $time);

Returns a camera offset, interpreting the registered camera offsets as
defining a piecewise constant function.

Camera offsets for a camera ID are registered through C</set> for
specific times.  The current method assumes that a camera offset is
valid from that time until the next later time for which a camera
offset was registered for the same camera ID, and that the oldest
camera ofset is valid also for any earlier time.

C<$camera_id> is the camera ID for which to return a camera offset.

C<$time> is the time for which to return a camera offset.  The time
must be specified either in seconds since the epoch, as for L<gmtime>,
or else as an L<Image::Synchronize::Timestamp>.

In scalar context, returns the requested camera offset, or C<undef> if
no offsets at all have yet been registered for that C<$camera_id>.

In list context, returns the C<$offset> as for the scalar case, and
also returns the name of the file for which that offset was
registered, if known, or C<undef> otherwise.  A file name (different
from C<undef>) is only returned if an offset was registered for
I<exactly> that C<$time>.

=cut

sub get {
  my ( $self, $camera_id, $time ) = @_;
  if ( Image::Synchronize::Timestamp->istypeof($time) ) {
    $time = $time->time_local;
  }
  $self->make_effective;
  $self->{min_added_time} = $time
    if not( defined $self->{min_added_time} )
    || $time < $self->{min_added_time};
  $self->{max_added_time} = $time
    if not( defined $self->{max_added_time} )
    || $time > $self->{max_added_time};
  $self->{accessed_cameras}->{$camera_id} = 1;
  my $c = $self->{effective}->{$camera_id};
  my @times = sort { $a <=> $b } keys %{$c};
  return unless @times;
  my $prev;

  my $file;
  if (wantarray) {

    # get the file for which the offset was registered, if any
    my $r = $self->{added}->{$camera_id};
    $file = $r->{file} if $r;
  }
  foreach (@times) {
    if ( $_ > $time ) {
      my $offset = $prev // $c->{$_};
      return wantarray ? ( $offset, $file ) : $offset;
    }
    $prev = $c->{$_};
  }
  my $offset = $c->{ $times[-1] };
  return wantarray ? ( $offset, $file ) : $offset;
}

=head2 get_exact

  $offset = $co->get_exact($camera_id, $time);

Returns the camera offset for the specified C<$time> for the specified
C<$camera_id>, if a camera offset was set (through L</set>) for
I<exactly> that time and camera ID.  Returns C<undef> if not found.

C<$time> is the time either in seconds since the epoch, as for
L<gmtime>, or else as an L<Image::Synchronize::Timestamp>.

=cut

sub get_exact {
  my ( $self, $camera_id, $time ) = @_;
  if ( Image::Synchronize::Timestamp->istypeof($time) ) {
    $time = $time->time_local;
  }
  my $r = $self->{added}->{$camera_id};
  $r = $r->{$time} if $r;
  if ($r) {
    return ( $r->{offset}, $r->{file} );
  }
  else {
    return ();
  }
}

=head2 export_data

  $data = $co->export_data;

Returns a version of Image::Synchronize::CameraOffsets C<$co> suitable
for exporting.  The return value is similar to

  {
    'cameraid1' =>
    {
      '2019-06-04T14:33:12' => '+1:03:15',
      '2019-06-05T08:11:43' => '+1:03:15'
    },
    'cameraid2' =>
    {
      '2019-01-01T00:00:00' => '+2:00',
      '2019-06-05T08:11:43' => '+2:00'
    },
  }

=cut

sub export_data {
  my ($self) = @_;
  $self->make_effective;
  my %export;
  my $e = $self->{effective};
  while ( my ( $camera_id, $c ) = each %{$e} ) {
    my %items;
    foreach my $time ( sort { $a <=> $b } keys %{$c} ) {
      $items{ display_time($time) } = display_offset( $c->{$time} );
    }
    $export{$camera_id} = \%items;
  }
  return \%export;
}

=head2 parse

  $co = $co->parse($data);

Parses camera offsets information from text C<$data> into
Image::Synchronize::CameraOffsets C<$co>, replacing any earlier
contents of C<$co>.  The text is expected to be in the format that
L</stringify> produces.  Returns the object.

=cut

sub parse {
  my ( $self, $data ) = @_;
  my %import;
  while ( my ( $camera_id, $c ) = each %{$data} ) {
    my $e = $import{$camera_id} = {};
    foreach my $key ( sort keys %{$c} ) {

      # the key is assumed to be a timestamp in text format, without
      # timezone offset
      my $time = Image::Synchronize::Timestamp->new($key);
      croak "Invalid time: $key\n" unless defined $time;

      # the value is assumed to be a timezone offset, in one of the
      # following three formats: '-1805', '-03:11', '-03:11:17'.  The
      # first one specifies the optionally signed number of seconds.
      # The second one specifies the optionally signed number of hours
      # and number of minutes.  The third one is like the second but
      # adds the number of seconds.

      my $offset = $c->{$key};
      croak "Undefined offset\n" unless defined $offset;
      if ( $offset =~ /^([-+])?(\d+):(\d+)(?::(\d+))?$/ ) {
        $offset = $2 * 3600 + $3 * 60 + ( $4 // 0 );
        $offset = -$offset if $1 eq '-';
      }
      elsif ( $offset !~ /^[-+]?\d+$/ ) {
        croak "Invalid offset: $offset\n";
      }
      $e->{ $time->time_local } = $offset;
    }
  }
  $self->{base} = \%import;

  # drop previous contents
  $self->{added} = {};
  delete $self->{min_added_time};
  delete $self->{max_added_time};

  # store the "base" contents also as the "effective" contents.  It
  # must be a deep copy, not a shallow one, otherwise processing of
  # "effective" may modify "base", too.
  $self->{effective}    = Load( Dump( $self->{base} ) );
  $self->{synchronized} = 1;
  return $self;
}

# returns a version of timestamp C<$time> (acceptable to
# L<Image::Synchronize::Timestamp>) that is ready for display.  For
# use by the L</stringify> method.
sub display_time {
  my ($time) = @_;
  my $t = Image::Synchronize::Timestamp->new($time);
  $t->remove_timezone;
  return $t->display_iso;
}

# returns a version of timezone offset C<$offset> (in seconds) that is
# ready for display.  For use by the L</stringify> method.
sub display_offset {
  my ($offset) = @_;
  use integer;
  my $tzmin  = $offset / 60;
  my $tzsec  = $offset % 60;
  my $tzhour = $tzmin / 60;
  $tzmin = abs( $tzmin % 60 );
  $tzsec = abs($tzsec);
  if ($tzsec) {
    return sprintf( '%+d:%02d:%02d', $tzhour, $tzmin, $tzsec );
  }
  else {
    return sprintf( '%+d:%02d', $tzhour, $tzmin );
  }
}

=head2 relevant_part

  $relevant = $co->relevant_part;

Extracts the part of the camera offsets C<$co> that was accessed.  The
results include only those camera IDs that were accessed through
L</set> or L</get> since the last call to L</parse>, and for each of
those camera IDs only the smallest time range that was accessed for that
camera ID.

The return value is a HASH reference, similar to

  {
    'CameraID1' => {
      '2018-03-10T17:44:22' => 76,
      '2018-05-02T12:55:52' => -15,
      '2018-06-22T09:22:15' => -15
    },
  }

The keys are camera IDs and their 

=cut

sub relevant_part {
  my ($self) = @_;
  $self->make_effective;
  my %relevant;
  while ( my ( $camera_id, $c ) = each %{ $self->{effective} } ) {
    next unless $self->{accessed_cameras}->{$camera_id};
    my $e = $relevant{$camera_id} = {};
    my ( $first, $last );
    my @times = sort { $a <=> $b } keys %{$c};
    foreach my $i ( 0 .. $#times ) {
      $first = $i
        if not( defined $first )
        && $times[$i] >= $self->{min_added_time};
      $last = $i if $times[$i] <= $self->{max_added_time};
    }
    if ( defined $first ) {

      # expand range so it includes at least the entire relevant range
      --$first if $first > 0 && $times[$first] > $self->{min_added_time};
      ++$last if $last < $#times && $times[$last] < $self->{max_added_time};

      foreach my $i ( $first .. $last ) {
        $relevant{$camera_id}->{ display_time( $times[$i] ) } =
          display_offset( $c->{ $times[$i] } );
      }
    }
  }
  return \%relevant;
}

=head2 stringify

  $text = $co->stringify;

Returns the exportable contents of Image::Synchronize::CameraOffsets
C<$co> in YAML format.  The return value is similar to

    cameraid1:
      2019-06-04T14:33:12: +1:03:15
      2019-06-05T08:11:43: +1:03:15
    cameraid2:
      2019-01-01T00:00:00: +2:00
      2019-06-05T08:11:43: +2:00

=cut

sub stringify {
  my ($self) = @_;
  return Dump($self->export_data);
}

sub to_display {
  my ($self) = @_;
  $self->make_effective;
  my %relevant;
  while ( my ( $camera_id, $c ) = each %{ $self->{effective} } ) {
    my $e = $relevant{$camera_id} = {};
    my @times = sort { $a <=> $b } keys %{$c};
    foreach my $i ( 0 .. $#times ) {
      $relevant{$camera_id}->{ display_time( $times[$i] ) } =
        display_offset( $c->{ $times[$i] } );
    }
  }
  return \%relevant;
}

sub for_camera {
  my ( $self, $camera_id ) = @_;
  my %out;
  foreach my $key (qw(base added effective)) {
    $out{$key} = $self->{$key}->{$camera_id};
  }
  return \%out;
}

=head1 DEPENDENCIES

This module uses the following non-core Perl module:

=over

=item

Image::Synchronize::Timestamp

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
