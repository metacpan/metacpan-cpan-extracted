package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterContactInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterContactInfo;

sub test_can_create_ad_center_contact_info_and_set_all_fields : Test(6) {
    my $ad_center_contact_info = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterContactInfo->new
        ->Fax('fax')
        ->HomePhone('home phone')
        ->Mobile('mobile')
        ->Phone1('phone1')
        ->Phone2('phone2')
    ;

    ok($ad_center_contact_info);

    is($ad_center_contact_info->Fax, 'fax', 'can get fax');
    is($ad_center_contact_info->HomePhone, 'home phone', 'can get home phone');
    is($ad_center_contact_info->Mobile, 'mobile', 'can get mobile');
    is($ad_center_contact_info->Phone1, 'phone1', 'can get phone1');
    is($ad_center_contact_info->Phone2, 'phone2', 'can get phone2');
};

1;
