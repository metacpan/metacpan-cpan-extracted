package Microsoft::AdCenter::V8::CustomerManagementService::Test::MapAccountIdToExternalAccountIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::MapAccountIdToExternalAccountIdsResponse;

sub test_can_create_map_account_id_to_external_account_ids_response_and_set_all_fields : Test(1) {
    my $map_account_id_to_external_account_ids_response = Microsoft::AdCenter::V8::CustomerManagementService::MapAccountIdToExternalAccountIdsResponse->new
    ;

    ok($map_account_id_to_external_account_ids_response);

};

1;
