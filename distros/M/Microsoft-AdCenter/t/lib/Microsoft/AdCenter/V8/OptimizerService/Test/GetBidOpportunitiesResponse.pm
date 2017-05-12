package Microsoft::AdCenter::V8::OptimizerService::Test::GetBidOpportunitiesResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::OptimizerService;
use Microsoft::AdCenter::V8::OptimizerService::GetBidOpportunitiesResponse;

sub test_can_create_get_bid_opportunities_response_and_set_all_fields : Test(2) {
    my $get_bid_opportunities_response = Microsoft::AdCenter::V8::OptimizerService::GetBidOpportunitiesResponse->new
        ->Opportunities('opportunities')
    ;

    ok($get_bid_opportunities_response);

    is($get_bid_opportunities_response->Opportunities, 'opportunities', 'can get opportunities');
};

1;
