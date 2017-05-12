package Microsoft::AdCenter::V6::CustomerManagementService::Test::CustomerUpdateResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::CustomerUpdateResponseMsg;

sub test_can_create_customer_update_response_msg_and_set_all_fields : Test(1) {
    my $customer_update_response_msg = Microsoft::AdCenter::V6::CustomerManagementService::CustomerUpdateResponseMsg->new
    ;

    ok($customer_update_response_msg);

};

1;
