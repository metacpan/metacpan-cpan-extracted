package Microsoft::AdCenter::V6::CustomerManagementService::Test::ErrorInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::ErrorInfo;

sub test_can_create_error_info_and_set_all_fields : Test(4) {
    my $error_info = Microsoft::AdCenter::V6::CustomerManagementService::ErrorInfo->new
        ->errCode('err code')
        ->errLevel('err level')
        ->errMsg('err msg')
    ;

    ok($error_info);

    is($error_info->errCode, 'err code', 'can get err code');
    is($error_info->errLevel, 'err level', 'can get err level');
    is($error_info->errMsg, 'err msg', 'can get err msg');
};

1;
