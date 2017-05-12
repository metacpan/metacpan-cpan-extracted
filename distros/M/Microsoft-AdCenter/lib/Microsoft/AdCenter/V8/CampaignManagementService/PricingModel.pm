package Microsoft::AdCenter::V8::CampaignManagementService::PricingModel;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService::PricingModel - Represents "PricingModel" in Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    Cpc
    Cpm

=cut

sub Cpc {
    return 'Cpc';
}

sub Cpm {
    return 'Cpm';
}

1;
