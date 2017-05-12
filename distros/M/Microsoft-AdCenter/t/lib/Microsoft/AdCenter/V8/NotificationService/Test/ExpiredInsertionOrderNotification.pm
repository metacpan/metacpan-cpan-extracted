package Microsoft::AdCenter::V8::NotificationService::Test::ExpiredInsertionOrderNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::ExpiredInsertionOrderNotification;

sub test_can_create_expired_insertion_order_notification_and_set_all_fields : Test(2) {
    my $expired_insertion_order_notification = Microsoft::AdCenter::V8::NotificationService::ExpiredInsertionOrderNotification->new
        ->BillToCustomerName('bill to customer name')
    ;

    ok($expired_insertion_order_notification);

    is($expired_insertion_order_notification->BillToCustomerName, 'bill to customer name', 'can get bill to customer name');
};

1;
