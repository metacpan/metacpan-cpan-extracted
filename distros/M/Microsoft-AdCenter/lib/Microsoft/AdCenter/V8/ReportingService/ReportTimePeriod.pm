package Microsoft::AdCenter::V8::ReportingService::ReportTimePeriod;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::ReportingService::ReportTimePeriod - Represents "ReportTimePeriod" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    LastFourWeeks
    LastMonth
    LastSevenDays
    LastSixMonths
    LastThreeMonths
    LastWeek
    LastYear
    ThisMonth
    ThisWeek
    ThisYear
    Today
    Yesterday

=cut

sub LastFourWeeks {
    return 'LastFourWeeks';
}

sub LastMonth {
    return 'LastMonth';
}

sub LastSevenDays {
    return 'LastSevenDays';
}

sub LastSixMonths {
    return 'LastSixMonths';
}

sub LastThreeMonths {
    return 'LastThreeMonths';
}

sub LastWeek {
    return 'LastWeek';
}

sub LastYear {
    return 'LastYear';
}

sub ThisMonth {
    return 'ThisMonth';
}

sub ThisWeek {
    return 'ThisWeek';
}

sub ThisYear {
    return 'ThisYear';
}

sub Today {
    return 'Today';
}

sub Yesterday {
    return 'Yesterday';
}

1;
