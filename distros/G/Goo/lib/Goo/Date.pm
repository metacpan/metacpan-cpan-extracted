package Goo::Date;

###############################################################################
# Nigel Hamilton - handle dates
#
# Copyright Nigel Hamilton 2002
# All Rights Reserved
#
# Author:   	Nigel Hamilton
# Filename: 	Goo::Date.pm
# Description:  Date handling functions
#
# Date      	Change
# -----------------------------------------------------------------------------
# 20/6/2002     Version 1
#
###############################################################################

use strict;


###############################################################################
#
# get_date_ndays_ago - return the date n days go
#
###############################################################################

sub get_date_ndays_ago {

    my ($days) = @_;

    # how many seconds in a day?
    #                   hh   mm   ss
    my $secondsperday = 24 * 60 * 60;

    # how many total seconds?
    my $when = time() - ($days * $secondsperday);

    # adjust localtime values accordingly
    my ($day, $month, $year) = (localtime($when))[ 3, 4, 5 ];

    $month = $month + 1;
    $year  = $year + 1900;

    return "$year-$month-$day";

}


###############################################################################
#
# get_last_month - return the last month
#
###############################################################################

sub get_last_month {

    my ($month) = @_;

    if ($month > 12) { die("Invalid month: $month"); }

    if ($month == 1) { return 12; }

    return $month - 1;

}


###############################################################################
#
# get_current_year - return the year
#
###############################################################################

sub get_current_year {

    my ($day, $month, $year) = get_current_date();

    return $year;

}


###############################################################################
#
# get_current_date_with_slashes - return a zero-filled date like dd/mm/yyyy
#
###############################################################################

sub get_current_date_with_slashes {

    my ($day, $month, $year) = get_current_date();

    $month = get_zero_padded($month);
    $day   = get_zero_padded($day);

    return "$day/$month/$year";

}


###############################################################################
#
# convert - convert from yyyy-mm-dd to -> 10 jan 2002
#
###############################################################################

sub convert {

    # adjust localtime values accordingly
    my ($date) = @_;

    $date =~ m/^(.*?)-(.*?)-(.*?)$/;

    my $month = get_month_prefix($2);

    return "$3 $month $1";

}


###############################################################################
#
# get_current_date_with_month_prefix - get the current date
#
###############################################################################

sub get_current_date_with_month_prefix {

    # adjust localtime values accordingly
    my ($day, $month, $year) = (localtime)[ 3, 4, 5 ];

    $month = $month + 1;

    $month = get_month_prefix($month);

    $year = $year + 1900;

    return $day . " " . $month . " " . $year;

}


###############################################################################
#
# get_current_date - get the current date
#
###############################################################################

sub get_current_date {

    # adjust localtime values accordingly
    my ($day, $month, $year) = (localtime)[ 3, 4, 5 ];

    return ($day, $month + 1, $year + 1900);

}


##############################################################################
#
# get_month_from_prefix - return a month number given a prefix
#
##############################################################################

sub get_month_from_prefix {

    my ($month) = @_;

    my $months = { 'Jan' => 1,
                   'Feb' => 2,
                   'Mar' => 3,
                   'Apr' => 4,
                   'May' => 5,
                   'Jun' => 6,
                   'Jul' => 7,
                   'Aug' => 8,
                   'Sep' => 9,
                   'Oct' => 10,
                   'Nov' => 11,
                   'Dec' => 12
                 };

    return $months->{$month};

}


##############################################################################
#
# get_month_prefix - return a month prefix
#
##############################################################################

sub get_month_prefix {

    my ($month) = @_;

    my $months = { 1  => 'Jan',
                   2  => 'Feb',
                   3  => 'Mar',
                   4  => 'Apr',
                   5  => 'May',
                   6  => 'Jun',
                   7  => 'Jul',
                   8  => 'Aug',
                   9  => 'Sep',
                   10 => 'Oct',
                   11 => 'Nov',
                   12 => 'Dec'
                 };

    return $months->{$month};

}


##############################################################################
#
# get_month - return a month
#
##############################################################################

sub get_month {

    my ($month) = @_;

    my $months = { 1  => 'January',
                   2  => 'February',
                   3  => 'March',
                   4  => 'April',
                   5  => 'May',
                   6  => 'June',
                   7  => 'July',
                   8  => 'August',
                   9  => 'September',
                   10 => 'October',
                   11 => 'November',
                   12 => 'Dececember'
                 };

    return $months->{$month};

}


##############################################################################
#
# get_date_from_time - return a date given a time
#
##############################################################################

sub get_date_from_time {

    my ($time, $format) = @_;

    # adjust localtime values accordingly
    my ($hour, $day, $month, $year) = (localtime($time))[ 2, 3, 4, 5 ];

    $year  = $year + 1900;
    $month = $month + 1;

    $month = get_zero_padded($month);
    $day   = get_zero_padded($day);
    $hour  = get_zero_padded($hour);

    $format = lc($format);

    if ($format eq "yyyymmdd") {
        return $year . $month . $day;
    }

    if ($format eq "yyyymmddhh") {
        return $year . $month . $day . $hour;
    }

}


##############################################################################
#
# get_zero_padded - add padding to fit the format
#
##############################################################################

sub get_zero_padded {

    my ($field) = @_;

    if (length($field) == 1) { $field = "0$field"; }

    return $field;

}


##############################################################################
#
# get_time - return the current time
#
##############################################################################

sub get_time {

    # local time returns: Fri Apr 11 09:27:08 2002 in scalar context
    return localtime();


}


###############################################################################
#
# get_today - synonym for get_current_date
#
###############################################################################

sub get_today {

    return get_current_date();

}

1;


__END__

=head1 NAME

Goo::Date - Date handling functions

=head1 SYNOPSIS

use Goo::Date;

=head1 DESCRIPTION

Simple date handling methods.

=head1 METHODS

=over

=item get_date_ndays_ago

return the date n days go

=item get_last_month

return the last month

=item get_current_year

return the year

=item get_current_date_with_slashes

return a zero-filled date like dd/mm/yyyy

=item convert

convert from yyyy-mm-dd to -> 10 jan 2002

=item get_current_date_with_month_prefix

get the current date

=item get_current_date

get the current date

=item get_month_from_prefix

return a month number given a prefix

=item get_month_prefix

return a month prefix

=item get_month

return a month

=item get_date_from_time

return a date given a time

=item get_zero_padded

add padding to fit the format

=item get_time

return the current time

=item get_today

synonym for get_current_date


=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

