package Microsoft::AdCenter::V8::CampaignManagementService::Test::PhoneExtension;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::PhoneExtension;

sub test_can_create_phone_extension_and_set_all_fields : Test(5) {
    my $phone_extension = Microsoft::AdCenter::V8::CampaignManagementService::PhoneExtension->new
        ->Country('country')
        ->EnableClickToCallOnly('enable click to call only')
        ->EnablePhoneExtension('enable phone extension')
        ->Phone('phone')
    ;

    ok($phone_extension);

    is($phone_extension->Country, 'country', 'can get country');
    is($phone_extension->EnableClickToCallOnly, 'enable click to call only', 'can get enable click to call only');
    is($phone_extension->EnablePhoneExtension, 'enable phone extension', 'can get enable phone extension');
    is($phone_extension->Phone, 'phone', 'can get phone');
};

1;
