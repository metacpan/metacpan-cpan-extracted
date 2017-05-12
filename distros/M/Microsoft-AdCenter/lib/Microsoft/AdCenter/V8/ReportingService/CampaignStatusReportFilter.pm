package Microsoft::AdCenter::V8::ReportingService::CampaignStatusReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::ReportingService::CampaignStatusReportFilter - Represents "CampaignStatusReportFilter" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Active
    BudgetPaused
    Cancelled
    Deleted
    Paused
    Submitted

=cut

sub Active {
    return 'Active';
}

sub BudgetPaused {
    return 'BudgetPaused';
}

sub Cancelled {
    return 'Cancelled';
}

sub Deleted {
    return 'Deleted';
}

sub Paused {
    return 'Paused';
}

sub Submitted {
    return 'Submitted';
}

1;
