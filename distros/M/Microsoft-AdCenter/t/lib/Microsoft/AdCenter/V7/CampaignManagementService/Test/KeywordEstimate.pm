package Microsoft::AdCenter::V7::CampaignManagementService::Test::KeywordEstimate;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::KeywordEstimate;

sub test_can_create_keyword_estimate_and_set_all_fields : Test(7) {
    my $keyword_estimate = Microsoft::AdCenter::V7::CampaignManagementService::KeywordEstimate->new
        ->AverageMonthlyCost('average monthly cost')
        ->AverageMonthlyPosition('average monthly position')
        ->BroadKeywordEstimate('broad keyword estimate')
        ->EstimatedTotalMonthlyImpressions('estimated total monthly impressions')
        ->ExactKeywordEstimate('exact keyword estimate')
        ->PhraseKeywordEstimate('phrase keyword estimate')
    ;

    ok($keyword_estimate);

    is($keyword_estimate->AverageMonthlyCost, 'average monthly cost', 'can get average monthly cost');
    is($keyword_estimate->AverageMonthlyPosition, 'average monthly position', 'can get average monthly position');
    is($keyword_estimate->BroadKeywordEstimate, 'broad keyword estimate', 'can get broad keyword estimate');
    is($keyword_estimate->EstimatedTotalMonthlyImpressions, 'estimated total monthly impressions', 'can get estimated total monthly impressions');
    is($keyword_estimate->ExactKeywordEstimate, 'exact keyword estimate', 'can get exact keyword estimate');
    is($keyword_estimate->PhraseKeywordEstimate, 'phrase keyword estimate', 'can get phrase keyword estimate');
};

1;
