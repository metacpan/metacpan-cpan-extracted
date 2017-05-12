package Microsoft::AdCenter::V7::CampaignManagementService::Test::Target;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::Target;

sub test_can_create_target_and_set_all_fields : Test(12) {
    my $target = Microsoft::AdCenter::V7::CampaignManagementService::Target->new
        ->Age('age')
        ->Behavior('behavior')
        ->Day('day')
        ->Device('device')
        ->Gender('gender')
        ->Hour('hour')
        ->Id('id')
        ->IsLibraryTarget('is library target')
        ->Location('location')
        ->Name('name')
        ->Segment('segment')
    ;

    ok($target);

    is($target->Age, 'age', 'can get age');
    is($target->Behavior, 'behavior', 'can get behavior');
    is($target->Day, 'day', 'can get day');
    is($target->Device, 'device', 'can get device');
    is($target->Gender, 'gender', 'can get gender');
    is($target->Hour, 'hour', 'can get hour');
    is($target->Id, 'id', 'can get id');
    is($target->IsLibraryTarget, 'is library target', 'can get is library target');
    is($target->Location, 'location', 'can get location');
    is($target->Name, 'name', 'can get name');
    is($target->Segment, 'segment', 'can get segment');
};

1;
