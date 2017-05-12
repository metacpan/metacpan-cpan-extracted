package Microsoft::AdCenter::V7::CampaignManagementService::Test::TimeOfTheDay;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::TimeOfTheDay;

sub test_can_create_time_of_the_day_and_set_all_fields : Test(3) {
    my $time_of_the_day = Microsoft::AdCenter::V7::CampaignManagementService::TimeOfTheDay->new
        ->Hour('hour')
        ->Minute('minute')
    ;

    ok($time_of_the_day);

    is($time_of_the_day->Hour, 'hour', 'can get hour');
    is($time_of_the_day->Minute, 'minute', 'can get minute');
};

1;
