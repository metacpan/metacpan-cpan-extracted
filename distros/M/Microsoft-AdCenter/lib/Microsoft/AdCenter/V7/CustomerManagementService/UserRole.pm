package Microsoft::AdCenter::V7::CustomerManagementService::UserRole;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V7::CustomerManagementService::UserRole - Represents "UserRole" in Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AdvertiserCampaignManager
    ClientAdmin
    ClientManager
    ClientViewer
    PublisherAccountManager
    PublisherAdmin
    PublisherAdViewer
    PublisherListManager
    PublisherReportUser
    SuperAdmin

=cut

sub AdvertiserCampaignManager {
    return 'AdvertiserCampaignManager';
}

sub ClientAdmin {
    return 'ClientAdmin';
}

sub ClientManager {
    return 'ClientManager';
}

sub ClientViewer {
    return 'ClientViewer';
}

sub PublisherAccountManager {
    return 'PublisherAccountManager';
}

sub PublisherAdmin {
    return 'PublisherAdmin';
}

sub PublisherAdViewer {
    return 'PublisherAdViewer';
}

sub PublisherListManager {
    return 'PublisherListManager';
}

sub PublisherReportUser {
    return 'PublisherReportUser';
}

sub SuperAdmin {
    return 'SuperAdmin';
}

1;
