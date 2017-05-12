package Microsoft::AdCenter::V6::ReportingService::ReportRequestStatusType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::ReportingService::ReportRequestStatusType - Represents "ReportRequestStatusType" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Error
    Pending
    Success

=cut

sub Error {
    return 'Error';
}

sub Pending {
    return 'Pending';
}

sub Success {
    return 'Success';
}

1;
