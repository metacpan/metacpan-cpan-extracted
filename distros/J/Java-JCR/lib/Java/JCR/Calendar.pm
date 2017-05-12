package Java::JCR::Calendar;

use strict;
use warnings;

our $VERSION = '0.05';

use Carp;
use Scalar::Util qw( blessed );

=head1 NAME

Java::JCR::Calendar - Utilities for converting dates

=head1 SYNOPSIS

  # With DateTime
  use DateTime;

  # Set
  my $datetime = DateTime->now;
  $node->set_property('date', $datetime);

  # Get
  my $datetime = $property->get_date; # DateTime object 

  # With Class::Date
  use Class::Date qw( now );

  # Set
  my $class_date = now;
  $node->set_property('date', $class_date);

  # Get
  my $class_date = $property->get_date('Class::Date'); # Class::Date

  # With a custom date class
  Java::JCR::Calendar->register_date_conversion(
      'My::Date::Class', \&my_date_class_inflate, \&my_date_class_deflate);

  # Set
  my $my_date = My::Date::Class->right_now;
  $property->set_date('date', $my_date);

  # Get
  my $my_date = $property->get_date('My::Date::Class');

  # Or make it the default:
  Java::JCR::Calendar->default_date_class('My::Date::Class');
  my $my_date = $property->get_date;
      

=head1 DESCRIPTION

This class helps make the translation from C<java.lang.Calendar> to a Perl date/time object as seamless as possible. Since Perl has a plethora of date/time classes and everyone seems to have their own favorite based upon functionality and performance characteristics, I've tried to make this configurable enough that if your favorite isn't supported, you may add it very easily.

Currently, this class ships with support for the following (if installed):

=over

=item 1.

L<DateTime>

=item 2.

L<Class::Date>

=back

For each of the classes above, a date conversion will be registered if the class can be loaded (i.e., it's installed). The first date conversion registered will be made the default date class.

I've chosen these classes based upon my experience and knowledge of their development and developers. L<DateTime> is the obvious first choice since it's the most actively developed and best supported module. If you would like to see an additional module supported in the L<Java::JCR> distribution, please send patches to my email address (listed in L</"AUTHOR">) and I will consider it for a future release.

If none of the above date classes is available and you haven't registered a date conversion for another class, you can't use JCR dates directly. The JCR will convert any date to or from an ISO 8601 string if you use the string accessor/mutators rather than the date accessor/mutators. Any fallback solution I could come up with would be redundant.

=head1 HOW IT WORKS

The goal of this class is to be seamless. Therefore, any method that would return a C<java.util.Calendar> object in the JCR API has been wrapped to return a Perl date object. By default, this date class is L<DateTime>.

  my $date = $property->get_date;
  print "Property set to date: ", $date->ymd, "\n";

However, if you want a different date class, you may specify the name of the class to use as the last argument to the method. The class specified must have a registered date conversion, or an exception will be thrown. 

  my $date = $property->get_date('Class::Date');
  print "Property set to date: ", $date->ymd, "\n";

As an alternative to specifying a different class every time, you may also change which class is used by default using the C<default_date_class()> method (see L</"METHODS">).

  Java::JCR::Calendar->default_date_class('Class::Date');
  my $date = $property->get_date; # returns a Class::Date object
  print "Property set to date: ", $date->ymd, "\n";

When a JCR method accepts a C<java.util.Calendar> object as an argument, you may use any date class with a registered date conversion and pass that to the method.

This class, with the help of the registered date conversions, automatically converts the date between the Perl object and a C<java.util.Calendar> object.

If you wish to use a date class for which no date conversion is provided, you may register a date conversion for that class by providing and inflation and deflation method to the C<register_date_conversion()> method (see L</"METHODS">).

  package MySuperSimpleDate;

  sub new {
      my ($class, %hash) = @_;
      return bless \%hash, $class;
  }

  sub ymd {
      my ($self) = @_;
      return $self->{year}.'-'.$self->{month}.'-'.$self->{day};
  }

  sub inflate {
      my ($hash) = @_;
      return MySuperSimpleDate->(%$hash);
  }

  sub deflate {
      my ($date) = @_;
      my %hash = %$date;
      return \%hash;
  }

  package main;

  Java::JCR::Calendar->register_date_conversion(
      'MySuperSimpleDate', 
      \&MySuperSimpleDate::inflate, 
      \&MySuperSimpleDate::deflate,
  );

  my $date = $property->get_date('MySuperSimpleDate');
  print "Property set to date: ", $date->ymd, "\n";

  # Or even make it the default:
  Java::JCR::Calendar->default_date_class('MySuperSimpleDate');
  my $date = $property->get_date;
  print "Property set to date: ", $date->ymd, "\n";

Basically, you should be able to use dates however you like with the JCR without putting much thought into it. 

This is, in my opinion, some nice DWIMmery and adheres to TMTOWTDI and really didn't take much effort on my part either, Viva la Perl!

=head1 METHODS

Here are the methods for choosing how to use dates:

=over

=item Java::JCR::Calendar->register_date_conversion($class, \&inflater, \&deflater)

This registers a new conversion handler for the class, C<$class>. 

Whenever the end-user specifies the class, C<$class>, for a date accessor, the inflation method, C<\&inflater>, will be called to convert the date from an hash of values to date object blessed into the class, C<$class>.

Whenever the end-user uses a date mutator and passes an object blessed into the given class, C<$class>, the deflation method, C<\&deflater>, is used to convert the date object into a hash of values.

The hash of values given to the inflation method and to be returned by the deflation method, will look something like this:

  {
      year       => 2006,
      month      => 6,
      day        => 17,
      hour       => 11,
      minute     => 38,
      second     => 44,
      nanosecond => 42_563_889,
      timezone   => 'America/Chicago',
      locale     => 'en_US',
      lenient    => 1,
  }

The hash returned during inflation must set the date fields (year, month, and day), but all the other fields are optional. See below for the values chosen if your deflation function doesn't set a field.

Here is the detailed description for each field:

=over

=item year

This is the year. Use positive values to represent AD/CE years. Use negative values to represent BC/BCE years. (0 is not a valid year and will result in an exception.)

=item month

This is the month of the year. Values must fall within the range of 1 to 12. 

Values outside this range will result in an exception unless "lenient" is set to a true value.

=item day

This is the day of the month. Values must fall within the range of 1 to 31, though the upper limit is month dependent. 

If you set the value to an invalid day for the given month, an exception will be thrown unless "lenient" is set to a true value.

=item hour

This is the hour of the day. Values must fall within the range of 0 to 23. If not specified, this value will be set to 0. 

If you set the value outside this range an exception will be thrown unless "lenient" is set to a true value.

=item minute

This is the minute of the hour. Values must fall within the range of 0 to 59. If not specified, this value will be set to 0.

Values outside this range will cause an exception to be thrown unless "lenient" is set to a true value.

=item second

This is the second of the minute. Values must fall within the range of 0 to 59. If not specified, this value will be set to 0.

Any value given outside of this range will result in an exception unless "lenient" is set to a true value.

=item nanosecond

This is the the nanoseconds within the current second. Values must fall within the range of 0 to 999,999,999. If not specified, this value will be set to 0.

If the value given is outside of this range and exception will be thrown unless "lenient" is set to a true value.

=item timezone

This is the time zone of the date and time. The values available for this may either be numeric offsets from UTC. These offsets can have the following formats:

  GMT-6
  GMT+10
  GMT+230
  GMT+10:45

The time zone may also be specified as a named zone (which is usually better because named zones can cope with local rules dealing with Daylight Savings Time and other adjustments---such as new legislation changing DST). However, Java doesn't specify a standard that is followed for picking which named time zones are available (if any). Therefore, it's up to your JVM to present a sane collection. However, it's generally safe to assume that time zones from the Olson time zone database will be available.

Since L<DateTime::TimeZone> uses the Olson database for it's time zones, you may use that as a reference.

If no time zone is specified during deflation, Java will be told to assume the default time zone. The default is generally the local time zone, but may vary depending upon your JVM configuration.

=item locale

I'm not certain if this is actually significant to how the JCR stores a calendar object, but I've included it for completeness (and it doesn't require much in the way of extra effort either way).

The locale must be specified using the ISO-639 and ISO-3166 standards with the possiblity of vendor or browser-specific variant codes. See the Javadoc for C<java.util.Locale> if you want more specific details.

If no locale is specified during deflation, the default Java locale will be used.

=item lenient

By setting this to a true value, the C<java.util.Calendar> object will have the lenient setting set to true. This will allow you to specify month, day, hour, minute, second, and nanosecond values outside the normal range without throwing an exception. Such values will result in a roll-over rather than an exception.

This value defaults to false. Thus, if it isn't given, an exception will be thrown when an out of bounds value is given.

The hash given to the inflation function will always have this value set to false. However, your inflation function may be as lenient or strict as desired. The Calendar implementation on your JVM should return valid dates, so it shouldn't be an issue in any case.

=back

All dates are, obviously, according to the Gregorian calendar, which is due to the fact that the Calendar API of Java only fully supports Gregorian-style calendars. However, since we're using Perl, we're not limited to that calendar. If you want to, you may use one of the L<DateTime> calendar modules to use Chinese, Christian, Coptic, Discordian, French revolutionary, Hebrew, Hijiri, Japanese, Julian, Mayan, Pataphysical, or even Middle-earth Shire dates. However, all dates stored in the JCR must be according to the Gregorian calendar.

The inflation function, C<\&inflater>, can expect a single argument, which is the hash (as described above), containing all the above fields filled. The inflation function must return an object of the specified class, C<$class>, or throw an exception. Your function must not return C<undef>.

During inflation, the hash will be created by reading in the fields set on the C<java.util.Calendar> object returned by the JCR.

The deflation function, C<\&deflater>, can expect a single argument, which is an object blessed into the specified class, C<$class>. The deflation function must return a hash containing the date (as described above). The date fields must be set.

During deflation, a C<java.util.Calendar> object will be created by fetching a Calendar instance according to the time zone and locale specified in the hash returned by the C<\&deflater> function. Then, each field will be set in the following order: year, month, day, hour, minute, second, and nanosecond. If a time field isn't given, the default value listed above will be set on that field. Setting in this order will ensure that roll-overs will be handled 

=cut

my $default_date_class;
my %date_conversions;

sub register_date_conversion {
    my ($class, $date_class, $inflater, $deflater) = @_;

    $date_conversions{$date_class} = {
        inflater => $inflater,
        deflater => $deflater,
    };
}

=item Java::JCR::Calendar->default_date_class($class)

Specify the default date class to use when none is specified. This affects any JCR method which returns a date. On any such method, you may specify the date class to use explicitly by using the class name as the last argument to the method. However, if you do not specify a class name, the default class name is used instead.

The default class name is specified by calling this method and giving it a class name, C<$class>.

If you set the class name, C<$class>, to C<undef>, you are requiring the specification of a date class on any method that returns a date. If no date class is given when the default has been set to C<undef>, an exception will be thrown.

=cut

sub default_date_class {
    my ($class, $date_class) = @_;
    $default_date_class = $date_class;
}

=back

=cut

sub _perl_date_has_conversion {
    my ($date) = @_;

    my $class = blessed $date;

    return !defined $class                    ? 0
         :  defined $date_conversions{$class} ? 1
         :                                      0;
}

sub _perl_date_to_java_calendar {
    my ($date) = @_;

    my $class = blessed $date;

    croak 'Cannot use an unblessed date object' if not defined $class;
    croak qq(No Perl-to-Java date conversion is available for "$class")
        if not defined $date_conversions{$class};

    my $conversion = $date_conversions{$class};

    my $deflater = $conversion->{deflater};

    return Java::JCR::JavaUtils::hash_to_calendar($deflater->($date));
}

sub _java_calendar_to_perl_date {
    my ($calendar, $class) = @_;

    $class ||= $default_date_class;

    croak 'Cannot convert date from Java to Perl: ',
          'No date class was given and no default is available.'
        if not defined $class;
    croak qq(No Java-to-Perl date conversion is available for "$class")
        if not defined $date_conversions{$class};

    my $conversion = $date_conversions{$class};

    my $inflater = $conversion->{inflater};

    return $inflater->(Java::JCR::JavaUtils::calendar_to_hash($calendar));
}

eval 'use DateTime';
if (!$@) {
    __PACKAGE__->register_date_conversion(
        'DateTime',
        sub { # inflater
            my ($hash) = @_;

            my $time_zone = $hash->{timezone};
            $time_zone =~ s/^GMT([-+])/$1/;

            return DateTime->new(
                year       => $hash->{year},
                month      => $hash->{month},
                day        => $hash->{day},
                hour       => $hash->{hour},
                minute     => $hash->{minute},
                second     => $hash->{second},
                nanosecond => $hash->{nanosecond},
                time_zone  => $time_zone,
            );
        },
        sub { # deflater
            my ($date) = @_;
            my $hash = {
                year       => $date->year,
                month      => $date->month,
                day        => $date->day,
                hour       => $date->hour,
                minute     => $date->minute,
                second     => $date->second,
                nanosecond => $date->nanosecond,
            };

            my $tz = $date->time_zone;
            if ($tz->is_olson) {
                $hash->{timezone} = $tz->name;
            }

            elsif ($tz->is_utc) {
                $hash->{timezone} = 'UTC';
            }

            elsif (!$tz->is_floating) {
                $hash->{timezone} 
                    = 'GMT'.DateTime::TimeZone->offset_as_string(
                        $tz->offset_for_datetime($date)
                    );
            }

            # else floating, let Java use the default

            return $hash;
        },
    );

    __PACKAGE__->default_date_class('DateTime');
}

eval 'use Class::Date';
if (!$@) {
    __PACKAGE__->register_date_conversion('Class::Date',
        sub { # inflater
            my ($hash) = @_;
            
            return Class::Date->new([
                $hash->{year},
                $hash->{month},
                $hash->{day},
                $hash->{hour},
                $hash->{minute},
                $hash->{second},
            ], $hash->{timezone});
        },
        sub { # deflater
            my ($date) = @_;

            return {
                year     => $date->year,
                month    => $date->month,
                day      => $date->day,
                hour     => $date->hour,
                minute   => $date->minute,
                second   => $date->second,
                timezone => $date->tz,
            };
        },
    );

    if (!defined $default_date_class) {
        __PACKAGE__->default_date_class('Class::Date');
    }
}
                
=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
