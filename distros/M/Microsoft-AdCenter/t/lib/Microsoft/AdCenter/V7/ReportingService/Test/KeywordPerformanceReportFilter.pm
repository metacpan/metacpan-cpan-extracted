package Microsoft::AdCenter::V7::ReportingService::Test::KeywordPerformanceReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::ReportingService;
use Microsoft::AdCenter::V7::ReportingService::KeywordPerformanceReportFilter;

sub test_can_create_keyword_performance_report_filter_and_set_all_fields : Test(14) {
    my $keyword_performance_report_filter = Microsoft::AdCenter::V7::ReportingService::KeywordPerformanceReportFilter->new
        ->AdDistribution('ad distribution')
        ->AdType('ad type')
        ->BidMatchType('bid match type')
        ->Cashback('cashback')
        ->DeliveredMatchType('delivered match type')
        ->DeviceType('device type')
        ->KeywordRelevance('keyword relevance')
        ->Keywords('keywords')
        ->LandingPageRelevance('landing page relevance')
        ->LandingPageUserExperience('landing page user experience')
        ->LanguageAndRegion('language and region')
        ->LanguageCode('language code')
        ->QualityScore('quality score')
    ;

    ok($keyword_performance_report_filter);

    is($keyword_performance_report_filter->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($keyword_performance_report_filter->AdType, 'ad type', 'can get ad type');
    is($keyword_performance_report_filter->BidMatchType, 'bid match type', 'can get bid match type');
    is($keyword_performance_report_filter->Cashback, 'cashback', 'can get cashback');
    is($keyword_performance_report_filter->DeliveredMatchType, 'delivered match type', 'can get delivered match type');
    is($keyword_performance_report_filter->DeviceType, 'device type', 'can get device type');
    is($keyword_performance_report_filter->KeywordRelevance, 'keyword relevance', 'can get keyword relevance');
    is($keyword_performance_report_filter->Keywords, 'keywords', 'can get keywords');
    is($keyword_performance_report_filter->LandingPageRelevance, 'landing page relevance', 'can get landing page relevance');
    is($keyword_performance_report_filter->LandingPageUserExperience, 'landing page user experience', 'can get landing page user experience');
    is($keyword_performance_report_filter->LanguageAndRegion, 'language and region', 'can get language and region');
    is($keyword_performance_report_filter->LanguageCode, 'language code', 'can get language code');
    is($keyword_performance_report_filter->QualityScore, 'quality score', 'can get quality score');
};

1;
