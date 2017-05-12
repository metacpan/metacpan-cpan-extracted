package Microsoft::AdCenter::V7::ReportingService::DeviceTypeReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::ReportingService::DeviceTypeReportFilter - Represents "DeviceTypeReportFilter" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Computer
    NonSmartPhone
    SmartPhone
    Tablet

=cut

sub Computer {
    return 'Computer';
}

sub NonSmartPhone {
    return 'NonSmartPhone';
}

sub SmartPhone {
    return 'SmartPhone';
}

sub Tablet {
    return 'Tablet';
}

1;
