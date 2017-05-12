package Microsoft::AdCenter::V7::ReportingService::BudgetSummaryReportTimePeriod;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::BudgetSummaryReportTimePeriod - Represents "BudgetSummaryReportTimePeriod" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    LastMonth
    LastSevenDays
    ThisMonth
    Today
    Yesterday

=cut

sub LastMonth {
    return 'LastMonth';
}

sub LastSevenDays {
    return 'LastSevenDays';
}

sub ThisMonth {
    return 'ThisMonth';
}

sub Today {
    return 'Today';
}

sub Yesterday {
    return 'Yesterday';
}

1;
