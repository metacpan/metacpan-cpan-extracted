package Image::Synchronize::Timerange;

=head1 NAME

Image::Synchronize::Timerange - a timestamp range class

=head1 SYNOPSIS

=head2 Create/Parse

From two text or L<Image::Synchronize::Timestamp> or numeric values

  $r = Image::Synchronize::Timerange->new($begin, $end);

From one text value specifying beginning and end

  $r = Image::Synchronize::Timerange->new("$begin/$end");

From a text or L<Image::Synchronize::Timestamp> or numeric value
specifying a range of no duration

  $r = Image::Synchronize::Timerange->new($begin);

Using object instead of class name as invocant

  $r2 = $r->new($text);        # $r2 and $r are unrelated

Assignment/clone

  $r2 = $r->clone;              # assigns a clone
  $r2 = $r; # copies *reference*; $t and $t2 refer to the same object

=head2 Stringify

  $r = Image::Synchronize::Timerange
    ->new('2001-02-03T04:05:06+07:00/11:15');
  print "$r"; # ISO8601 format: '2001-02-03T04:05:06+07:00/11:15'
  print $r->stringify           # same as previous
  print $r->display_iso;        # same as previous
  print $r->display_utc;   # ISO in UTC: 2001-02-02T21:05:06Z/03T04:15
  print $r->display_time;       # no dates

=head2 Query

Extract the beginning and end as L<Image::Synchronize::Timestamp>:

  $timestamp_begin = $r->begin;
  $timestamp_end   = $r->end;

Number of non-leap seconds since the epoch

  ($time_local_begin, $time_local_end) = $r->time_local;
  ($time_utc_begin, $time_utc_end)     = $r->time_utc;

Timezone offset in seconds relative to UTC

  ($timezone_offset_begin, $timezone_offset_end) = $r->timezone_offset;

In scalar context refers only to range beginning

  $time_local_begin      = $r->time_local;
  $time_utc_begin        = $r->time_utc;
  $timezone_offset_begin = $r->timezone_offset;

The duration

  $duration = $r->duration;

Check if an instant is within the time range

  $bool = $r->contains_instant($instant);
  $bool = $r->contains_local($instant);

Check for presence of parts

  $bool = $r->has_timezone_offset;
  $bool = $r->is_empty;

Check type

  Image::Synchronize::Timerange->istypeof($r); # true
  Image::Synchronize::Timerange->istypeof(6); # false
  $r->istypeof(6);              # same as previous

=head2 Combine

  $r2 = $r + 30;                # shift copy forward by 30 seconds
  $r2 = 30 + $r;                # same as previous
  $r += 30;                     # shift forward by 30 seconds
  $r3 = $r + $r2                # ERROR: cannot add timeranges

  $r2 = $r - 30;                # shift copy backward by 30 seconds
  $r -= 30;                     # shift backward by 30 seconds
  $r3 = $r - $r2;               # ERROR: cannot subtract timeranges

=head2 Compare

  $r2 == $r;                    # same range
  $r2 != $r;                    # not the same range
  $r->identical($r2);           # same clock times and timezone
  $r <=> $r2;                   # three way comparison
  # < <= => > can also be used, but the interpretation is not obvious

=head2 Modify

  $r->set_from_text($text);     # replace old value
  $r->adjust_timezone_offset($offset);

=head1 METHODS

=cut

use Modern::Perl;

use Carp;
use Clone qw(clone);
use Image::Synchronize::Timestamp;
use Scalar::Util qw(blessed looks_like_number);

use parent qw(Clone);

use overload
  '='   => \&clone,
  '-'   => \&subtract,
  '+'   => \&add,
  '""'  => \&stringify,
  '<=>' => \&three_way_cmp;

=head2 new

  # empty range
  $r = Image::Synchronize::Timerange->new;

  # from two values (L<Image::Synchronize::Timestamp> or text or
  # numbers)
  $r = Image::Synchronize::Timerange->new($begin, $end);

  # from a single text value specifying begin and end:
  $r = Image::Synchronize::Timerange->new("$begin/$end");

  # a range of length zero
  $r = Image::Synchronize::Timerange->new($begin);

Construct a new instance.

The beginning and (optionally) end of the range can each be instances
of L<Image::Synchronize::Timestamp>, and can also be specified in the
same ways as for L<Image::Synchronize::Timestamp/new>.  If the date or
timezone offset are missing from one but present in the other, then
they are shared with the peer.

If the range beginning and end are specified in a single text value
(separated by C</>), then if the beginning or end are unsigned numbers
then they're not interpreted as "seconds since the epoch" (as
L<Image::Synchronize::Timestamp/new> does) but as clock hours.  So,

  '2001-02-03T04:05:06/07'

is interpreted as

  '2001-02-03T04:05:06/2001-02-03T07:00'

Returns C<undef> if invalid arguments are supplied, including if the
range end comes before the range beginning.

=cut

sub new {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant; # object or class name
  my $self = bless {}, $class;
  if ( scalar(@_) == 1 ) {
    if ( Image::Synchronize::Timestamp->istypeof( $_[0] ) ) {

      $self->{begin} = $_[0]->clone;
    }
    else {
      return unless defined $self->set_from_text( $_[0] );
    }
  }
  elsif ( scalar(@_) >= 2 ) {
    my @values;
    foreach ( 0 .. 1 ) {
      if ( Image::Synchronize::Timestamp->istypeof( $_[$_] ) ) {
        $values[$_] = $_[$_]->clone;
      }
      else {
        $values[$_] = Image::Synchronize::Timestamp->new( $_[$_] );
      }
    }
    return unless defined $values[0] and defined $values[1];
    $self->{begin} = $values[0];
    $self->{end}   = $values[1];
  }
  return $self->normalize;
}

=head2 clone

  $r2 = $r->clone;

Returns a clone of C<$r>.  The clone is a deep copy of the original,
so a subsequent change of the original does not affect the clone.

=cut

# no code; provided by package Clone

=head2 stringify

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

=head display_iso

  $text = $r->display_iso;

An alias for L</stringify>.

=cut

sub display_iso {
  stringify(@_);
}

=head2 display_utc

  $text = $r->display_utc;

Displays the time range relative to UTC, in ISO-8601 format.

=cut

sub display_utc {
  my ($self) = @_;
  return $self->new($self->{begin}->adjust_to_utc,
                    $self->{end}->adjust_to_utc)->display_iso;
}

=head2 display_time

  $text = $r->display_time;

Returns a text version of $r with the range beginning and (if present)
end as signed time values since the epoch in the associated timezone,
followed by the designation of that timezone.  The hour number is not
restricted to be less than 24 and can be negative.

This is useful for time ranges without dates.  If C<$r> was created
with date parts, then the displayed number of hours is likely to be
very large.

=cut

sub display_time {
  my ($self) = @_;
  my $front = defined($self->{begin})? $self->{begin}->display_time : '';
  return '' if $front eq '';
  my $back = defined($self->{end})? $self->{end}->display_time: '';
  return $front . ($back? "/$back": '');
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

=head2 timezone_offset

  @offset = $r->timezone_offset;
  $offset = $r->timezone_offset;

Returns the timezone offset from UTC in seconds, if known.  Otherwise
returns C<undef>.

In list context, processes both the beginning and end of the range.
In scalar context, processes only the beginning.

=cut

sub timezone_offset {
  my ($self) = @_;
  return $self->per_timestamp_( sub { $_[0]->timezone_offset } );
}

=head2 length

  $l = $r->duration;

Returns the duration of the time range, in seconds.

=cut

sub duration {
  my ($self) = @_;
  return $self->end - $self->begin;
}

=head2 has_timezone_offset

  $bool = $r->has_timezone_offset;

Returns a true value if the time range has a timezone offset, and a
false value otherwise.

=cut

sub has_timezone_offset {
  my ($self) = @_;
  return $self->begin->has_timezone_offset;
}

=head2 is_empty

Returns a true value if the time range is empty, i.e., has no
beginning and no end.  Returns a false value otherwise.

=cut

sub is_empty {
  my ($self) = @_;
  return $self->begin->is_empty;
}

=head2 istypeof

  $ok = $class->istypeof($item);
  $ok = $object->istypeof($item);    # queries $item, not $object

Returns a true value if C<$item> is an instance of (a subclass of) the
specified C<$class>, or of the class that the specified C<$object>
belongs to.  Returns a false value otherwise, including when C<$item>
is not an object.

=cut

sub istypeof {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant; # object or class name
  my ( $value ) = @_;
  return blessed($value) && $value->isa($class);
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
    return unless defined $self->begin->timezone_offset;
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


=head2 <=>

  $r1 <=> $r2;

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

=head2 ==

  $r1 == $r2;

Returns a true value if C<< <=> >> returns 0, ie., when the two ranges
represent the same interval of time (when reduced to the same
timezone).

=head2 !=

  $r1 != $r2;

Returns a true value if C<< <=> >> returns non-0, i.e., when the two
ranges do not represent the same interval of time (when reduced to the
same timezone).

=head < <= => >

  $r1 < $r2;
  $r1 <= $r2;
  $r1 => $r2;
  $r1 > $r2;

Returns a true value if C<< <=> >> returns a negative value, a zero or
negative value, a zero or positive value, or a positive value,
respectively.

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

=head2 set_from_text

  $r->set_from_text($text);

Set the range based on the C<$text> (similar to C<<
Image::Synchronize::Timerange->new($text) >>, discarding any previous
contents of C<$r>.

Returns C<$r>.

=cut

sub set_from_text {
  my ( $self, $text ) = @_;
  delete $self->{$_} foreach qw(begin end);
  if ( my ( $value1, $value2 ) = $text =~ m|^(.*?)/(.+)$| ) {
    # we disallow interpretation of isolated unsigned number as
    # "seconds from epoch" here
    $value1 = "$value1:00" if $value1 =~ /^\d+$/;
    $value2 = "$value2:00" if $value2 =~ /^\d+$/;
    my $begin = Image::Synchronize::Timestamp->new($value1);
    my $end = Image::Synchronize::Timestamp->new($value2);
    return unless (defined($begin) && defined($end));
    $self->{begin} = $begin if defined $begin;
    $self->{end} = $end if defined $end;
  } else {
    my $begin = Image::Synchronize::Timestamp->new($text);
    return unless defined $begin;
    $self->{begin} = $begin;
  };
  return $self->normalize;
}

=head2 adjust_timezone_offset

  $r->adjust_timezone_offset($offset);

Adjusts the timezone of the beginning and end of the range to
C<$offset> seconds relative to UTC.

If the beginning or end of the range already had a timezone offset and
if C<$offset> is defined, then the local time of the beginning or end
gets adjusted such that the indicated instant of time remains the
same.

If the beginning and end of the range already had a timezone offset
and if C<$_offset> is undefined, then the local time of the end of the
range is converted into the same timezone as the beginning of the
range before the timezone offsets are removed, so that the length of
the range remains the same.

Returns the instance after adjustment.

=cut

sub adjust_timezone_offset {
  my ( $self, $target_timezone_offset ) = @_;
  if (  $self->{end}
    and defined( $self->{end}->timezone_offset )
    and defined( $self->{begin}->timezone_offset )
    and $self->{begin}->timezone_offset != $self->{end}->timezone_offset
    and not defined $target_timezone_offset )
  {
    # first convert end of range to same timezone as beginning
    $self->{end}->adjust_timezone_offset( $self->{begin}->timezone_offset );
  }
  $self->{begin}->adjust_timezone_offset($target_timezone_offset);
  $self->{end}->adjust_timezone_offset($target_timezone_offset)
    if $self->{end};
  return $self->normalize;
}

=head2 set_local_timezone

 $r->adjust_to_local_timezone;

Adjusts the timezone of the beginning and end of the range to the
local timezone of the Perl process, including the effects of Daylight
Savings Time if appropriate.  Returns the instance.

If the range beginning or end do not have a timezone yet, then this
method may set the wrong timezone offset for part of the days on which
Daylight Savings Time begins or ends.

=cut

sub adjust_to_local_timezone {
  my ($self) = @_;
  $self->{begin}->adjust_to_local_timezone;
  $self->{end}->adjust_to_local_timezone if $self->{end};
  return $self;
}

###

# Calculates the nonnegative modulus of any two Perl numbers,
# including in particular floating-point numbers.  The perl operator %
# is not good enough for this, because it truncates its arguments to
# integers at the beginning of the calculation.  In list mode, mod($n,
# $d) returns ($q, $r) such that $n = $q*$d + $r with 0 <= $r <
# abs($d).  In scalar mode, returns only $r.
sub mod {
  my ($n, $d) = @_;
  my ($q, $r);
  eval {
    $q = int($n/$d);
  };
  $r = $n - $q*$d;
  # the "int" function truncates.
  #   $n $d $q   $r
  #  1.6  1  1  0.6
  # -1.6  1 -1 -0.6
  #  1.6 -1 -1  0.6
  # -1.6 -1  1 -0.6
  # We want 0 <= $r < abs($d)
  if ($r < 0) {
    --$q;
    $r += abs($d);
  }
  return wantarray? ($q, $r): $r;
}

# Splits a number into a multiple of another number and the
# nonnegative remainder.
sub split_number {
  my ($n, $d) = @_;
  my ($q, $r) = mod($n, $d);
  return wantarray? ($q*$d, $r): $r;
}

# convert to a normalized format, in which both the range beginning
# and range end are defined if any of them are, and in which both the
# range beginning and range end have a date and timezone offset if any
# of them have one.
sub normalize {
  my ($self) = @_;
  if ( $self->{begin} ) {
    $self->{end} //= $self->{begin}->clone;
  }
  elsif ( $self->{end} ) {
    $self->{begin} //= $self->{end}->clone;
  }
  else {                        # neither beginning nor end: empty
    return $self;
  }
  for (qw(local_time timezone_offset)) {
    if ( exists $self->{begin}->{$_} ) {
      $self->{end}->{$_} //= $self->{begin}->{$_};
    }
    elsif ( exists $self->{end} and exists $self->{end}->{$_} ) {
      $self->{begin}->{$_} = $self->{end}->{$_};
    }
  }
  # handle "has_date": the difference between timestamps with and
  # without dates.
  if ($self->{begin}->{has_date}
      && not($self->{end}->{has_date})) {
    # only the beginning has a date: add it to the end
    my ($date_instant, undef)
      = split_number($self->{begin}->time_local, 86400);
    $self->{end}->{time} += $date_instant;
    $self->{end}->{has_date} = 1;
  } elsif (not($self->{begin}->{has_date})
           && $self->{end}->{has_date}) {
    # only the end has a date: add it to the beginning.
    my ($date_instant, undef)
      = split_number($self->{end}->time_local, 86400);
    $self->{begin}->{time} += $date_instant;
    $self->{begin}->{has_date} = 1;
  }
  return undef if $self->{begin} > $self->{end};
  return $self;
}

sub per_timestamp_ {
  my ( $self, $coderef, @args ) = @_;
  if (wantarray) {
    return ( $coderef->( $self->begin, @args ),
      $coderef->( $self->end, @args ) );
  }
  return $coderef->( $self->begin, @args );
}

=head1 AUTHOR

Louis Strous E<lt>LS@quae.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2020 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
