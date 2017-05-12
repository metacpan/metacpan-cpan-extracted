package Microsoft::AdCenter::V8::CampaignManagementService::AnalyticsType;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::AnalyticsType - Represents "AnalyticsType" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    CampaignLevel
    Disabled
    Enabled

=cut

sub CampaignLevel {
    return 'CampaignLevel';
}

sub Disabled {
    return 'Disabled';
}

sub Enabled {
    return 'Enabled';
}

1;
