package Microsoft::AdCenter::V8::CampaignManagementService::Test::EditorialApiFaultDetail;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::EditorialApiFaultDetail;

sub test_can_create_editorial_api_fault_detail_and_set_all_fields : Test(4) {
    my $editorial_api_fault_detail = Microsoft::AdCenter::V8::CampaignManagementService::EditorialApiFaultDetail->new
        ->BatchErrors('batch errors')
        ->EditorialErrors('editorial errors')
        ->OperationErrors('operation errors')
    ;

    ok($editorial_api_fault_detail);

    is($editorial_api_fault_detail->BatchErrors, 'batch errors', 'can get batch errors');
    is($editorial_api_fault_detail->EditorialErrors, 'editorial errors', 'can get editorial errors');
    is($editorial_api_fault_detail->OperationErrors, 'operation errors', 'can get operation errors');
};

1;
