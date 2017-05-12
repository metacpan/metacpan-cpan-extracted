package Microsoft::AdCenter::V7::ReportingService::BidMatchTypeReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::BidMatchTypeReportFilter - Represents "BidMatchTypeReportFilter" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Broad
    Content
    Exact
    Phrase

=cut

sub Broad {
    return 'Broad';
}

sub Content {
    return 'Content';
}

sub Exact {
    return 'Exact';
}

sub Phrase {
    return 'Phrase';
}

1;
