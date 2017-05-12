package Labyrinth::DTUtils;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::DTUtils - Date & Time Utilities for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::DTUtils;

=head1 DESCRIPTION

Various date & time utilities.

=head1 EXPORT

everything

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw(
        DaySelect MonthSelect YearSelect PeriodSelect
        formatDate unformatDate isMonth
    ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

#############################################################################
#Libraries
#############################################################################

use DateTime;
use Time::Local;
use Labyrinth::Audit;
use Labyrinth::MLUtils;
use Labyrinth::Variables;

#############################################################################
#Variables
#############################################################################

my @months = (
    { 'id' =>  1,   'value' => "January",   },
    { 'id' =>  2,   'value' => "February",  },
    { 'id' =>  3,   'value' => "March",     },
    { 'id' =>  4,   'value' => "April",     },
    { 'id' =>  5,   'value' => "May",       },
    { 'id' =>  6,   'value' => "June",      },
    { 'id' =>  7,   'value' => "July",      },
    { 'id' =>  8,   'value' => "August",    },
    { 'id' =>  9,   'value' => "September", },
    { 'id' => 10,   'value' => "October",   },
    { 'id' => 11,   'value' => "November",  },
    { 'id' => 12,   'value' => "December"   },
);

my @dotw = (    "Sunday", "Monday", "Tuesday", "Wednesday",
                "Thursday", "Friday", "Saturday" );

my @days = map {{'id'=>$_,'value'=> $_}} (1..31);
my @periods = (
    {act => 'evnt-month', value => 'Month'},
    {act => 'evnt-week',  value => 'Week'},
    {act => 'evnt-day',   value => 'Day'}
);

my %formats = (
    1 => 'YYYY',
    2 => 'MONTH YYYY',
    3 => 'DD/MM/YYYY',
    4 => 'DABV MABV DD TIME24 YYYY',
    5 => 'DAY, DD MONTH YYYY',
    6 => 'DAY, DDEXT MONTH YYYY',
    7 => 'DAY, DD MONTH YYYY (TIME12)',
    8 => 'DAY, DDEXT MONTH YYYY (TIME12)',
    9 => 'YYYY/MM/DD',
    10 => 'DDEXT MONTH YYYY',
    11 => 'YYYYMMDDThhmmss',        # iCal date string
    12 => 'YYYY-MM-DDThh:mm:ssZ',   # RSS date string
    13 => 'YYYYMMDD',               # backwards date
    14 => 'DABV, DDEXT MONTH YYYY',
    15 => 'DD MABV YYYY',
    16 => 'DABV, dd MABV YYYY hh:mm:ss TZ', # RFC-822 date string
    17 => 'DAY, DD MONTH YYYY hh:mm:ss',
    18 => 'DD/MM/YYYY hh:mm:ss',
    19 => 'DDEXT MONTH YYYY',
    20 => 'DABV, DD MABV YYYY hh:mm:ss',
    21 => 'YYYY-MM-DD hh:mm:ss',
    22 => 'YYYYMMDDhhmm',
);

my %unformats = (
    11 => '(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})',        # iCal date string
    12 => '(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z',   # ISO 8601 date string
    13 => '(\d{4})(\d{2})(\d{2})',                              # backwards date
    22 => '(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})',
);

# decrees whether the date format above should be UTC
# time based, or allow for any Summer Time variations.
my %zonetime = (12 => 1, 16 => 1);

#############################################################################
#Subroutines
#############################################################################

=head1 FUNCTIONS

=head2 Dropdown Boxes

=over 4

=item DaySelect($opt,$blank)

Provides a Day dropdown selection box. 

The option $opt allows the given day (numerical 1 - 31) to be the selected 
option in the dropdown. If blank is true, a 'Select Day' option is added as
the first option to the dropdown.

=item MonthSelect($opt,$blank)

Provides a Month dropdown selection box. 

The option $opt allows the given month (numerical 1 - 12) to be the selected 
option in the dropdown. If blank is true, a 'Select Month' option is added as
the first option to the dropdown.

=item YearSelect($opt,$range,$blank,$dates)

Provides a Year dropdown selection box. 

The option $opt allows the given month (numerical 1 - 12) to be the selected 
option in the dropdown. If blank is true, a 'Select Month' option is added as
the first option to the dropdown.

If is specified, then the following criteria is used:

  0 - default
  1 - given dates, see $dates list
  2 - oldest year to current year
  3 - current year to future year

For oldest year, this is determined by the configuration setting 
'year_past_offset' or 'year_past'. For the future year, this is determined by
the configuration setting 'year_future_offset'.

If the range is set to 1, the list of dates given in the $dates array 
reference will be used.

=item PeriodSelect($opt,$blank)

Provides a Period dropdown selection box. 

The option $opt allows the given period to be the selected option in the 
dropdown. If blank is true, a 'Select Period' option is added as the first 
option to the dropdown.

Current valid periods are:

  opt           value
  -------------------
  evnt-month    Month
  evnt-week     Week
  evnt-day      Day

=back

=cut

sub DaySelect {
    my ($opt,$blank) = @_;
    my @list = @days;
    unshift @list, {id=>0,value=>'Select Day'}  if(defined $blank && $blank == 1);
    DropDownRows($opt,'day','id','value',@list);
}

sub MonthSelect {
    my ($opt,$blank) = @_;
    my @list = @months;
    unshift @list, {id=>0,value=>'Select Month'}    if(defined $blank && $blank == 1);
    DropDownRows($opt,'month','id','value',@list);
}

sub YearSelect {
    my ($opt,$range,$blank,$dates) = @_;
    my $year = formatDate(1);
    
    my $past_offset   = $settings{year_past_offset} || 0;
    my $future_offset = defined $settings{year_future_offset} ? $settings{year_future_offset} : 4;
    my $past   = $past_offset ? $year - $past_offset : $settings{year_past};
    my $future = $year + $future_offset;
    $past ||= $year;

    my @range = ($past .. $future);
    if(defined $range) {
        if($range == 1)     { @range = @$dates }
        elsif($range == 2)  { @range = ($past .. $year) }
        elsif($range == 3)  { @range = ($year .. $future) }
    }

    my @years = map {{'id'=>$_,'value'=> $_}} @range;
    unshift @years, {id=>0,value=>'Select Year'}    if(defined $blank && $blank == 1);
    DropDownRows($opt,'year','id','value',@years);
}

sub PeriodSelect {
    my ($opt,$blank) = @_;
    my @list = @periods;
    unshift @list, {act=>'',value=>'Select Period'}   if(defined $blank && $blank == 1);
    DropDownRowsText($opt,'period','act','value',@list);
}

## ------------------------------------
## Date Functions

=head2 Date Formatting

=over 4

=item formatDate

=item unformatDate

=item isMonth

=back

=cut

sub formatDate {
    my ($format,$time) = @_;
    my $now = $time ? 0 : 1;

    my $dt;
    my $timezone = $settings{timezone} || 'Europe/London';
    if($time) {
        $dt = DateTime->from_epoch( epoch => $time, time_zone => $timezone );
    } else {
        $dt = DateTime->now( time_zone => $timezone );
    }

    return $dt->epoch   unless($format);

#LogDebug("formatDate format=$format, time=".$dt->epoch);

    # create date mini strings
    my $fmonth  = $dt->month_name;
    my $amonth  = $dt->month_abbr;
    my $fdotw   = $dt->day_name;
    my $adotw   = $dt->day_abbr;
    my $fsday   = sprintf "%d",   $dt->day; # short form, ie 6
    my $fday    = sprintf "%02d", $dt->day; # long form, ie 06
    my $fmon    = sprintf "%02d", $dt->month;
    my $fyear   = sprintf "%04d", $dt->year;
    my $fddext  = sprintf "%d%s", $dt->day, _ext($dt->day);
    my $time12  = sprintf "%d:%02d%s", $dt->hour_12, $dt->minute, lc $dt->am_or_pm;
    my $time24  = sprintf "%d:%02d:%02d", $dt->hour, $dt->minute, $dt->second;
    my $fhour   = sprintf "%02d", $dt->hour;
    my $fminute = sprintf "%02d", $dt->minute;
    my $fsecond = sprintf "%02d", $dt->second;
    my $tz      = 'UTC';
    eval { $tz = $dt->time_zone->short_name_for_datetime };

    my $fmt = $formats{$format};

    # transpose format string into a date string
    $fmt =~ s/hh/$fhour/;
    $fmt =~ s/mm/$fminute/;
    $fmt =~ s/ss/$fsecond/;
    $fmt =~ s/DMY/$fday-$fmon-$fyear/;
    $fmt =~ s/MDY/$fmon-$fday-$fyear/;
    $fmt =~ s/YMD/$fyear-$fmon-$fday/;
    $fmt =~ s/MABV/$amonth/;
    $fmt =~ s/DABV/$adotw/;
    $fmt =~ s/MONTH/$fmonth/;
    $fmt =~ s/DAY/$fdotw/;
    $fmt =~ s/DDEXT/$fddext/;
    $fmt =~ s/YYYY/$fyear/;
    $fmt =~ s/MM/$fmon/;
    $fmt =~ s/DD/$fday/;
    $fmt =~ s/dd/$fsday/;
    $fmt =~ s/TIME12/$time12/;
    $fmt =~ s/TIME24/$time24/;
    $fmt =~ s/TZ/$tz/;

    return $fmt;
}

sub unformatDate {
    my ($format,$time) = @_;

    return time unless($format && $time);

    my (@fields,@values);
    my @basic  = qw(ss mm hh DD MM YYYY);
    my %forms  = map {$_ => 0 } @basic, 'dd';

    if($unformats{$format}) {
        @fields = reverse @basic;
        @values = $time =~ /$unformats{$format}/;
    } else {
        my $pattern = $formats{$format};
        $pattern =~ s!TIME24!hh::mm:ss!;
        $pattern =~ s!TIME12!hh::ampm!;

        @fields = split(qr![ ,/:()-]+!,$pattern);
        @values = split(qr![ ,/:()-]+!,$time);
    }

    @forms{@fields} = @values;
    $forms{$_} = int($forms{$_}||0)    for(@basic);

#use Data::Dumper;
#LogDebug("format=[$format], time=[$time]");
#LogDebug("fields=[@fields], values=[@values]");
#LogDebug("before=".Dumper(\%forms));

    ($forms{DD}) = $forms{dd} =~ /(\d+)/        if($forms{dd});
    ($forms{DD}) = $forms{DDEXT} =~ /(\d+)/     if($forms{DDEXT});
    $forms{MM} = isMonth($forms{MONTH})         if($forms{MONTH});
    $forms{MM} = isMonth($forms{MABV})          if($forms{MABV});
    ($forms{mm},$forms{AMPM}) = ($forms{ampm} =~ /(\d+)(am|pm)/)  if($forms{ampm});
    $forms{hh}+=12  if($forms{AMPM} && $forms{AMPM} eq 'pm');

    @values = map {$forms{$_}||0} @basic;

    my $timezone = $settings{timezone} || 'Europe/London';
    my $dt = DateTime->new(
                year => $values[5], month  => $values[4] || 1, day    => $values[3] || 1,
                hour => $values[2], minute => $values[1],      second => $values[0],
                time_zone => $timezone );

    return $dt->epoch;
}

sub _ext {
    my $day = shift;
    my $ext = "th";
    if($day == 1 || $day == 21 || $day == 31)   {   $ext = "st" }
    elsif($day == 2 || $day == 22)              {   $ext = "nd" }
    elsif($day == 3 || $day == 23)              {   $ext = "rd" }
    return $ext;
}

sub isMonth {
    my $month = shift;
    return (localtime)[4]+1 unless(defined $month && $month);

    foreach (@months) {
        return $_->{id} if($_->{value} =~ /$month/);
        return $_->{value} if($month eq $_->{id});
    }
    return 0;
}

1;

__END__

=head1 SEE ALSO

  Time::Local
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
