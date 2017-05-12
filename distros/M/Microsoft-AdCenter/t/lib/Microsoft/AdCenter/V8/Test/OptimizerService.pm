package Microsoft::AdCenter::V8::Test::OptimizerService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::OptimizerService;

sub test_can_create_v8_optimizer_service_and_set_all_fields : Test(9) {
    my $v8_optimizer_service = Microsoft::AdCenter::V8::OptimizerService->new
        ->EndPoint('http://some.where.that/does/not/exists')
        ->ApplicationToken('application token')
        ->CustomerAccountId('customer account id')
        ->CustomerId('customer id')
        ->DeveloperToken('developer token')
        ->Password('password')
        ->UserName('user name')
        ->TrackingId('tracking id')
    ;

    ok($v8_optimizer_service);

    is($v8_optimizer_service->EndPoint, 'http://some.where.that/does/not/exists', 'can get end point');
    is($v8_optimizer_service->ApplicationToken, 'application token', 'can get application token');
    is($v8_optimizer_service->CustomerAccountId, 'customer account id', 'can get customer account id');
    is($v8_optimizer_service->CustomerId, 'customer id', 'can get customer id');
    is($v8_optimizer_service->DeveloperToken, 'developer token', 'can get developer token');
    is($v8_optimizer_service->Password, 'password', 'can get password');
    is($v8_optimizer_service->UserName, 'user name', 'can get user name');
    is($v8_optimizer_service->TrackingId, 'tracking id', 'can get tracking id');
};

1;
