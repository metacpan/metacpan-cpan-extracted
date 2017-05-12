package Microsoft::AdCenter::V7::CampaignManagementService::MigrationStatus;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::CampaignManagementService::MigrationStatus - Represents "MigrationStatus" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Completed
    InProgress
    NotInPilot
    NotStarted

=cut

sub Completed {
    return 'Completed';
}

sub InProgress {
    return 'InProgress';
}

sub NotInPilot {
    return 'NotInPilot';
}

sub NotStarted {
    return 'NotStarted';
}

1;
