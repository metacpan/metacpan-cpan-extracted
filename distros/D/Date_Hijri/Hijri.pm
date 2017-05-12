#!/usr/bin/perl

############################################################
# Date::Hijri
# module for converting islamic (hijri) and gregorian dates
# (c) zeitform Internet Dienste 2003 - alex@zeitform.de
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# based on kcalendarsystemhijri.cpp
#   Copyright (c) 2002-2003 Carlos Moro <cfmoro@correo.uniovi.es>
#   Copyright (c) 2002-2003 Hans Petter Bieker <bieker@kde.org>
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Library General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Library General Public License for more details.
#
#   You should have received a copy of the GNU Library General Public License
#   along with this library; see the file COPYING.LIB.  If not, write to
#   the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#   Boston, MA 02111-1307, USA.
#
# kcalendarsystemhijri.cpp
#   [...] is translated from the Lisp code
#   in ``Calendrical Calculations'' by Nachum Dershowitz and
#   Edward M. Reingold, Software---Practice & Experience,
#   vol. 20, no. 9 (September, 1990), pp. 899--928.
#
#   This code is in the public domain, but any use of it
#   should publically acknowledge its source.
#
# Example usage:
#
# use Date::Hijri;
#
# print join("-", g2h(22,8,2003));  # prints 23-6-1424
# print join("-", h2g(23,6,1424));  # prints 22-8-2003
#
############################################################

package Date::Hijri;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(h2g g2h);

$VERSION = '0.02';

############################################################

use constant IslamicEpoch => 227014;

############################################################

sub g2h
  {
    my ($day, $month, $year) = @_;
    return Absolute2Islamic(Gregorian2Absolute($day, $month, $year));
  }

sub h2g
  {
    my ($day, $month, $year) = @_;
    return Absolute2Gregorian(Islamic2Absolute($day, $month, $year));
  }

sub lastDayOfGregorianMonth
  {
    # Compute the last date of the month for the Gregorian calendar.
    my ($month, $year) = @_;
    if ($month == 2)
      {
	return 29 if ($year % 4 == 0 && $year % 100 != 0) || ($year % 400 == 0);
      }
    return (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$month - 1];
  }

sub Gregorian2Absolute
  {
    # Computes the absolute date from the Gregorian date.
    my ($day, $month, $year) = @_;
    my $N = $day;                          # days this month
    for (my $m = $month - 1; $m > 0; $m--) # days in prior months this year
      {
	$N += lastDayOfGregorianMonth($m, $year);
      }
    return int($N                        # days this year
               + 365 * ($year - 1)       # days in previous years ignoring leap days
	       + ($year - 1) / 4         # Julian leap days before this year...
	       - ($year - 1) / 100       # ...minus prior century years...
	       + ($year - 1) / 400);     # ...plus prior years divisible by 400
  }

sub Absolute2Gregorian
  {
    # Computes the Gregorian date from the absolute date.
    my ($d) = @_;
    # Search forward year by year from approximate year
    my $year = int($d / 366 + 0.5);
    while ($d >= Gregorian2Absolute(1,1,$year+1)) { $year++; }
    # Search forward month by month from January
    my $month = 1;
    while ($d > Gregorian2Absolute(lastDayOfGregorianMonth($month, $year), $month, $year)) { $month++; }
    my $day = $d - Gregorian2Absolute(1, $month, $year) + 1;

    return ($day, $month, $year);
  }

sub IslamicLeapYear
  {
    # True if year is an Islamic leap year
    my ($year) = @_;
    return ((((11 * $year) + 14) % 30) < 11) ? 1 : 0;
  }

sub lastDayOfIslamicMonth
  {
    # Last day in month during year on the Islamic calendar.
    my ($month, $year) = @_;
    return ($month % 2 == 1) || ($month == 12 && IslamicLeapYear($year)) ? 30 : 29;
  }

sub Islamic2Absolute
  {
    # Computes the absolute date from the Islamic date.
    my ($day, $month, $year) = @_;
    return int($day                      # days so far this month
               + 29 * ($month - 1)       # days so far...
               + int($month /2)          # ...this year
               + 354 * ($year - 1)       # non-leap days in prior years
               + (3 + (11 * $year)) / 30 # leap days in prior years
               + IslamicEpoch);          # days before start of calendar
  }

sub Absolute2Islamic
  {
    # Computes the Islamic date from the absolute date.
    my ($d) = @_;
    my ($day, $month, $year);
    if ($d <= IslamicEpoch)
      {
        # Date is pre-Islamic
	$month = 0;
	$day = 0;
	$year = 0;
      }
    else
      {
	# Search forward year by year from approximate year
	$year = int(($d - IslamicEpoch) / 355);
	while ($d >= Islamic2Absolute(1,1,$year+1)) { $year++; }
	# Search forward month by month from Muharram
        $month = 1;
	while ($d > Islamic2Absolute(lastDayOfIslamicMonth($month,$year), $month, $year)) { $month++ }
	$day = $d - Islamic2Absolute(1, $month, $year) + 1;
    }
    return ($day, $month, $year);

  }

1;
__END__
############################################################

=head1 NAME

Date::Hijri - Perl extension to convert islamic (hijri) and gregorian dates.

=head1 SYNOPSIS

  use Date::Hijri;

  # convert gregorian to hijri date
  my ($hd, $hm, $hy) = g2h($gd, $gm, $gy);

  # convert hijri to gregorian date
  my ($gd, $gm, $gy) = h2g($hd, $hm, $hy);

=head1 DESCRIPTION

This simple module converts gregorian dates to islamic (hijri) and vice versa.

The dates must be given as an array containing the day, month and year, and return the
corresponding date as a list with the same elements.

=head1 EXAMPLES

  #!/usr/bin/perl -w

  use Date::Hijri;

  print join("-", g2h(22,8,2003));  # prints 23-6-1424
  print join("-", h2g(23,6,1424));  # prints 22-8-2003

=head1 SEE ALSO

This code is just stolen from KDE's L<kcalendarsystemhijri.cpp> at
http://webcvs.kde.org/cgi-bin/cvsweb.cgi/kdelibs/kdecore/kcalendarsystemhijri.cpp

   Copyright (c) 2002-2003 Carlos Moro <cfmoro@correo.uniovi.es>
   Copyright (c) 2002-2003 Hans Petter Bieker <bieker@kde.org>

   kcalendarsystemhijri.cpp is translated from the Lisp code
   in ``Calendrical Calculations'' by Nachum Dershowitz and
   Edward M. Reingold, Software---Practice & Experience,
   vol. 20, no. 9 (September, 1990), pp. 899--928.

   This code is in the public domain, but any use of it
   should publically acknowledge its source.

=head1 AUTHOR

Alex Pleiner, E<lt>alex@zeitform.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 zeitform Internet Dienste. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

I haven't really tested if the converted dates are right and hope
someone will point out mistakes.

Hijri calculations are very difficult. The islamic calendar is a pure
lunar calendar, the new month starts by a physical (i.e. human)
sighting of the crescent moon at a given locale. So it depends on
several factors (like weather) that make it unreliable to calculate
islamic calendars in advance. As a result the dates calculated by
Date::Hijri can be false by one or more days.

Please see http://www.rabiah.com/convert/introduction.html for further
explanation.

I'm not a muslim, but interested in Islamic culture, religion and
calendar system. I believe in the Internet as a chance to realize that
we live in a small world with multiple cultures, religions and
philosophies. We can learn from others and develop tolerance, respect
and understanding.

Salam Alaikum (peace be with you)

=cut

## -fin- 




