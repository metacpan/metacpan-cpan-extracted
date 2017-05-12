package Microsoft::AdCenter::V8::ReportingService::AgeGroupReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::ReportingService::AgeGroupReportFilter - Represents "AgeGroupReportFilter" in Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Ages0to12
    Ages13to17
    Ages18to24
    Ages25to34
    Ages35to49
    Ages50to64
    Ages65plus
    Unknown

=cut

sub Ages0to12 {
    return 'Ages0to12';
}

sub Ages13to17 {
    return 'Ages13to17';
}

sub Ages18to24 {
    return 'Ages18to24';
}

sub Ages25to34 {
    return 'Ages25to34';
}

sub Ages35to49 {
    return 'Ages35to49';
}

sub Ages50to64 {
    return 'Ages50to64';
}

sub Ages65plus {
    return 'Ages65plus';
}

sub Unknown {
    return 'Unknown';
}

1;
