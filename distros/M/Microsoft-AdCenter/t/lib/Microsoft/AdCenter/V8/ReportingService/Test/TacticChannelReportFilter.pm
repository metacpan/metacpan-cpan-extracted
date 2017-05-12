package Microsoft::AdCenter::V8::ReportingService::Test::TacticChannelReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::TacticChannelReportFilter;

sub test_can_create_tactic_channel_report_filter_and_set_all_fields : Test(5) {
    my $tactic_channel_report_filter = Microsoft::AdCenter::V8::ReportingService::TacticChannelReportFilter->new
        ->ChannelIds('channel ids')
        ->TacticIds('tactic ids')
        ->ThirdPartyAdGroupIds('third party ad group ids')
        ->ThirdPartyCampaignIds('third party campaign ids')
    ;

    ok($tactic_channel_report_filter);

    is($tactic_channel_report_filter->ChannelIds, 'channel ids', 'can get channel ids');
    is($tactic_channel_report_filter->TacticIds, 'tactic ids', 'can get tactic ids');
    is($tactic_channel_report_filter->ThirdPartyAdGroupIds, 'third party ad group ids', 'can get third party ad group ids');
    is($tactic_channel_report_filter->ThirdPartyCampaignIds, 'third party campaign ids', 'can get third party campaign ids');
};

1;
