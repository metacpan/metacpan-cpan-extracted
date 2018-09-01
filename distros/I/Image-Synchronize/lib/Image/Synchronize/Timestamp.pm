package Image::Synchronize::Timestamp;

=head1 NAME

Image::Synchronize::Timestamp - a timestamp class

=head1 SYNOPSIS

  # parse Exif timestamp text with offset from UTC
  $t = Image::Synchronize::Timestamp->new('2010:06:27 17:44:12+03:00');

  # or with - as date component separator
  $t = Image::Synchronize::Timestamp->new('2010-06-27 17:44:12+03:00');

  # or with T as date/time separator (ISO 8601)
  $t = Image::Synchronize::Timestamp->new('2010-06-27T17:44:12+03:00');

  # or without timezone offset
  $t2 = Image::Synchronize::Timestamp->new('2010:06:27 17:50:00');

  # number of non-leap seconds since the epoch
  $time_local = $t->time_local; # in local timezone
  $time_utc = $t->time_utc;     # in UTC

  $offset = $t->offset_from_utc; # in seconds

  $t3 = $t->clone;              # clone
  $t == $t3;                    # test equality
  $t != $t2;                    # test inequality
  print "$t";                   # back to text format

=head1 SUBROUTINES/METHODS

=cut

use warnings;
use strict;

use Carp;
use Scalar::Util qw(blessed looks_like_number);
use Time::Local;

use parent 'Exporter';

use overload
  '='   => \&clone,
  '-'   => \&subtract,
  '+'   => \&add,
  '""'  => \&stringify,
  '<=>' => \&three_way_cmp,
  'cmp' => \&three_way_cmp;

sub identify {
  my ($value) = @_;
  if ( ref $value ) {
    return ( blessed($value) or ref($value) );
  }
  return 'scalar';
}

=head2 new

  $t = Image::Synchronize::Timestamp->new;
  $t = Image::Synchronize::Timestamp->new($value);

Construct a new instance.  If C<$value> is a number, then it is taken
to represent the number of seconds since the epoch (in UTC).  If
C<$value> is defined but is not a number, then it is parsed as a
timestamp in text format.  See L<set_from_text> for details of the
supported formats.

If C<$value> is specified but no timestamp can be extracted from it,
then returns C<undef>.  If C<$value> is not specified, then returns an
empty instance.

=cut

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  if ( scalar(@_) == 1 ) {
    my ($value) = @_;
    if ( looks_like_number($value) ) {
      $self->{time}            = $value;
      $self->{offset_from_utc} = 0;        # assume UTC
    }
    else {
      $self->set_from_text($value);
    }
    return undef unless defined $self->{time};
  }
  elsif ( scalar(@_) == 2 ) {
    $self->set_from_text(@_);
  }
  elsif ( scalar(@_) ) {
    croak "Expected 1 or 2 arguments, found " . scalar(@_);
  }
  return $self;
}

=head2 istypeof

  $ok = Image::Synchronize::Timestamp->istypeof($item);

Returns a true value if C<$item> is an instance of (a subclass of)
Image::Synchronize::Timestamp, and a false value otherwise.

=cut

sub istypeof {
  my ( $class, $value ) = @_;
  return blessed($value) && $value->isa($class);
}

=head2 time_local

  $time = $t->time_local;       # range beginning or instant
  @times = $t->time_local;      # range beginning and end

In list context, returns the number of non-leap seconds since the
epoch in the timezone associated with the timestamp, for both the
range beginning and range end -- or C<undef> for whichever of those
isn't included in C<$t>.

In scalar context, returns the value for the range beginning (or
single instant) only.

=cut

sub time_local {
  my ($self) = @_;
  return $self->{time};
}

=head2 time_utc

  $time = $t->time_utc;

Returns the number of non-leap seconds since the epoch in UTC, or
C<undef> if the timestamp is empty or has no timezone offset.

=cut

sub time_utc {
  my ($self) = @_;
  my $value = $self->{time} - $self->{offset_from_utc}
    if defined( $self->{time} )
    and defined( $self->{offset_from_utc} );
  return $value;
}

=head2 has_timezone_offset

  Returns a true value if timestamp C<$t> has a timezone offset, and a
  false value otherwise.

=cut

sub has_timezone_offset {
  my ($self) = @_;
  return defined $self->{offset_from_utc};
}

sub contains_local {
  my ( $self, $time ) = @_;
  return $self->{time} == $time;
}

=head2 offset_from_utc

  $offset = $t->offset_from_utc;

Returns the timezone offset from UTC in seconds, or C<undef> if no
timezone offset is known.

=cut

sub offset_from_utc {
  my ($self) = @_;
  return $self->{offset_from_utc};
}

=head2 clone

  $t2 = $t->clone;

Returns a clone of the specified C<Image::Synchronize::Timestamp>.

=cut

sub clone {
  my ($self) = @_;
  my $clone = Image::Synchronize::Timestamp->new;
  $clone->{$_} = $self->{$_} foreach keys %$self;
  return $clone;
}

=head2 identical

  $t1->identical($t2);

Returns C<true> if the two C<Image::Synchronize::Timestamp> are identical, and
C<false> otherwise.  They are identical if both the time and the
timezone offset are equal in both.

=cut

sub identical {
  my ( $self, $other, $swap ) = @_;
  return if defined( $self->{time} ) != defined( $other->{time} );
  return
    if defined( $self->{offset_from_utc} ) !=
    defined( $other->{offset_from_utc} );

  # now each of the components either is defined in both objects or is
  # not defined in both objects
  if ( defined $self->{time} ) {
    if ( defined $self->{offset_from_utc} ) {
      return ( $self->{time} == $other->{time}
          && $self->{offset_from_utc} == $other->{offset_from_utc} );
    }
    else {
      return $self->{time} == $other->{time};
    }
  }
  else {
    if ( defined $self->{offset_from_utc} ) {
      return $self->{offset_from_utc} == $other->{offset_from_utc};
    }
    else {
      return 1;
    }
  }
}

=head2 <=>

  $t1 <=> $t2;

Returns -1, zero, or 1 depending on whether C<$t1> indicates an
earlier, equal, or later instant of time than C<$t2>.

=cut

sub three_way_cmp {
  my ( $self, $other, $swap ) = @_;
  croak "Found a " . identify($self) . ", need a " . __PACKAGE__ . "\n"
    unless Image::Synchronize::Timestamp->istypeof($self);
  unless ( Image::Synchronize::Timestamp->istypeof($other) ) {
    my $converted = Image::Synchronize::Timestamp->new($other);
    croak "Not a timestamp: $other\n" unless $converted;
    $other = $converted;
  }
  my $result;
  if ( defined $self->{time} ) {
    if ( defined $other->{time} ) {
      if (  defined $self->{offset_from_utc}
        and defined $other->{offset_from_utc} )
      {
        $result =
          $self->{time} -
          $self->{offset_from_utc} <=> $other->{time} -
          $other->{offset_from_utc};
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

=head2 -

  $difference = $t2 - $t1;

Returns the difference (in seconds) between the two timestamps C<$t2>
and C<$t1>.  If at least one of the two does not have a timezone
offset, then both timestamps are assumed to be in the same timezone.

=cut

sub subtract {
  my ( $self, $other, $swap ) = @_;
  if ( Image::Synchronize::Timestamp->istypeof($other) ) {
    return undef
      unless defined( $self->{time} )
      and defined( $other->{time} );
    my $difference = $self->{time} - $other->{time};
    if (  defined( $self->{offset_from_utc} )
      and defined( $other->{offset_from_utc} ) )
    {
      $difference += $other->{offset_from_utc} - $self->{offset_from_utc};
    }
    $difference = -$difference if $swap;
    return $difference;
  }
  else {
    my $result = $self->clone;
    $result->{time} -= $other;
    return $result;
  }
}

=head2 +

  $sum = $t + $seconds;
  $sum = $seconds + $t;

Returns the timestamp that is C<$seconds> later than timestamp C<$t>.

=cut

sub add {
  my ( $self, $other, $swap ) = @_;
  if ( Image::Synchronize::Timestamp->istypeof($other) ) {
    croak "Sorry, cannot add two Image::Synchronize::Timestamps\n";
  }
  my $result = $self->clone;
  $result->{time} += $other;
  return $result;
}

=head2 combine

  $t3 = $t1->combine($t2);

Returns a clone of C<$t1> with undefined parts (time or time zone
offset) copied from C<$t2>.  C<$t1> and C<$t2> are not modified.

=cut

sub combine {
  my ( $self, $other ) = @_;
  my $result = $self->clone;
  $result->{$_} //= $other->{$_} foreach keys %$other;
  return $result;
}

sub parse_components_ {
  my ($text) = @_;
  return unless $text;

  # process date and time and timezone
  # Date = Y-M-D or Y:M:D
  # Time = H:M:S
  # Timezone = Z or -H or +H or -H:M or +H:M or -H:M:S or +H:M:S
  # S = space or T
  # complete = DateSTimeTimezone
  #         or DateSTime
  #         or TimeTimezone
  if (
    $text =~ /(?:
                (?<year>\d+)
                ([-:])
                (?<month>\d+)
                \g{-2}
                (?<day>\d+)
                [ T])?
                (?<hour>\d+)
                (?::(?<minute>\d+))?
                (?::(?<second>\d+))?
                (?:(?<tzutc>Z)  # Z means UTC
                |(?:(?<tzsign>[-−+])
                    (?<tzhour>\d+)
                    (?::(?<tzminute>\d+))?
                    (?::(?<tzsecond>\d+))?
                ))?/x
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
    return map { defined($_) ? 1 * $_ : $_ } (
      $+{year},   $+{month},  $+{day}, $+{hour},
      $+{minute}, $+{second}, $offset
    );
  }
  else {
    return ();
  }
}

sub components_to_time_and_offset_ {
  my @components = @_;
  $components[$_] //= 0 foreach 3 .. 5;    # hours .. seconds
  my $time;
  eval {
    $time = timegm(
      $components[5], $components[4], $components[3], $components[2],
      $components[1] - 1,
      $components[0] - 1900
    );
  };
  return if $@;                            # unparseable time
  return ( $time, $components[6] );
}

# a private sub to parse a timestamp
sub parse_ {
  my ($text) = @_;
  return unless $text;
  my @components = parse_components_($text);

  # components:
  #       0      1    2     3       4       5       6
  #   (year, month, day, hour, minute, second, offset)

  # must have at least year-month-day-hour for the range beginning
  return
        unless defined $components[0]
    and defined $components[1]
    and defined $components[2]
    and defined $components[3];
  return components_to_time_and_offset_(@components);
}

sub display_one_ {
  my ( $time, $offset, $format ) = @_;
  return unless defined $time;
  my ( $sec, $min, $hour, $mday, $mon, $year ) = gmtime($time);
  my $tz = '';
  if ( defined $offset ) {
    use integer;

    # assume rounding toward zero
    my $tzhour = $offset / 3600;
    $offset -= 3600 * $tzhour;
    my $tzmin = $offset / 60;
    $offset -= 60 * $tzmin;
    if ($offset) {
      $tz = sprintf( '%+03d:%02d:%02d', $tzhour, abs($tzmin), abs($offset) );
    }
    else {
      $tz = sprintf( '%+03d:%02d', $tzhour, abs($tzmin) );
    }
  }
  $format //= '%d:%02d:%02d %02d:%02d:%02d';
  return
    sprintf( $format, $year + 1900, $mon + 1, $mday, $hour, $min, $sec ) . $tz;
}

=head2 stringify

  $text = $t->stringify;
  $text = "$t";

Returns a text version of C<$t>, in Exif format.  If C<$t> contains no
timezone offset, then the returned text is like C<'2000:01:02
03:04:05'>, showing the year, month, day, hour, minute, and second.
If C<$t> does contain a timezone offset, then that offset gets
appended and is like C<'+06:00'>, showing the signed hour and minute
of the offset with respect to UTC.  If the timezone offset includes a
number of seconds unequal to zero, then that number of seconds is
included in the offset text as well (e.g., C<'+06:00:03'>). These
examples are for timezones where the clock time is approximately 6
hours greater than UTC.

If C<$t> was set from undefined text, then C<< $t->stringify >>
returns C<undef>, and C<"$t"> returns C<''>.

=cut

sub stringify {
  my ($self) = @_;
  return unless defined $self->{time};
  return display_one_( $self->{time}, $self->{offset_from_utc} );
}

=head2 display_iso

  $t->display_iso

Returns a text representation of the timestamp in ISO8601 format, for
example C<2001-02-23T14:47:22+01:00> for a timestamp representing 14
hours 47 minutes 22 seconds (= 22 seconds past 2:47 pm) on February
23rd of 2001.

=cut

sub display_iso {
  my ($self) = @_;
  return unless defined $self->{time};
  my $format = '%d-%02d-%02dT%02d:%02d:%02d';
  return display_one_( $self->{time}, $self->{offset_from_utc}, $format );
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

=head2 display_utc

  $text = $t->display_utc;

Returns a text version of C<$t>, in UTC in ISO 8601 format.  The
returned text is like C<'2000-01-02T03:04:05Z'>, showing the year,
month, day, hour, minute, and second.  If C<$t> includes timezone
information, then that is taken into account.  Otherwise, C<$t> is
assumed to be in UTC already.

If C<$t> was set from undefined text, then C<< $t->display_utc >>
returns C<undef>.

=cut

sub display_utc {
  my ($self) = @_;
  return unless defined $self->{time};
  my @times  = $self->time_utc;
  my $result = display_utc_one_( $times[0] );
  my $second = display_utc_one_( $times[1] );
  $result .= "/$second" if $second;
  return $result;
}

=head2 set_from_text

  $t->set_from_text($text);

Sets C<$t> to the instant of time expressed by text C<$text>,
discarding any previous contents of C<$t>.

The text must specify a date and a time.  The date must consist of
three numbers (year, month, day) separated by either a colon C<:> or a
dash C<->.  The time must consist of three numbers (hour, minute,
second) separated by a colon C<:>.  The date and time must be
separated by a single whitespace or a capital T.

Optionally, an offset from UTC may be specified, as two numbers, of
which the first one must be signed and represents hours, and the
second one must be separated from the first by a colon C<:> and
represents minutes.

These formats include the format of Exif timestamps, for example
C<'2010:06:27 17:44:12+03:00'> or C<'2010:06:27 17:50:00'>, and also
the ISO 8601 formats C<'2010-06-27T17:44:12+03:00'> or
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
  my ( $self, @text ) = @_;
  my ( $time, $offset );
  if ( @text == 1 ) {
    ( $time, $offset ) = parse_( $text[0] );
  }
  elsif ( @text == 2 ) {
    my @components      = parse_components_( $text[0] );
    my @base_components = parse_components_( $text[1] );

    # must have at least year-month-day-hour for the base timestamp
    return
          unless defined $base_components[0]
      and defined $base_components[1]
      and defined $base_components[2]
      and defined $base_components[3];

    ( $time, $offset ) = components_to_time_and_offset_(@base_components);

    if ( defined( $components[3] ) ) {
      $components[4] //= 0;
      $components[5] //= 0;
      my $tod = $components[3] * 3600 + $components[4] * 60 + $components[5];
      my $base_tod = $time % 86400;
      my $d        = $tod - $base_tod;
      $time += $d;
      if ( $d > 43200 ) {

        # time > base + 12 hours; assume time is in previous day so
        # absolute difference is less than 12 hours
        $time -= 86400;
      }
      elsif ( $d <= -43200 ) {

        # time <= base - 12 hours; assume time is in next day so
        # absolute difference is less than 12 hours
        $time += 86400;
      }
    }
  }
  delete $self->{time};
  delete $self->{offset_from_utc};
  $self->{time}            = $time   if defined $time;
  $self->{offset_from_utc} = $offset if defined $offset;
  return $self;
}

=head2 set_timezone_offset_if_not_set

  $t->set_timezone_offset_if_not_set($offset);

Sets the timezone offset of C<$t> to C<$offset>, unless C<$t> already
has a timezone offset, in which case C<$t> is not modified.

Returns C<$t>.

=cut

sub set_timezone_offset_if_not_set {
  my ( $self, $offset ) = @_;
  $self->{offset_from_utc} //= $offset;
  return $self;
}

=head2 set_timezone_offset

  $t->set_timezone_offset($offset);

Sets the timezone offset of C<$t> to <$offset>.  If C<$t> already had
a timezone offset, then adjusts the clock time so it refers to the
same instant of time as before but now relative to the new timezone.

If C<$offset> is C<undef>, then the timezone of C<$t> becomes
undefined.

Returns the object.

=cut

sub set_timezone_offset {
  my ( $self, $offset ) = @_;
  if ( defined $offset ) {
    if ( defined $self->{offset_from_utc} ) {    # already have a timezone
      $self->{time} += $offset - $self->{offset_from_utc};
    }
    $self->{offset_from_utc} = $offset;
  }
  else {
    delete $self->{offset_from_utc};
  }
  $self;
}

=head2 local_offset_from_utc

  $t->local_offset_from_utc

Returns the difference between the local timezone and UTC, in seconds.
The local timezone is the timezone that is valid at the specified time
C<$t> (for the environment of the current process).

=cut

sub local_offset_from_utc {
  my ($self) = @_;
  my @t = localtime( $self->to_utc->time_utc );
  return timegm(@t) - timelocal(@t);
}

=head2 clone_to_local_timezone

  $t->clone_to_local_timezone

Returns a clone of timestamp C<$t> with its timezone set to the local
timezone (for the environment of the current process).

=cut

sub clone_to_local_timezone {
  my ($self) = @_;
  $self->clone->set_to_local_timezone;
}

=head2 set_to_local_timezone

  $t->set_to_local_timezone

Sets the timezone of timestamp C<$t> to the local timezone (for the
environment of the current process).  If C<$t> already had a timezone
offset, then adjusts the clock time so it refers to the same instant
of time as before but now relative to the local timezone.

Returns the adjusted C<$t>.

=cut

sub set_to_local_timezone {
  my ($self) = @_;
  $self->set_timezone_offset( $self->local_offset_from_utc );
}

=head2 set_to_local_timezone_if_not_set

  $t->set_to_local_timezone_if_not_set

Sets the timezone of timestamp C<$t> to the local timezone (for the
environment of the current process) if it has no timezone offset yet.

Returns the adjusted C<$t>.

=cut

sub set_to_local_timezone_if_not_set {
  my ($self) = @_;
  $self->set_timezone_offset_if_not_set( $self->local_offset_from_utc );
}

=head2 remove_timezone

  $t->remove_timezone

Removes the timezone offset from timestamp C<$t>.  The clock time
remains the same.  Returns modified C<$t>.

=cut

sub remove_timezone {
  my ($self) = @_;
  delete $self->{offset_from_utc};
  return $self;
}

=head2 to_utc

  $t->to_utc

Returns a clone of timestamp C<$t> with its timezone set to UTC.

=cut

sub to_utc {
  my ($self) = @_;
  $self->clone->set_to_utc;
}

=head2 set_to_utc

  $t->set_to_utc

Sets the timezone of timestamp C<$t> to UTC.  If C<$t> already had a
timezone offset, then adjusts the clock time so it refers to the same
instant of time as before but now relative to UTC.

Returns the adjusted C<$t>.

=cut

sub set_to_utc {
  my ($self) = @_;
  $self->set_timezone_offset(0);
}

=head2 set_to_utc_if_not_set

  $t->set_to_utc_if_not_set

Sets the timezone of timestamp C<$t> to UTC if it has no timezone offset yet.

Returns the adjusted C<$t>.

=cut

sub set_to_utc_if_not_set {
  my ($self) = @_;
  $self->set_timezone_offset_if_not_set(0);
}

=head2 date

  $t->date;

Returns the date part of the text version (as produced by
L</stringify>) of the timestamp.

=cut

sub date {
  my ($self) = @_;
  my $t = "$self";
  $t =~ /^(.*?) /;
  return $1;
}

=head2 time

  $t->time;

Returns the time part of the text version (as produced by
L</stringify>) of the timestamp -- excluding the timezone, if any.

=cut

sub time {
  my ($self) = @_;
  my $t = "$self";
  $t =~ / (.*?)([-+]|\Z)/;
  return $1;
}

=head1 AUTHOR

Louis Strous E<lt>LS@quae.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2018 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
