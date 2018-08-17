package Image::Synchronize::Timerange;

=head1 NAME

Image::Synchronize::Timerange - a timestamp range class

=head1 SYNOPSIS

  # from single text value
  $r = Image::Synchronize::Timerange
    ->new('2010-06-26 17:44:12+03:00/2010-06-26 18:03:44+03:00');

  # or from two text values
  $r = Image::Synchronize::Timerange
    ->new('2010-06-26 17:44:12+03:00', '2010-06-26 18:03:44+03:00');

  # or from two "time" values
  $r = Image::Synchronize::Timerange
    ->new('2010-06-26 17:44:12+03:00', '2010-06-26 18:03:44+03:00');

  # omit range end date or timezone if the same as for range start
  $r = Image::Synchronize::Timerange
    ->new('2010-06-26 17:44:12+03:00/18:03:44');

  # number of non-leap seconds since the epoch
  @time_local = $r->time_local;  # in local timezone
  @time_utc = $r->time_utc;      # in UTC

  @offset = $r->offset_from_utc; # in seconds

  # in scalar context refers only to range beginning
  $time_local = $r->time_local;  # in local timezone
  $time_utc = $r->time_utc;      # in UTC

  $offset = $r->offset_from_utc; # in seconds

  $r2 = $r->clone;              # clone
  $r2 == $r;                    # test equality
  $r2 != $r;                    # test inequality
  print "$r";                   # back to text format

=head1 METHODS

=cut

use warnings;
use strict;

use Carp;
use Image::Synchronize::Timestamp;
use Scalar::Util qw(blessed looks_like_number);

use overload
  '='   => \&clone,
  '-'   => \&subtract,
  '+'   => \&add,
  '""'  => \&stringify,
  '<=>' => \&three_way_cmp;

=head2 new

  # empty range
  $r = Image::Synchronize::Timerange->new;

  # range beginning and range end

  #  from text representation
  $r = Image::Synchronize::Timerange->new($text);

  #  from two values;
  $r = Image::Synchronize::Timerange->new($v1, $v2);
  # Each value may be an Image::Synchronize::Timestamp, a time value,
  # or a text value

  # range of length zero

  #  from text representation
  $r = Image::Synchronize::Timerange->new($text);

  #  from one value
  $r = Image::Synchronize::Timerange->new($v1);

  # The value may be an Image::Synchronize::Timestamp, a time value,
  # or a text value

Construct a new instance.

If a timezone offset is specified for the range beginning or the range
end but not for both, then the specified timezone offset applies to
both.

If invalid arguments are supplied, then returns C<undef>.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  if ( scalar(@_) == 1 ) {

   # either a text representation of a fat range (with its end
   # different from its beginning), or a
   # text/Image::Synchronize::Timestamp/time representation of a thin
   # range (with length zero).
    if ( Image::Synchronize::Timestamp->istypeof( $_[0] ) ) {

      # an Image::Synchronize::Timestamp
      $self->{begin} = $_[0];
    }
    elsif ( not looks_like_number( $_[0] ) ) {
      $self->set_from_text( $_[0] ) or return;
    }
    else {
      $self->{begin} = Image::Synchronize::Timestamp->new( $_[0] ) or return;
    }
  }
  elsif ( scalar(@_) >= 2 ) {

    # a text/Image::Synchronize::Timestamp/time representation of a
    # fat range
    my @values;
    foreach ( 0 .. 1 ) {
      if ( Image::Synchronize::Timestamp->istypeof( $_[$_] ) ) {
        $values[$_] = $_[$_];
      }
      else {
        $values[$_] = Image::Synchronize::Timestamp->new( $_[$_] ) or return;
      }
    }
    return unless defined $values[0] and defined $values[1];
    $self->{begin} = $values[0];
    $self->{end}   = $values[1];
  }
  else {
    $self->{begin} = Image::Synchronize::Timestamp->new;
  }
  return $self;
}

sub istypeof {
  my ( $class, $value ) = @_;
  return blessed($value) && $value->isa($class);
}

=head2 set_from_text

  $r->set_from_text($text);

Set the range based on the C<$text>.  If C<$text> is not a valid text
representation of a time range, then leaves C<$r> unchanged and
returns C<undef>.  Otherwise returns C<$r> after updating it.

=cut

sub set_from_text {
  my ( $self, $text ) = @_;
  if ( my ( $value1, $value2 ) = $text =~ m|^(.*?)/(.+)$| ) {
    my @components1 = Image::Synchronize::Timestamp::parse_components_($value1);
    my @components2 = Image::Synchronize::Timestamp::parse_components_($value2);

    return unless defined $components1[0]    # date 1
      and defined $components1[3]            # time 1
      and defined $components2[3];           # time 2

    my ( $time1, $offset1 ) =
      Image::Synchronize::Timestamp::components_to_time_and_offset_(
      @components1);
    return unless defined $time1;

    # range end date and timezone offset defaults to that of range
    # beginning
    $components2[$_] //= $components1[$_] for ( 0 .. 2, 6 );

    my ( $time2, $offset2 ) =
      Image::Synchronize::Timestamp::components_to_time_and_offset_(
      @components2);
    return unless defined $time2;

    if (  defined $offset1
      and defined $offset2
      and $time2 - $offset2 < $time1 - $offset1 )
    {
      # the range "end" indicates an earlier time than the range
      # "beginning"; switch roles
      ( $time1, $offset1, $time2, $offset2 ) =
        ( $time2, $offset2, $time1, $offset1 );
    }

    $self->{begin} =
      Image::Synchronize::Timestamp->new($time1)
      ->set_timezone_offset               # remove UTC timezone
      ->set_timezone_offset($offset1);    # set new timezone offset
    $self->{end} =
      Image::Synchronize::Timestamp->new($time2)
      ->set_timezone_offset               # remove UTC timezone
      ->set_timezone_offset($offset2);    # set new timezone offset
  }
  else {
    $self->{begin} = Image::Synchronize::Timestamp->new($text) or return;
    delete $self->{end};
  }
  $self->normalize;
  return $self;
}

# convert to a normalized format, in which both the range beginning
# and range end are defined if any of them are, and in which both the
# range beginning and range end have a timezone offset if any of them
# have one.
sub normalize {
  my ($self) = @_;
  if ( $self->{begin} ) {
    $self->{end} //= $self->{begin}->clone;
  }
  elsif ( $self->{end} ) {
    $self->{begin} //= $self->{end}->clone;
  }
  else {
    return $self;
  }
  for (qw(local_time offset_from_utc)) {
    if ( exists $self->{begin}->{$_} ) {
      $self->{end}->{$_} //= $self->{begin}->{$_};
    }
    elsif ( exists $self->{end} and exists $self->{end}->{$_} ) {
      $self->{begin}->{$_} = $self->{end}->{$_};
    }
  }
  return $self;
}

=head2 begin

  $t = $r->begin;

Returns an L<Image::Synchronize::Timestamp> representing the beginning
of the range.

=cut

sub begin {
  my ($self) = @_;
  return $self->{begin};
}

=head2 end

  $t = $r->end;

Returns an L<Image::Synchronize::Timestamp> representing the end of
the range.

=cut

sub end {
  my ($self) = @_;
  return $self->{end};
}

sub per_timestamp_ {
  my ( $self, $coderef, @args ) = @_;
  if (wantarray) {
    return ( $coderef->( $self->begin, @args ),
      $coderef->( $self->end, @args ) );
  }
  return $coderef->( $self->begin, @args );
}

=head2 time_local

  @time = $r->time_local;       # range begin and end
  $time = $r->time_local;       # range begin only

Returns the number of non-leap seconds since the epoch in the timezone
associated with the timestamp, if known.  Otherwise returns C<undef>.

In list context, processes both the beginning and end of the range.
In scalar context, processes only the beginning.

=cut

sub time_local {
  my ($self) = @_;
  return $self->per_timestamp_( sub { $_[0]->time_local } );
}

=head2 time_utc

  @time = $r->time_utc;         # range begin and end
  $time = $r->time_local;       # range begin only

Returns the number of non-leap seconds since the epoch in UTC, if
known.  Otherwise returns C<undef>.

In list context, processes both the beginning and end of the range.
In scalar context, processes only the beginning.

=cut

sub time_utc {
  my ($self) = @_;
  return $self->per_timestamp_( sub { $_[0]->time_utc } );
}

=head2 offset_from_utc

  @offset = $r->offset_from_utc;
  $offset = $r->offset_from_utc;

Returns the timezone offset from UTC in seconds, if known.  Otherwise
returns C<undef>.

In list context, processes both the beginning and end of the range.
In scalar context, processes only the beginning.

=cut

sub offset_from_utc {
  my ($self) = @_;
  return $self->per_timestamp_( sub { $_[0]->offset_from_utc } );
}

sub has_timezone_offset {
  my ($self) = @_;
  return $self->begin->has_timezone_offset;
}

=head2 length

  $l = $r->length;

Returns the length of the time range, in seconds.

=cut

sub length {
  my ($self) = @_;
  return $self->end - $self->begin;
}

=head2 set_timezone_offset

  $r->set_timezone_offset($target_timezone_offset);

Sets the timezone of the beginning and end of the range to
C<$target_timezone_offset> seconds relative to UTC.

If the beginning or end of the range already had a timezone offset and
if C<$target_timezone_offset> is defined, then the local time of the
beginning or end gets adjusted such that the indicated instant of time
remains the same.

If the beginning and end of the range already had a timezone offset
and if C<$target_timezone_offset> is undefined, then the local time of
the end of the range is converted into the same timezone as the
beginning of the range before the timezone offsets are removed, so
that the length of the range remains the same.

Returns the instance after adjustment.

=cut

sub set_timezone_offset {
  my ( $self, $target_timezone_offset ) = @_;
  if (  $self->{end}
    and defined( $self->{end}->offset_from_utc )
    and defined( $self->{begin}->offset_from_utc )
    and $self->{begin}->offset_from_utc != $self->{end}->offset_from_utc
    and not defined $target_timezone_offset )
  {
    # first convert end of range to same timezone as beginning
    $self->{end}->set_timezone_offset( $self->{begin}->offset_from_utc );
  }
  $self->{begin}->set_timezone_offset($target_timezone_offset);
  $self->{end}->set_timezone_offset($target_timezone_offset)
    if $self->{end};
  return $self->normalize;
}

=head2 set_local_timezone

 $r->set_local_timezone;

Sets or changes the timezone of the beginning and end of the range to
the local timezone of the Perl process, including the effects of
Daylight Savings Time if appropriate.  Returns the instance.

If the range beginning or end do not have a timezone yet, then this
method may set the wrong timezone offset for part of the days on which
Daylight Savings Time begins or ends.

=cut

sub set_local_timezone {
  my ($self) = @_;
  $self->{begin}->set_local_timezone;
  $self->{end}->set_local_timezone if $self->{end};
  return $self;
}

=head2 set_local_standard_timezone

 $r->set_local_standard_timezone;

Sets or changes the timezone of the beginning and end of the range to
the local standard timezone of the Perl process, without Daylight
Savings Time.  Returns the instance.

=cut

sub set_local_standard_timezone {
  my ($self) = @_;
  $self->{begin}->set_local_standard_timezone;
  $self->{end}->set_local_standard_timezone if $self->{end};
  return $self;
}

=head2 clone

  $r2 = $r->clone;

Returns a clone of the specified L<Image::Synchronize::Timerange>.
The clone is a deep copy of the original, so a subsequent change of
the original does not affect the clone.

=cut

sub clone {
  my ($self) = @_;
  my $clone = Image::Synchronize::Timerange->new;
  $clone->{begin} = $self->{begin}->clone;
  $clone->{end} = $self->{end}->clone if $self->{end};
  return $clone;
}

=head2 identical

  $r1->identical($r2);

Returns a true value if the two L<Image::Synchronize::Timerange>s are
identical, and a false value otherwise.  They are identical if the
local time and the timezone offset of the beginning and end of the
range are equal between both instances.

=cut

sub identical {
  my ( $self, $other ) = @_;

  # if begin or end is defined in the one but not the other, then they
  # are not identical
  return
    if defined( $self->begin ) != defined( $other->begin )
    or defined( $self->end ) != defined( $other->end );

  # now begin and end are either defined in both or else not defined
  # in both.

  return (
    (
      not( defined( $self->begin ) )
        or $self->begin->identical( $other->begin )
    )
      and ( not( defined( $self->end ) )
      or $self->end->identical( $other->end ) )
  );
}

=head2 <=>

  $r1 <=> $r2;
  $r1->three_way_cmp($r2);

Returns an integer value between -3 and +3, inclusive, that indicates
the position of range C<$r1> relative to that of range C<$r2>.
Returns 0 only if the two ranges indicate the same period of time
(when reduced to the same timezone).  Returns a negative number if
C<$r1> is deemed to come before C<$r2>, or a positive number if C<$r1>
is deemed to come after C<$r2>.

If C<$r1> is entirely before C<$r2> (i.e., the end of C<$r1> comes
before the beginning of C<$r2>), then returns -3.

Otherwise, if C<$r1> is entirely after C<$r2> (i.e., the beginning of
C<$r1> comes after the end of C<$r2>), then returns +3.

Otherwise C<$r1> and C<$r2> overlap in at least one point.  If the
middle time of C<$r1> comes before the middle time of C<$r2>, then
returns -2.

Otherwise, if the middle time of C<$r1> comes after the middle time
of C<$r2>, then returns +2.

Otherwise, the middle times are equal.  Then returns -1, 0, or +1
depending on whether the begin time of C<$r1> comes before, is equal
to, or comes after the begin time of C<$r2>.

If any of the relevant timestamps lack a timezone offset, then they
are assumed to be in the same timezone.  Otherwise the timezone
offsets are taken into account.

=cut

sub three_way_cmp {
  my ( $self, $other, $swap ) = @_;
  return -3 if $self->end < $other->begin;
  return +3 if $self->begin > $other->end;
  my $middle1 = $self->begin +  ( $self->end - $self->begin ) * 0.5;
  my $middle2 = $other->begin + ( $other->end - $other->begin ) * 0.5;
  return -2 if $middle1 < $middle2;
  return +2 if $middle1 > $middle2;
  return $self->begin <=> $other->begin;
}

=head2 -

 $shifted = $r - $offset;

Returns a range that is like C<$r> but shifted into the past by
C<$offset> seconds.

=cut

sub subtract {
  my ( $self, $other, $swap ) = @_;
  if ( ref($other) ) {
    croak "Sorry, cannot subtract a " . ref($other)
      . " from an Image::Synchronize::Timerange\n";
  }
  my $result = $self->clone;
  $result->{begin} -= $other;
  $result->{end} -= $other if $result->{end};
  return $result;
}

=head2 +

  $shifted = $r + $offset;
  $shifted = $offset + $r;

Returns a range that is like C<$r> but shifted into the future by
C<$offset> seconds.

=cut

sub add {
  my ( $self, $other, $swap ) = @_;
  if ( ref($other) ) {
    croak "Sorry, cannot add a "
      . ref($other)
      . " to an Image::Synchronize::Timerange\n";
  }
  my $result = $self->clone;
  $result->{begin} += $other;
  $result->{end} += $other if $result->{end};
  return $result;
}

=stringify

  $text = $r->stringify;
  $text = "$r";

Returns a text version of C<$r>, in ISO 8601 format.

If C<$r> is empty, then C<< $t->stringify >> returns C<undef>, and
C<"$r"> returns C<''>.

=cut

sub stringify {
  my ($self) = @_;
  return "" unless $self->begin;
  my $text = $self->begin->display_iso;
  if ( $self->{end} ) {
    my $text2 = $self->end->display_iso;
    if ( $text2 ne $text ) {
      my ($date) = $text =~ /^(.*?T)/;
      if ( $text2 =~ /^\Q$date\E(.*)$/ ) {

        # range end has same date as range beginning; omit date
        $text2 = $1;
      }
      my ($timezone) = $text =~ /([-+][^-+]+)$/;
      if ( defined($timezone) and $text2 =~ /^(.*?)\Q$timezone\E$/ ) {

        # range end has same timezone as range beginning; omit timezone
        $text2 = $1;
      }
      $text = "$text/$text2";
    }
  }
  return $text;
}

=head2 contains_instant

  $ok = $r->contains_instant($instant);

If C<$instant> is a number, then it is interpreted as a "time" value
as returned by the C<time> function; i.e., the number of non-leap
seconds since the epoch, in UTC.  Returns a true value if C<$r> has a
timezone offset and if the specified instant of time is not outside of
the range, or a defined but false value if C<$r> has a timezone offset
but the specified instant of time is outside of the range, or C<undef>
if C<$r> has no timezone offset so that its relationship with UTC is
unknown.

If C<$instant> is an L<Image::Synchronize::Timestamp>, then returns
C<undef> if C<$instant> has a timezone offset but C<$r> does not, or
vice versa.  Otherwise, returns a true value if the instant of time is
not outside of the range, or a defined but false value if the instant
of time is outside of the range.

Both boundaries are included in the range.

=cut

sub contains_instant {
  my ( $self, $instant ) = @_;
  if ( blessed($instant)
    and Image::Synchronize::Timestamp->istypeof($instant) )
  {
    return ( $instant >= $self->begin && $instant <= $self->end );
  }
  else {    # assume it's a time value
            # return undef if range has no timezone offset (because then we
            # cannot tell where UTC instant is compared to it)
    return unless defined $self->begin->offset_from_utc;
    return ( $instant >= $self->begin->time_utc
        && $instant <= $self->end->time_utc );
  }
}

=head2 contains_local

  $ok = $r->contains_local($instant);

Like L</contains_instant>, but disregarding timezone offsets.

If C<$instant> is a number, then it is interpreted as a "time" value
as returned by the C<time> function; i.e., the number of non-leap
seconds since the epoch.  Otherwise, C<$instant> must be an
L<Image::Synchronize::Timestamp>.

Returns a true value if the time indicated by C<$instant>,
disregarding its timezone offset if any, is within (not outside) the
range indicated by C<$r>, also disregarding its timezone offset if
any.  Otherwise returns a false value.

=cut

sub contains_local {
  my ( $self, $time ) = @_;
  $time = $time->time_local
    if ref $time;    # assume an Image::Synchronize::Timestamp
  return $self->begin->{time} <= $time && $self->end->{time} >= $time;
}

=head1 AUTHOR

Louis Strous E<lt>LS@quae.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2018 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
