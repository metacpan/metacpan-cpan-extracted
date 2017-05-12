package Microsoft::AdCenter::V8::CampaignManagementService::Test::Keyword;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::Keyword;

sub test_can_create_keyword_and_set_all_fields : Test(13) {
    my $keyword = Microsoft::AdCenter::V8::CampaignManagementService::Keyword->new
        ->BroadMatchBid('broad match bid')
        ->ContentMatchBid('content match bid')
        ->EditorialStatus('editorial status')
        ->ExactMatchBid('exact match bid')
        ->Id('id')
        ->NegativeKeywords('negative keywords')
        ->Param1('param1')
        ->Param2('param2')
        ->Param3('param3')
        ->PhraseMatchBid('phrase match bid')
        ->Status('status')
        ->Text('text')
    ;

    ok($keyword);

    is($keyword->BroadMatchBid, 'broad match bid', 'can get broad match bid');
    is($keyword->ContentMatchBid, 'content match bid', 'can get content match bid');
    is($keyword->EditorialStatus, 'editorial status', 'can get editorial status');
    is($keyword->ExactMatchBid, 'exact match bid', 'can get exact match bid');
    is($keyword->Id, 'id', 'can get id');
    is($keyword->NegativeKeywords, 'negative keywords', 'can get negative keywords');
    is($keyword->Param1, 'param1', 'can get param1');
    is($keyword->Param2, 'param2', 'can get param2');
    is($keyword->Param3, 'param3', 'can get param3');
    is($keyword->PhraseMatchBid, 'phrase match bid', 'can get phrase match bid');
    is($keyword->Status, 'status', 'can get status');
    is($keyword->Text, 'text', 'can get text');
};

1;
