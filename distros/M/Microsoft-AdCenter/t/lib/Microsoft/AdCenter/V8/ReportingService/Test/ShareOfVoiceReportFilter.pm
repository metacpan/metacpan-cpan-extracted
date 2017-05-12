package Microsoft::AdCenter::V8::ReportingService::Test::ShareOfVoiceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::ShareOfVoiceReportFilter;

sub test_can_create_share_of_voice_report_filter_and_set_all_fields : Test(7) {
    my $share_of_voice_report_filter = Microsoft::AdCenter::V8::ReportingService::ShareOfVoiceReportFilter->new
        ->AdDistribution('ad distribution')
        ->BidMatchType('bid match type')
        ->DeliveredMatchType('delivered match type')
        ->Keywords('keywords')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
    ;

    ok($share_of_voice_report_filter);

    is($share_of_voice_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($share_of_voice_report_filter->BidMatchType, 'bid match type', 'can get bid match type');
    is($share_of_voice_report_filter->DeliveredMatchType, 'delivered match type', 'can get delivered match type');
    is($share_of_voice_report_filter->Keywords, 'keywords', 'can get keywords');
    is($share_of_voice_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($share_of_voice_report_filter->LanguageCode, 'language code', 'can get language code');
};

1;
