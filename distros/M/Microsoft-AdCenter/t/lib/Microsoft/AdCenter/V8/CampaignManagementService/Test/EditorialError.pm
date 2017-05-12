package Microsoft::AdCenter::V8::CampaignManagementService::Test::EditorialError;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::EditorialError;

sub test_can_create_editorial_error_and_set_all_fields : Test(8) {
    my $editorial_error = Microsoft::AdCenter::V8::CampaignManagementService::EditorialError->new
        ->Appealable('appealable')
        ->Code('code')
        ->DisapprovedText('disapproved text')
        ->ErrorCode('error code')
        ->Index('index')
        ->Message('message')
        ->PublisherCountry('publisher country')
    ;

    ok($editorial_error);

    is($editorial_error->Appealable, 'appealable', 'can get appealable');
    is($editorial_error->Code, 'code', 'can get code');
    is($editorial_error->DisapprovedText, 'disapproved text', 'can get disapproved text');
    is($editorial_error->ErrorCode, 'error code', 'can get error code');
    is($editorial_error->Index, 'index', 'can get index');
    is($editorial_error->Message, 'message', 'can get message');
    is($editorial_error->PublisherCountry, 'publisher country', 'can get publisher country');
};

1;
