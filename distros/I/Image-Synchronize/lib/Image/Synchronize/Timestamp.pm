package Image::Synchronize::Timestamp;

=head1 NAME

Image::Synchronize::Timestamp - a timestamp class

=head1 SYNOPSIS

=head2 Create/Parse

  $t = Image::Synchronize::Timestamp->new($text);
  $t2 = $t->new($text2);         # $t2 and $t are unrelated

Or create from the number of seconds since the epoch

  $t = Image::Synchronize::Timestamp->new(6000);

Here are examples of the recognized text formats:

  '2010:06:27 17:44:12+03:00': Exif date format, with timezone offset
  '2010-06-27 17:44:12+03:00': '-' as date separator
  '2010-06-27T17:44:12+03:00': 'T' as date/time separator: ISO 8601
  '2010-06-27T17:44:12+03:00:00': with timezone seconds, too
  '2010:06:27 17:50:00'      : no timezone offset
  '2010:06:27 17:50'         : fewer time components
  '2010:06:27 17+03'         : 17+03 means the same as 17:00+03:00
  '17:44:12+03:00'           : no date
  '17'                       : same as 17:00:00
  '-17:44:12+03:00'          : signed time
  '+17:44:12+03:00'

Assignment/clone:

  $t->clone;                    # assigns a clone
  $t2 = $t; # copies *reference*; $t and $t2 refer to the same object

=head2 Stringify

  $t = Image::Synchronize::Timestamp->new('2010-06-27T17:44:12+03:00');
  print "$t";             # (Exif) format;  2010:06:27 17:44:12+03:00
  print $t->stringify;    # same as previous
  print $t->display_iso;  # ISO8601 format: 2010-06-27T17:44:12+03:00
  print $t->display_utc;  # ISO in UTC:     2010-06-27T14:44:12Z
  print $t->display_time; # no date:        +354905:44:12+03:00
  print $t->date;         # Exif date (UTC) 2010:06:27
  print $t->time;         # Exif time (UTC) 14:44:12

=head2 Query

Number of non-leap seconds since the epoch

  $time_local = $t->time_local;  # in local timezone
  $time_utc   = $t->time_utc;    # in UTC

Timezone offset in seconds relative to UTC

  $offset = $t->timezone_offset;

Get timezone offset for local system at given instant

  $offset = $t->local_timezone_offset;

Check for presence of parts

  $bool = $t->has_timezone_offset;
  $bool = $t->is_empty;
  $bool = $t->has_date;

Check type

  Image::Synchronize::Timestamp->istypeof($t); # true
  Image::Synchronize::Timestamp->istypeof(3);  # false
  $t->istypeof(3);              # same as previous

=head2 Combine

  $t = Image::Synchronize::Timestamp->new('17:44:12+03:00');
  $t2 = $t + 30;                # 17:44:42+03:00
  $t2 = 30 + $t;                # same as previous
  $t3 = $t + $t2;               # ERROR: cannot add two timestamps

  $t2 += 100;                   # shift forward by 100 seconds

  $d = $t2 - $t;                #  30
  $t2 = $t - 20;                #  17:43:52+03:00
  $t3 = -$t;                    # -17:44:12+03:00

  $t3 -= 100;                   # shift backward by 100 seconds

=head2 Compare

  $t1 = Image::Synchronize::Timestamp->new('+17:44:12+03:00');
  $t2 = Image::Synchronize::Timestamp->new('+15:44:12+01:00');
  $t3 = Image::Synchronize::Timestamp->new('+17:00:00+03:00');

The following five are true

  $t1 == $t2;                   # same instant, also eq
  $t3 < $t1;                    # also <=, le, lt
  $t2 >= $t3;                   # also >, gt, ge
  $t3 != $t2;                   # not the same instant, also ne
  $t1->identical($t1);          # same clock time and timezone

  $t1 == $t2;            # true: same instant
  $t1->identical($t2);   # false: not same clock time and timezone

Three-way compare

  $t1 <=> $t2;                  # 0: same instant
  $t1 <=> $t3;                  # >0: first one is later
  $t3 <=> $t1;                  # <0: first one is earlier

=head2 Modify

  $t->set_from_text($text);     # replace old value
  $t->adjust_timezone_offset($offset); # shift to new timezone
  $t->adjust_to_local_timezone; # of local system at given instant
  $t->adjust_to_utc;
  $t->set_timezone_offset($offset); # keep clock time, replace timezone
  $t->remove_timezone;
  $t->adjust_nodate;            # reinterpret without date
  $t->adjust_todate;            # reinterpret with date

=head1 SUBROUTINES/METHODS

=cut

use Modern::Perl;

use Carp;
use Clone qw(clone);
use Scalar::Util qw(blessed looks_like_number);
use Time::Local v1.30 qw(timegm_modern timelocal_modern);

use parent qw(Clone);
# Clone provides a 'clone' member

use overload
  '='   => \&clone,    # copy constructor: doesn't overload assignment
  '-'   => \&subtract,
  '+'   => \&add,
  '""'  => \&stringify,
  '<=>' => \&three_way_cmp,
  'cmp' => \&three_way_cmp,
  ;

# CREATE/PARSE

=head2 new

  $t = Image::Synchronize::Timestamp->new;
  $t = Image::Synchronize::Timestamp->new($value);
  $t2 = $t->new($value);

Construct a new instance.  If C<$value> is a number, then it is taken
to represent the number of seconds since the epoch, in an undefined
timezone.  If C<$value> is defined but is not a number, then it is
parsed as a timestamp in text format.  See L</set_from_text> for
details of the supported formats.

If C<$value> is specified but no timestamp can be extracted from it,
then returns C<undef>.  If C<$value> is not specified, then returns an
empty instance that can be filled using L</set_from_text>.

=cut

sub new {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant; # object or class name
  my $self = bless {}, $class;
  if ( scalar(@_) ) {
    $self->set_from_text($_[0]);
    return undef unless defined $self->{time};
  }
  return $self;
}

=head2 clone

  $t->clone;

Creates a clone of C<$t>.  The clone is a "deep copy" so modifying any
part of the clone does not affect any part of the original.

Calling C<clone> explicitly is useful if you need to modify the clone
and want to leave the original unchanged.  For example,

  $t2 = $t->clone->set_timezone(0); # does not modify $t
  $t3 = $t->set_timezone(0);        # modifies $t

=cut

# no code; provided by package Clone

# STRINGIFY

=head2 stringify

  $text = $t->stringify;
  $text = "$t";

Returns a text version of C<$t>, in Exif format, i.e., using a colon
C<:> as separator in the date, time, and timezone parts.  Only the
time part is always present, the date and timezone parts are only
included when present.

The date part looks like C<'2000:01:02'>, showing year, month, and
day.  The time part looks like C<'03:04:05'>, showing hour, minute,
and second.  The timezone part looks like C<'+06:00'>, showing signed
hour, minute, and (if it is not zero) seconds.  The date and time part
are separated by one space character.  The time and timezone part are
not separated.

A full timestamp looks like C<'2000:01:02 03:04:05+06:00'>.  This
example is for a timezone where the clock time is 6 hours greater than
UTC.

If C<$t> is empty (created via L</new> or L</set_from_text> with no
argument), then C<< $t->stringify >> returns C<undef>, and C<"$t">
returns C<''>.

=cut

sub stringify {
  my ($self) = @_;
  return unless defined $self->{time};
  return display_one_( $self->{time}, $self->{timezone_offset},
                       $self->{has_date}, ':', ' ' );
}

=head2 display_iso

  $text = $t->display_iso;

Returns a text representation of the timestamp in ISO 8601 format, if
the timestamp includes a date, for example
C<2001-02-23T14:47:22+01:00> for a timestamp representing 14 hours 47
minutes 22 seconds (= 22 seconds past 2:47 pm) on February 23rd of the
year 2001.

If the timestamp does not include a date, then returns the same as
L</display_time>, of which the format is not part of ISO 8601.

Is like L</stringify> but uses a hyphen C<-> instead of a colon C<:>
as separator in the date part, and uses a capital letter C<T> instead
of a space as a separator between the date and time part.

If C<$t> is empty (created via L</new> or L</set_from_text> with no
argument), then returns C<undef>.

=cut

sub display_iso {
  my ($self) = @_;
  return unless defined $self->{time};
  return display_one_( $self->{time}, $self->{timezone_offset},
                       $self->{has_date}, '-', 'T' );
}

=head2 display_utc

  $text = $t->display_utc;

Returns a text version of C<$t>, in UTC in ISO 8601 format, if the
timestamp includes a date.  The returned text is like
C<'2000-01-02T03:04:05Z'>, showing the year, month, day, hour, minute,
and second.  If C<$t> includes timezone information, then the text
version represents the UTC date/time that represents the same instant
of time as the original clock date/time in the specified timezone.  If
C<$t> has no timezone information then it is assumed to be in UTC
already.

If the timestamp does not include a date, then returns the same as
L</display_time>, of which the format is not part of ISO 8601.

Is like L</display_iso> but uses capital letter C<Z> for the timezone
part.

If C<$t> is empty (created via L</new> or L</set_from_text> with no
argument), then returns C<undef>.

Example:

  $t = Image::Synchronize::Timestamp->new('2001-02-03 04:05:06+02:00');
  $text = $t->display_utc;              # '2001-02-03T02:05:06Z'

=cut

sub display_utc {
  my ($self) = @_;
  return unless (defined($self->{time})
                 && defined($self->{timezone_offset}));
  my $t = $self->clone->adjust_to_utc;
  return display_one_( $t->{time}, 'Z', $t->{has_date}, '-', 'T' );
}

=head2 display_time

  $text = $t->display_time

Returns a text version of C<$t> as a signed time value.  The returned
text is like C<'+03:04:05-06:07'>, showing the signed time (hour,
minute, second) since the epoch in the associated timezone, followed
by the designation of that timezone.  The hour number is not
restricted to be less than 24, and can be negative.  The example is
for a time that is 3 hours 4 minutes 5 seconds since the epoch in a
timezone that is 6 hours and 7 minutes earlier than UTC.

This method is useful for timestamps without dates.  If C<$t> was
created with a date part, then the displayed number of hours is likely
to be very large.

Examples:

  $t = Image::Synchronize::Timestamp->new('01:02+03');
  $text = $t->display_time;     # '+01:02:00+03:00'
  $text = "$t";                 # '1970:01:01 01:02:00+03:00'

  $t = Image::Synchronize::Timestamp->new('2001-02-03T04:05');
  $text = $t->display_time; # '+272548:05'
                            # 272548 hours 5 minutes since epoch

=cut

sub display_time {
  my ($self) = @_;
  return display_tz_($self->time_local) . display_tz_($self->timezone_offset);
}

=head date

  $text = $t->date;

Returns the date part of timestamp C<$t> in Exif format, similar to
C<'2020:08:23'>.  If C<$t> has a timezone offset, then the date part
of a clone adjusted to UTC is returned.  If C<$t> has no timezone
offset, then the date part of the local time is returned.

=cut

sub date {
  my ($t) = @_;
  $t = $t->clone if $t->has_timezone_offset;
  return $t->stringify =~ s/ .*//r;
}

=head date

  $text = $t->time;

Returns the time part of timestamp C<$t> in Exif format, similar to
C<'11:21:53'>.  If C<$t> has a timezone offset, then the time part of
a clone adjusted to UTC is returned.  If C<$t> has no timezone offset,
then the time part of the local time is returned.

=cut

sub time {
  my ($t) = @_;
  $t = $t->clone if $t->has_timezone_offset;
  return $t->stringify =~ s/^.*? //r;
}

# QUERY:

=head2 time_local

  $seconds = $t->time_local;

Returns the number of non-leap seconds since the epoch in the timezone
associated with the timestamp, or C<undef> if the timestamp is empty.

C<time_local> returns the same value for two timestamps with the same
clock time but different timezone offsets.

Examples:

  $t1 = Image::Synchronize::Timestamp->new('2001-02-03T04:05:06');
  $t2 = $t1->clone->set_timezone(3600); # sets timezone to +01:00

  print $t1->time_local;         # prints 981173106
  print $t2->time_local;         # prints the same

=cut

sub time_local {
  my ($self) = @_;
  return $self->{time};
}

=head2 time_utc

  $seconds = $t->time_utc;

Returns the number of non-leap seconds since the epoch in UTC, or
C<undef> if the timestamp is empty or has no timezone offset.

C<time_utc> returns different values for two timestamps with the same
clock time but different timezone offsets.

Examples:

  $t1 = Image::Synchronize::Timestamp->new('2001-02-03T04:05:06');
  $t2 = $t1->clone->set_timezone_offset(3600); # timezone +01:00
  $t3 = $t1->clone->set_timezone_offset(0);    # timezone UTC = 00:00

  print $t1->time_utc;         # undefined
  print $t2->time_utc;         # 981169506
  print $t3->time_utc;         # 981173106

=cut

sub time_utc {
  my ($self) = @_;
  my $value = $self->{time} - $self->{timezone_offset}
    if defined( $self->{time} )
    and defined( $self->{timezone_offset} );
  return $value;
}


=head2 timezone_offset

  $seconds = $t->timezone_offset;

Returns the timezone offset from UTC in seconds, or C<undef> if no
timezone offset is known.

=cut

sub timezone_offset {
  my ($self) = @_;
  return $self->{timezone_offset};
}

=head2 local_timezone_offset

  $seconds = $t->local_timezone_offset

Returns the difference between the local timezone and UTC, in seconds,
for the instant of time represented by C<$t>.

If C<$t> has no timezone offset, then it is assumed to be in UTC.

The local timezone is the timezone that is valid at the specified time
C<$t> for the system where the current process runs.

For example, if the process runs on a system that believes it is
located in Amsterdam, then C<< $t->local_timezone_offset >> returns
3600 for dates/times C<$t> when standard time (UTC+1) is in effect in
Amsterdam, and returns 7200 for dates/times C<$t> when daylight
savings time (UTC+2) is in effect in Amsterdam.

=cut

sub local_timezone_offset {
  my ($self) = @_;
  my @t = localtime( $self->time_utc // $self->time_local );
  return timegm_modern(@t) - timelocal_modern(@t);
}

=head2 has_timezone_offset

  $bool = $t->has_timezone_offset;

Returns a true value if timestamp C<$t> has a timezone offset, and a
false value otherwise.

=cut

sub has_timezone_offset {
  my ($self) = @_;
  return defined $self->{timezone_offset};
}

=head is_empty

  $bool = $t->is_empty;

Returns a true value if the date/time part of C<$t> is not defined,
and a false value otherwise.

=cut

sub is_empty {
  my ($self) = @_;
  return not(defined $self->{time});
}

=head has_date

  $bool = $t->has_date;

Returns a true value if C<$t> has a date, and a false value otherwise.

=cut

sub has_date {
  my ($self) = @_;
  return $self->{has_date};
}

=head2 istypeof

  $ok = Image::Synchronize::Timestamp->istypeof($item);

  $t = Image::Synchronize::Timestamp->new('02:03');
  $ok = $t->istypeof($item);    # queries $item, not $t

Returns a true value if C<$item> is an instance of (a subclass of)
Image::Synchronize::Timestamp, and a false value otherwise, including
when C<$item> is not an object.

=cut

sub istypeof {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant; # object or class name
  my ( $value ) = @_;
  return blessed($value) && $value->isa($class);
}

# COMBINE

=head2 +

  # $t is an Image::Synchronize::Timestamp
  $sum = $t + $seconds;
  $sum = $seconds + $t;

Returns the timestamp that is C<$seconds> later than timestamp C<$t>.
C<$seconds> must be a scalar number.

=cut

sub add {
  my ( $self, $other, $swap ) = @_;
  my $othertype = identify($other);
  if ( $othertype ne '-scalar-' ) {
    croak "Sorry, cannot add Image::Synchronize::Timestamp and $othertype";
  }
  my $result = $self->clone;
  $result->{time} += $other;
  return $result;
}

=head2 -

  # $t1, $t2 are Image::Synchronize::Timestamp
  $seconds = $t2 - $t1;         # difference

  $t3 = $t2 - $seconds;         # shift

  $t3 = -$t2;                   # negative

  $t3 = $seconds - $t2;         # shift negative

The first form returns the difference in seconds between the two
timestamps C<$t2> and C<$t1>.  If at least one of the two does not
have a timezone offset, then both timestamps are assumed to be in the
same timezone.  If both have a timezone offset, then the difference
between the timezone offsets is taken into account.

The second form shifts the timestamp back in time by the specified
number of C<$seconds>, which must be a number.

The third form produces the opposite of the timestamp.  The time part
(the number of seconds since the epoch in the timezone) is multiplied
by -1, but the timezone offset (if any) remains the same.  This form
is mostly useful if the timestamp has no date part.

The fourth form is equivalent to C<< $t3 = (-$t2) + $seconds >>:
produce the negative of C<$t2> and then shift it to the future by the
indicated number of C<$seconds>.

=cut

sub subtract {
  my ( $self, $other, $swap ) = @_;
  if ( Image::Synchronize::Timestamp->istypeof($other) ) {
    return undef
      unless defined( $self->{time} )
      and defined( $other->{time} );
    my $difference = $self->{time} - $other->{time};
    if (  defined( $self->{timezone_offset} )
      and defined( $other->{timezone_offset} ) )
    {
      $difference += $other->{timezone_offset} - $self->{timezone_offset};
    }
    $difference = -$difference if $swap;
    return $difference;
  }
  else {
    my $result = $self->clone;
    $result->{time} -= $other;
    if ($swap) {
      $result->{time} = -$result->{time};
    }
    return $result;
  }
}

# COMPARE

=head2 <=>

  $order = $t1 <=> $t2;

Returns -1, zero, or +1 depending on whether timestamp C<$t1>
indicates an earlier, equal, or later instant of time than timestamp
C<$t2>.  If at least one of the two timestamps has no timezone, then
both are assumed to be in the same timezone.  The empty timestamp
compares less than any defined timestamp, and compares equal to
itself.

The following binary comparison operators are likewise available:

       < <= == => >  !=
  cmp lt le eq ge gt ne

=cut

sub three_way_cmp {
  my ( $self, $other, $swap ) = @_;
  croak "Found a " . identify($self) . ", need a " . __PACKAGE__ . "\n"
    unless Image::Synchronize::Timestamp->istypeof($self);
  unless ( Image::Synchronize::Timestamp->istypeof($other) ) {
    my $converted = Image::Synchronize::Timestamp->new($other);
    croak "Not a timestamp: $other\n" unless defined $converted;
    $other = $converted;
  }
  my $result;
  if ( defined $self->{time} ) {
    if ( defined $other->{time} ) {
      if (  defined $self->{timezone_offset}
        and defined $other->{timezone_offset} )
      {
        $result =
          $self->{time} -
          $self->{timezone_offset} <=> $other->{time} -
          $other->{timezone_offset};
      }
      else {
        $result = $self->{time} <=> $other->{time};
      }
    }
    else {
      $result = 1;    # defined > undef
    }
  }
  else {
    if ( defined $other->{time} ) {
      $result = -1;    # undef < defined
    }
    else {
      $result = 0;     # undef == undef
    }
  }
  $result = -$result if $swap;
  return $result;
}

=head2 identical

  $bool = $t1->identical($t2);

Returns a true value if the two timestamps are identical, and a false
value otherwise.  The two timestamps are identical if the date/time
part and the timezone offset part are identical in both.  This method
returns false for two timestamps that indicate the same instant of
time but have different timezone parts.

=cut

sub identical {
  my ( $self, $other, $swap ) = @_;
  return if defined( $self->{time} ) != defined( $other->{time} );
  return
    if defined( $self->{timezone_offset} ) !=
    defined( $other->{timezone_offset} );

  # now each of the components either is defined in both objects or is
  # not defined in both objects
  if ( defined $self->{time} ) {
    if ( defined $self->{timezone_offset} ) {
      return ( $self->{time} == $other->{time}
          && $self->{timezone_offset} == $other->{timezone_offset} );
    }
    else {
      return $self->{time} == $other->{time};
    }
  }
  else {
    if ( defined $self->{timezone_offset} ) {
      return $self->{timezone_offset} == $other->{timezone_offset};
    }
    else {
      return 1;
    }
  }
}

# MODIFY

=head2 set_from_text

  $t->set_from_text($text);

Sets C<$t> to the instant of time expressed by text C<$text>,
discarding any previous contents of C<$t>.

The text must specify at least a time, and optionally also a date and
a timezone offset.

The date must consist of three numbers (year, month, day) separated by
either a colon C<:> or a dash C<->.  The time must consist of from one
to three numbers (hour, minute, second) separated by a colon C<:>.
The date and time must be separated by a single whitespace or a
capital T.

An offset from UTC may be specified, as from one to three numbers, of
which the first one must be signed and represents hours, and the
remaining ones (if specified) must be separated from the previous by a
colon C<:>, and represent minutes and seconds.

These formats include the format of Exif timestamps, for example
C<'2010:06:27 17:44:12+03:00:00'> or C<'2010:06:27 17:50:00'>, and
also the ISO 8601 formats C<'2010-06-27T17:44:12+03:00'> or
C<'2010-06-27T17:50:00'>.

The example timestamps with timezone offset represent June 27th of the
year 2010, at 44 minutes and 12 seconds past 5 o'clock in the
afternoon, in a timezone where the clock reads 3 hours later than UTC.
The corresponding UTC time is 14:44:12.

If the text cannot be parsed as a timestamp, then the
C<Image::Synchronize::Timestamp> is left without contents.

Returns C<$t>.

=cut

sub set_from_text {
  my ( $self, $value ) = @_;
  my ( $time, $offset, $has_date );
  if ( defined $value ) {
    if ( $value =~ /^[-+]?\d+$/ )
    {
      $time = $value;
      $has_date = 1;
    }
    else {
      ( $time, $offset, $has_date ) = parse_( $value );
    }
  }
  delete $self->{$_} foreach qw(time timezone_offset has_date);
  $self->{time}            = $time   if defined $time;
  $self->{timezone_offset} = $offset if defined $offset;
  $self->{has_date} = $has_date if defined $has_date;
  return $self;
}


=head2 adjust_timezone_offset

  $t->adjust_timezone_offset($offset);

Adjusts the timezone offset of C<$t> to <$offset>, if C<$t> is not
empty.

If C<$t> already had a timezone offset, then its clock time is
adjusted so it refers to the same instant of time as before, but now
relative to the new timezone.

If C<$offset> is C<undef>, then the timezone of C<$t> becomes
undefined.

Returns the object.

=cut

sub adjust_timezone_offset {
  my ( $self, $offset ) = @_;
  if ( defined $offset ) {
    if ( defined $self->{timezone_offset} ) {    # already have a timezone
      $self->{time} += $offset - $self->{timezone_offset};
    }
    $self->{timezone_offset} = $offset;
  }
  else {
    delete $self->{timezone_offset};
  }
  $self;
}

=head2 adjust_to_local_timezone

  $t->adjust_to_local_timezone

Adjusts the timezone of timestamp C<$t> to the local timezone
appropriate for the local system at the indicated instant of time.

If C<$t> already had a timezone offset, then adjusts the clock time so
it refers to the same instant of time as before but now relative to
the local timezone.

Returns the adjusted C<$t>.

=cut

sub adjust_to_local_timezone {
  my ($self) = @_;
  $self->adjust_timezone_offset( $self->local_timezone_offset );
}

=head2 adjust_to_utc

  $t->adjust_to_utc

Adjusts the timezone of timestamp C<$t> to UTC, if C<$t> is not an
empty timestamp.

If C<$t> already had a timezone offset, then adjusts the clock time so
it refers to the same instant of time as before but now relative to
UTC.

Returns the adjusted C<$t>.

=cut

sub adjust_to_utc {
  my ($self) = @_;
  $self->adjust_timezone_offset(0) if defined $self->{time};
}

=head2 set_timezone_offset

  $t->set_timezone_offset($offset);

Sets the timezone offset of C<$t> to <$offset>, discarding the
previous timezone offset if any.  The clock time is not adjusted.

If C<$offset> is C<undef>, then the timezone of C<$t> becomes
undefined.

Returns the object.

=cut

sub set_timezone_offset {
  my ( $self, $offset ) = @_;
  if ( defined $offset ) {
    $self->{timezone_offset} = $offset;
  }
  else {
    delete $self->{timezone_offset};
  }
  $self;
}


=head2 remove_timezone

  $t->remove_timezone

Removes the timezone offset from timestamp C<$t>.  The clock time
remains the same.

Returns the modified C<$t>.

=cut

sub remove_timezone {
  my ($self) = @_;
  delete $self->{timezone_offset};
  return $self;
}

=head2 adjust_nodate

  $t->adjust_nodate;

If timestamp C<$t> has a date, then remove that date by changing C<$t>
to the no-date form.  The offset from the epoch in seconds is instead
interpreted as an offset from an unspecified zero point that is not
associated with a particular date.

A timestamp with no date gets stringified to an optionally signed
timestamp consisting of hours, minutes, and seconds, optionally with a
timezone offset.  The number of hours in the timestamp may be much
greater than 24.

=cut

sub adjust_nodate {
  my ($self) = @_;
  delete $self->{has_date};
  return $self;
}

=head2 adjust_todate

  $t->adjust_todate;

If timestamp C<$t> has no date, then add a date by changing C<$t> to
the with-date form.  The offset from an unspecified zero point not
associated with any particular date is instead interpreted as the
offset from the epoch.

=cut

sub adjust_todate {
  my ($self) = @_;
  $self->{has_date} = 1;
  return $self;
}

# Private helper functions, not part of the official interface

sub parse_components_ {
  my ($text) = @_;
  return unless $text;

  # process date and time and timezone
  # Date = Y-M-D or Y:M:D
  # Time = H:M:S or H:M or H
  # Timezone = Z or -H or +H or -H:M or +H:M or -H:M:S or +H:M:S
  # S = space or T
  # complete = DateSTimeTimezone
  #         or DateSTime
  #         or TimeTimezone
  #         or SignTimeTimezone
  if (
      $text =~ /^
                (?:             # start date + hour or signed hour
                  (?:           # start date + hour
                    (?:         # start date
                      (?<year>\d+)
                      ([-:])
                      (?<month>\d+)
                      \g{-2}    # same separator as for year - month
                      (?<day>\d+)
                      [ T]      # separator is space or T
                    )           # end date
                    (?<hour>\d+)
                  )             # end date + hour
                |
                  (?:           # start optionaly signed hour
                    (?<hoursign>[-+])? # sign is optional
                    (?<hour>\d+)
                  )             # end optionally signed hour
                )               # end date + hour or signed hour
                (?:
                  :             # separator hour - minute
                  (?<minute>\d+)
                )?              # minute is optional
                (?:
                  :             # separator minute - second
                  (?<second>\d+)
                )?              # second is optional
                (?:             # start timezone
                  (?<tzutc>Z)   # Z means UTC
                |
                  (?:           # start numeric timezone
                    (?<tzsign>[-+]) # sign is required
                    (?<tzhour>\d+)
                    (?:         # start timezone minute
                      :         # separator hour - minute
                      (?<tzminute>\d+)
                    )?          # minute is optional
                    (?:
                      :           # separator timezone minute - second
                      (?<tzsecond>\d+)
                    )?          # second is optional
                  )             # end numeric timezone
                )?              # end timezone, timezone is optional
              $/x
    )
  {    # timezone
    my $offset;
    if ( $+{tzutc} ) {    # timezone is UTC
      $offset = 0;
    }
    elsif ( $+{tzsign} ) {
      $offset = $+{tzhour} * 3600;
      $offset += $+{tzminute} * 60 if $+{tzminute};
      $offset += $+{tzsecond} if $+{tzsecond};
      $offset = -$offset if $+{tzsign} eq '-';
    }
    my @c = map { defined($_) ? 1 * $_ : $_ }
      (
       $+{year},  $+{month},  $+{day},
       $+{hour}, $+{minute}, $+{second},
       $offset
     );
    if (defined($+{hoursign}) && $+{hoursign} eq '-') {
      foreach my $i (qw(3 4 5)) {
        if (defined $c[$i]) {
          $c[$i] *= -1;
        }
      }
    }
    return @c;
  }
  else {
    return ();
  }
}

sub components_to_time_and_offset_ {
  my @components = @_;
  $components[$_] //= 0 foreach 3 .. 5;    # hours .. seconds
  my ($time, $has_date);
  if (defined $components[0]) {
    # have year-month-day too
    eval {
      $time = timegm_modern(
                     $components[5], $components[4], $components[3],
                     $components[2], $components[1] - 1,
                     $components[0]
                   );
    };
    return if $@;               # unparseable time
    $has_date = 1;
  } else {
    $time = $components[3]*3600 + ($components[4] // 0)*60
      + ($components[5] // 0);
  }
  return ( $time, $components[6], $has_date );
}

# a private sub to parse a timestamp
sub parse_ {
  my ($text) = @_;
  return unless $text;
  my @components = parse_components_($text);

  # components:
  #       0      1    2     3       4       5       6
  #   (year, month, day, hour, minute, second, offset)

  # must have at least the hour
  return unless defined $components[3];
  return components_to_time_and_offset_(@components);
}

sub display_tz_ {
  my ($offset) = @_;
  my $tz = '';
  if ( defined $offset ) {
    if (Image::Synchronize::Timestamp->istypeof($offset)) {
      if ($offset->has_date) {
        $offset = $offset->clone->adjust_nodate;
      }
      return "$offset";
    } else {
      use integer;

      my $sign = ($offset < 0)? '-': '+';
      $offset = abs($offset);
      my $tzhour = $offset / 3600;
      $offset -= 3600 * $tzhour;
      my $tzmin = $offset / 60;
      $offset -= 60 * $tzmin;
      if ($offset) {
        $tz = $sign . sprintf( '%02d:%02d:%02d', $tzhour, $tzmin, $offset );
      } else {
        $tz = $sign . sprintf( '%02d:%02d', $tzhour, $tzmin );
      }
    }
  }
  return $tz;
}

sub display_one_ {
  my ( $time, $offset, $has_date, $date_separator,
       $date_time_separator ) = @_;
  return unless defined $time;
  if ($has_date) {
    my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime($time);
    my $tz = '';
    if (defined $offset) {
      if ($offset eq 'Z') {
        $tz = 'Z';
      } else {
        $tz = display_tz_($offset);
      }
    }
    my $format = '%d'
      . $date_separator . '%02d'
      . $date_separator . '%02d'
      . $date_time_separator
      . '%02d:%02d:%02d';
    return
      sprintf( $format, $year + 1900, $mon + 1, $mday, $hour, $min, $sec )
      . $tz;
  } else {
    return display_tz_($time) . display_tz_($offset);
  }
}

sub display_utc_one_ {
  my ($time) = @_;
  return unless defined $time;
  my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime($time);
  return sprintf(
    '%d-%02d-%02dT%02d:%02d:%02dZ',
    $year + 1900,
    $mon + 1, $mday, $hour, $min, $sec
  );
}

# identify the type of the value in a non-empty string, either the
# name of the package (if an object), or the reference type (if a
# reference), or '-undef-' (if undef), or '-scalar-'.
sub identify {
  my ($value) = @_;
  if ( ref $value ) {
    return ( blessed($value) or ref($value) );
  }
  return defined($value)? '-scalar-': '-undef-';
}

=head1 AUTHOR

Louis Strous E<lt>LS@quae.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2020 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
