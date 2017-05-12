package Microsoft::AdCenter::V8::BulkService::Test::AdApiError;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::BulkService;
use Microsoft::AdCenter::V8::BulkService::AdApiError;

sub test_can_create_ad_api_error_and_set_all_fields : Test(5) {
    my $ad_api_error = Microsoft::AdCenter::V8::BulkService::AdApiError->new
        ->Code('code')
        ->Detail('detail')
        ->ErrorCode('error code')
        ->Message('message')
    ;

    ok($ad_api_error);

    is($ad_api_error->Code, 'code', 'can get code');
    is($ad_api_error->Detail, 'detail', 'can get detail');
    is($ad_api_error->ErrorCode, 'error code', 'can get error code');
    is($ad_api_error->Message, 'message', 'can get message');
};

1;
