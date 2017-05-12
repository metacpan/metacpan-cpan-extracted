package Microsoft::AdCenter::V8::CampaignManagementService::CampaignStatus;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::CampaignStatus - Represents "CampaignStatus" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Active
    BudgetAndManualPaused
    BudgetPaused
    Deleted
    Paused

=cut

sub Active {
    return 'Active';
}

sub BudgetAndManualPaused {
    return 'BudgetAndManualPaused';
}

sub BudgetPaused {
    return 'BudgetPaused';
}

sub Deleted {
    return 'Deleted';
}

sub Paused {
    return 'Paused';
}

1;
