package Microsoft::AdCenter::V8::OptimizerService::Test::Opportunity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::OptimizerService;
use Microsoft::AdCenter::V8::OptimizerService::Opportunity;

sub test_can_create_opportunity_and_set_all_fields : Test(3) {
    my $opportunity = Microsoft::AdCenter::V8::OptimizerService::Opportunity->new
        ->ExpirationDate('2010-05-31T12:23:34')
        ->OpportunityKey('opportunity key')
    ;

    ok($opportunity);

    is($opportunity->ExpirationDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($opportunity->OpportunityKey, 'opportunity key', 'can get opportunity key');
};

1;
