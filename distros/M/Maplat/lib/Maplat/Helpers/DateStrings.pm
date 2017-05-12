
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::DateStrings;
use strict;
use warnings;

use 5.008000;
use Maplat::Helpers::Padding qw(doFPad);

use Date::Manip qw(Date_Init UnixDate);
use Date::Parse;
use Readonly;

use base qw(Exporter);
our @EXPORT = qw(getISODate getFileDate getUniqueFileDate getDateAndTime fixDateField parseNaturalDate getShortFiledate getCurrentHour getCurrentDay getISODate_nDaysOffset offsetISODate setmylocaltime); ## no critic (Modules::ProhibitAutomaticExportation)

our $VERSION = 0.995;

Readonly my $YEARBASEOFFSET => 1900;
my $lastUniqueDate = "";
my $UniqueDateCounter = 0;

my %timemap = (
    morning         => "06:00:00",
    premorning      => "05:45:00",
    afternoon       => "14:00:00",
    preafternoon    => "13:45:00",
    evening         => "22:00:00",
    preevening      => "21:45:00",
    night           => "22:00:00",
    prenight        => "21:45:00",
    noon            => "12:00:00",
    midnight        => "23:59:59",
    christmas       => "THISYEAR-12-24",
    "new year"      => "NEXTYEAR-01-01",
    "new years eve" => "THISYEAR-12-31",
);
my $timemap_updated = "";
my $timezoneoffset = 0;

sub setmylocaltime {
    my ($lt) = @_;
    
    $timezoneoffset = $lt;
    return 1;
}

sub getmylocaltime {
    return localtime ($timezoneoffset + time);
}

sub updateTimeMap {
    # calculate some variable date and time strings
    
    # atm, we need to run only once a day, so return quickly
    # it is the same date as last run
    my ($currentDate, undef) = getDateAndTime();
    if($timemap_updated eq $currentDate) {
        return;
    }
    $timemap_updated = $currentDate;
    
    Date_Init("TZ=CET");
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    my $nextyear = $year+1;
    my $lastyear = $year-1;
    
    # a number of variable dates
    my %vardates = (
                    "sysadmin day"          => "last friday in june",
                    "towel day"             => "25th may",
                    "new years eve"         => "31st december",
                    "new year"              => "1st january",
                    "christmas eve"         => "24th december",
                    "christmas"             => "25th december",
                    "rene(s)* birthday"     => "9th november",
                    "frank(s)* birthday"    => "6th september",
                    
                    );
    
    foreach my $varkey (keys %vardates) {
        my $varval = $vardates{$varkey};
        my $lastYearDay = UnixDate($varval . " $lastyear", "%Y-%m-%d");
        my $currentYearDay = UnixDate($varval . " $year", "%Y-%m-%d");
        my $nextYearDay = UnixDate($varval . " $nextyear", "%Y-%m-%d");
    
        my ($tmpyear, $tmpmon, $tmpday) = split/\-/, $currentYearDay;
        # normal
        if($mon < $tmpmon || ($mon == $tmpmon && $mday <= $tmpday)) {
            $timemap{$varkey} = $currentYearDay;
        } else {
            $timemap{$varkey} = $nextYearDay;
        }
        
        # "last ..."
        my $lastvarkey = "last " . $varkey;
        if($mon < $tmpmon || ($mon == $tmpmon && $mday <= $tmpday)) {
            $timemap{$lastvarkey} = $lastYearDay;
        } else {
            $timemap{$lastvarkey} = $currentYearDay;
        }
    }
    return;
}

sub getISODate {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    $sec = doFPad($sec, 2);
    return "$year-$mon-$mday $hour:$min:$sec";
}

sub getISODate_nDaysOffset {
    my ($nDays) = @_;
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = localtime(time + (86400 * $nDays));
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    $sec = doFPad($sec, 2);
    return "$year-$mon-$mday $hour:$min:$sec";
}

sub getShortFiledate {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    return "$year$mon$mday";
}

sub getCurrentHour {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    return "$year$mon$mday$hour";
}

sub getCurrentDay {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);

    return "$year$mon$mday";
}

sub getFileDate {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    $sec = doFPad($sec, 2);
    return "$year$mon$mday$hour$min$sec";
}

sub getUniqueFileDate {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    my $date = "$year$mon$mday$hour$min$sec";
    
    if($date eq $lastUniqueDate) {
        $UniqueDateCounter++;
        if($UniqueDateCounter == 99) {
            my $newmin = $min;
            while($newmin == $min) {
                print "getUniqueFileDate is throtteling\n";
                sleep(1);
                (undef,$newmin) = getmylocaltime();
            }
        }
    } else {
        $UniqueDateCounter = 1;
        $lastUniqueDate = $date;
    }
    $date .= doFPad($UniqueDateCounter, 2);
    return $date;
    
}

sub getDateAndTime {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = getmylocaltime();
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    $sec = doFPad($sec, 2);
    return ("$year-$mon-$mday", "$hour:$min:$sec");
}

sub parseNaturalDate {
    my ($dateString) = @_;
    
    updateTimeMap();
    
    # parse some extra mappings
    my (undef,undef, undef, undef,undef, $thisyear) = getmylocaltime();
    $thisyear += $YEARBASEOFFSET;
    my $nextyear = $thisyear + 1;
    
    # remove unused characters
    $dateString =~ s/([^a-zA-Z0-9\ \-\:])//go;
    
    # reorder the form of "TIMENAME of DAYNAME"
    if($dateString =~ /(.*)\ (of|on|at)\ (.*)/) {
        $dateString = "$3 $1";
    }
    
    if($dateString =~ /last/) {
        # First try only keys with "last" in it
        foreach my $speakdate (keys %timemap) {
            next unless $speakdate =~ /last/;
            my $writedate = $timemap{$speakdate};
            $dateString =~ s/\b$speakdate\b/$writedate/g;
        }    
    }
    
    foreach my $speakdate (keys %timemap) {
        my $writedate = $timemap{$speakdate};
        $dateString =~ s/\b$speakdate\b/$writedate/g;
    }
    $dateString =~ s/THISYEAR/$thisyear/g;
    $dateString =~ s/NEXTYEAR/$nextyear/g;
    
#    my $dt = $naturalDateParser->parse_datetime($dateString);
    my $newdate = UnixDate($dateString, "%Y-%m-%d %H:%M:%S");
    if(defined($newdate) && $newdate ne "") {
        return $newdate;
    } else {
        return $dateString;
    }
}

sub fixDateField {
    my ($date) = @_;
    
    if($date =~ /(\d\d\d\d\-\d\d\-\d\d\ \d\d\:\d\d\:\d\d)/o) {
        $date = $1;
    }
    if($date eq "1970-01-01 23:59:59") {
        $date = "";
    }
    
    return $date;
}

sub offsetISODate {
    my($date, $offset) = @_;
    
    my $oldtime = str2time($date) + $offset;
    
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = localtime $oldtime;
    $year += $YEARBASEOFFSET;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    $sec = doFPad($sec, 2);
    my $newtime = "$year-$mon-$mday $hour:$min:$sec";
    
    return $newtime;
}

1;

__END__

=head1 NAME

Maplat::Helpers::DateStrings - generation and parsing of common date strings

=head1 SYNOPSIS

  use Maplat::Helpers::DateStrings;
  
  my $datestring = getISODate();
  my $datestring = getISODate_nDaysOffset($days);
  my $datestring = getFileDate();
  my $datestring = getShortFiledate();
  my $datestring = getUniqueFileDate();
  my $datestring = getCurrentHour();
  my $datestring = getCurrentDay();
  my ($date, $time) = getDateAndTime();
  my $isodate = parseNaturalDate($naturalDate);
  my $datestring = fixDateField($brokendate);

=head1 DESCRIPTION

This module provides a host of date functions required in commercial environments.
Most of them return the current date in some form or other, while at least one of
them (getUniqueFileDate) cheats when it has to.

=head2 getISODate

Returns the current date and time in the short ISO format with space instead of "T"
as delimeter betweeen date and time, e.g.

  "$year-$mon-$mday $hour:$min:$sec"

=head2 getISODate_nDaysOffset

Similar to getISODate, but offsets the date with the given number of days.

=head2 offsetISODate

This function take an ISO date string and an offset in seconds and returns the re-calculated ISO date.

=head2 getFileDate

Returns the date and time in a format suiteable for filenames, e.g.:

  "$year$mon$mday$hour$min$sec"

=head2 getShortFiledate

Returns only the current date (without time) in a format suiteable for filenames, e.g.:

  "$year$mon$mday"

=head2 getUniqueFileDate

Returns the date and time in the same format as getFileDate, with one exception:
It cheats. 

Only one unique filedate can naturally produced per second in this format, so the seconds
are actually a counter that resets at when the minute value changes. Seconds don't even
end at 59, they run to 99. If the counter reaches 99, the function waits till the minute marker
changes.

This function may or not be useless to you, i needed it for communication with legacy software
that expects the filename to start with a filedate string, which must be unique but doesn't check
if the seconds are valid. My software produced the data files in bursts with about 20-80 files
per second. If you don't have similar requirements, you're better of using getFileDate() instead.

=head2 getCurrentHour

A bit of a misnomer. This function returns a date string thats exact to the hour, e.g.:

  "$year$mon$mday$hour"

This is quite usefull to check if the hour changed since your last check, something like this:

  my $hour = "";
  sub cyclicFuntion {
    my $newhour = getCurrentHour();
    if($newhour ne $hour) {
      # Do some cyclic job at the start of every hour
      ...
      $hour = $newhour;
    }
  }

Checking the full string instead of only the hour value makes it possible to start correctly
even if the program somehow skipped some 23 odd hours.

=head2 getCurrentDay

Very similar to getCurrentHour(), except it is only accurate to the day, e.g.:

  "$year$mon$mday"

=head2 getDateAndTime

Similar to getISODate, except it returns an array with two values, the date and time:

  my @date = getDateAndTime();
  print $date[0]; # Date
  print $date[1]; # Time

Altough you might prefer to use it in a proper list context in the first place:

  my ($date, $time) = getDateAndTime();

=head2 parseNaturalDate

This function provides a bit of "magic date/time string parsing".

If you give it an ISO date or something similar, it just pretty-prints it to the same
format as getISODate().

But you can also supply it with date "descriptions", for example:

  "tomorrow morning"
  "sunday night"
  "new years eve afternoon"
  "renes birthday morning" (The authors birthday, which is 9th of November)
  "now"

The values of morning, afternoon and evening are currently hardcoded to "06:00", "14:00",
and "22:00" respectively (the workshift model my employer uses). You can also add a "pre" 
to the timestring which takes off 15 minutes, for example "premorning" meaning "05:45"

=head2 fixDateField

For easier handling, some Maplat tables have date fields ("timestamp without timezone" to
be precise) that are NOT NULL and have a default of "1970-01-01 23:59:59".

For display on the web interface, all dates get parsed through this function, default dates
are replaced by empty strings. Also, the datestring is trimmed of unnessecary whitespace.

=head2 updateTimeMap

Internal function.

=head2 setmylocaltime

Internal function, workaround for a specific Windows machine with broken registry

=head2 getmylocaltime

Internal function, workaround for a specific Windows machine with broken registry

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
