package Microsoft::AdCenter::V8::BulkService::AdditionalEntity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::BulkService::AdditionalEntity - Represents "AdditionalEntity" in Microsoft AdCenter Bulk Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AdEditorialRejectionReasons
    AdGroupNegativeKeywords
    AdGroupNegativeSites
    AdGroupTargets
    CampaignNegativeKeywords
    CampaignNegativeSites
    CampaignSiteLinksAdExtensions
    CampaignTargets
    KeywordEditorialRejectionReasons

=cut

sub AdEditorialRejectionReasons {
    return 'AdEditorialRejectionReasons';
}

sub AdGroupNegativeKeywords {
    return 'AdGroupNegativeKeywords';
}

sub AdGroupNegativeSites {
    return 'AdGroupNegativeSites';
}

sub AdGroupTargets {
    return 'AdGroupTargets';
}

sub CampaignNegativeKeywords {
    return 'CampaignNegativeKeywords';
}

sub CampaignNegativeSites {
    return 'CampaignNegativeSites';
}

sub CampaignSiteLinksAdExtensions {
    return 'CampaignSiteLinksAdExtensions';
}

sub CampaignTargets {
    return 'CampaignTargets';
}

sub KeywordEditorialRejectionReasons {
    return 'KeywordEditorialRejectionReasons';
}

1;
