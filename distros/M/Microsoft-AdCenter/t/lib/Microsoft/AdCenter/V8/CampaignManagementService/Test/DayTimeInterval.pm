package Microsoft::AdCenter::V8::CampaignManagementService::Test::DayTimeInterval;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DayTimeInterval;

sub test_can_create_day_time_interval_and_set_all_fields : Test(3) {
    my $day_time_interval = Microsoft::AdCenter::V8::CampaignManagementService::DayTimeInterval->new
        ->Begin('begin')
        ->End('end')
    ;

    ok($day_time_interval);

    is($day_time_interval->Begin, 'begin', 'can get begin');
    is($day_time_interval->End, 'end', 'can get end');
};

1;
