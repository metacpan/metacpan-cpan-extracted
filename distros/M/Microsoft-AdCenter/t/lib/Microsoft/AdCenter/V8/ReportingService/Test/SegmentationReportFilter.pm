package Microsoft::AdCenter::V8::ReportingService::Test::SegmentationReportFilter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::ReportingService;
use Microsoft::AdCenter::V8::ReportingService::SegmentationReportFilter;

sub test_can_create_segmentation_report_filter_and_set_all_fields : Test(6) {
    my $segmentation_report_filter = Microsoft::AdCenter::V8::ReportingService::SegmentationReportFilter->new
        ->AgeGroup('age group')
        ->Country('country')
        ->Gender('gender')
        ->GoalIds('goal ids')
        ->Keywords('keywords')
    ;

    ok($segmentation_report_filter);

    is($segmentation_report_filter->AgeGroup, 'age group', 'can get age group');
    is($segmentation_report_filter->Country, 'country', 'can get country');
    is($segmentation_report_filter->Gender, 'gender', 'can get gender');
    is($segmentation_report_filter->GoalIds, 'goal ids', 'can get goal ids');
    is($segmentation_report_filter->Keywords, 'keywords', 'can get keywords');
};

1;
