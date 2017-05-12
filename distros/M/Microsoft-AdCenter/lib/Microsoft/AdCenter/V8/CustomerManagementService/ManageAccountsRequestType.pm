package Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequestType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequestType - Represents "ManageAccountsRequestType" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    EndedByAdvertiser
    EndedByAgency
    RequestedByAdvertiser
    RequestedByAgency

=cut

sub EndedByAdvertiser {
    return 'EndedByAdvertiser';
}

sub EndedByAgency {
    return 'EndedByAgency';
}

sub RequestedByAdvertiser {
    return 'RequestedByAdvertiser';
}

sub RequestedByAgency {
    return 'RequestedByAgency';
}

1;
