package Microsoft::AdCenter::V8::NotificationService::Test::EditorialRejectionNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::EditorialRejectionNotification;

sub test_can_create_editorial_rejection_notification_and_set_all_fields : Test(1) {
    my $editorial_rejection_notification = Microsoft::AdCenter::V8::NotificationService::EditorialRejectionNotification->new
    ;

    ok($editorial_rejection_notification);

};

1;
