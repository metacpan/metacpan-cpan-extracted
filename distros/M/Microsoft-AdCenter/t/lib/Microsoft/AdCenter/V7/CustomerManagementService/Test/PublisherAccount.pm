package Microsoft::AdCenter::V7::CustomerManagementService::Test::PublisherAccount;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::PublisherAccount;

sub test_can_create_publisher_account_and_set_all_fields : Test(1) {
    my $publisher_account = Microsoft::AdCenter::V7::CustomerManagementService::PublisherAccount->new
    ;

    ok($publisher_account);

};

1;
