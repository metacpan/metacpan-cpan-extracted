package Microsoft::AdCenter::V7::CampaignManagementService::Test::Segment;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::Segment;

sub test_can_create_segment_and_set_all_fields : Test(3) {
    my $segment = Microsoft::AdCenter::V7::CampaignManagementService::Segment->new
        ->Id('id')
        ->Name('name')
    ;

    ok($segment);

    is($segment->Id, 'id', 'can get id');
    is($segment->Name, 'name', 'can get name');
};

1;
