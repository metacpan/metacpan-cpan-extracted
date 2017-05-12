package Microsoft::AdCenter::V8::CustomerBillingService::Test::UpdateInsertionOrderResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::UpdateInsertionOrderResponse;

sub test_can_create_update_insertion_order_response_and_set_all_fields : Test(2) {
    my $update_insertion_order_response = Microsoft::AdCenter::V8::CustomerBillingService::UpdateInsertionOrderResponse->new
        ->LastModifiedTime('2010-05-31T12:23:34')
    ;

    ok($update_insertion_order_response);

    is($update_insertion_order_response->LastModifiedTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
};

1;
