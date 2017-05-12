package Microsoft::AdCenter::V7::ReportingService::AdGroupStatusReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::AdGroupStatusReportFilter - Represents "AdGroupStatusReportFilter" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Active
    Deleted
    Draft
    Expired
    Paused
    Submitted

=cut

sub Active {
    return 'Active';
}

sub Deleted {
    return 'Deleted';
}

sub Draft {
    return 'Draft';
}

sub Expired {
    return 'Expired';
}

sub Paused {
    return 'Paused';
}

sub Submitted {
    return 'Submitted';
}

1;
