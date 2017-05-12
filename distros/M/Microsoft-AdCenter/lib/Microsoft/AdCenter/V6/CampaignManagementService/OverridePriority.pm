package Microsoft::AdCenter::V6::CampaignManagementService::OverridePriority;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::CampaignManagementService::OverridePriority - Represents "OverridePriority" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    KeywordEnable
    KeywordPriority
    SegmentEnable
    SegmentPriority

=cut

sub KeywordEnable {
    return 'KeywordEnable';
}

sub KeywordPriority {
    return 'KeywordPriority';
}

sub SegmentEnable {
    return 'SegmentEnable';
}

sub SegmentPriority {
    return 'SegmentPriority';
}

1;
