package Microsoft::AdCenter::V7::ReportingService::SearchQueryReportAggregation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::SearchQueryReportAggregation - Represents "SearchQueryReportAggregation" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Daily
    Hourly
    Monthly
    Summary
    Weekly

=cut

sub Daily {
    return 'Daily';
}

sub Hourly {
    return 'Hourly';
}

sub Monthly {
    return 'Monthly';
}

sub Summary {
    return 'Summary';
}

sub Weekly {
    return 'Weekly';
}

1;
