package Microsoft::AdCenter::V8::NotificationService::Test::ApplicationFault;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::ApplicationFault;

sub test_can_create_application_fault_and_set_all_fields : Test(2) {
    my $application_fault = Microsoft::AdCenter::V8::NotificationService::ApplicationFault->new
        ->TrackingId('tracking id')
    ;

    ok($application_fault);

    is($application_fault->TrackingId, 'tracking id', 'can get tracking id');
};

1;
