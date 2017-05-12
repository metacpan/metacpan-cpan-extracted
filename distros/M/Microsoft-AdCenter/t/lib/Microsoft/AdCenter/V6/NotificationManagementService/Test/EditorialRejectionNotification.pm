package Microsoft::AdCenter::V6::NotificationManagementService::Test::EditorialRejectionNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::EditorialRejectionNotification;

sub test_can_create_editorial_rejection_notification_and_set_all_fields : Test(27) {
    my $editorial_rejection_notification = Microsoft::AdCenter::V6::NotificationManagementService::EditorialRejectionNotification->new
        ->AccountId('account id')
        ->AccountName('account name')
        ->AccountNumber('account number')
        ->AdDescription('ad description')
        ->AdId('ad id')
        ->AdTitle('ad title')
        ->CampaignId('campaign id')
        ->CampaignName('campaign name')
        ->CustomerName('customer name')
        ->DestinationURL('destination url')
        ->DisplayURL('display url')
        ->KeywordsAccepted('keywords accepted')
        ->KeywordsPending('keywords pending')
        ->KeywordsRejected('keywords rejected')
        ->OrderId('order id')
        ->OrderName('order name')
        ->Top1Keyword('top1 keyword')
        ->Top1KeywordReason('top1 keyword reason')
        ->Top2Keyword('top2 keyword')
        ->Top2KeywordReason('top2 keyword reason')
        ->Top3Keyword('top3 keyword')
        ->Top3KeywordReason('top3 keyword reason')
        ->Top4Keyword('top4 keyword')
        ->Top4KeywordReason('top4 keyword reason')
        ->Top5Keyword('top5 keyword')
        ->Top5KeywordReason('top5 keyword reason')
    ;

    ok($editorial_rejection_notification);

    is($editorial_rejection_notification->AccountId, 'account id', 'can get account id');
    is($editorial_rejection_notification->AccountName, 'account name', 'can get account name');
    is($editorial_rejection_notification->AccountNumber, 'account number', 'can get account number');
    is($editorial_rejection_notification->AdDescription, 'ad description', 'can get ad description');
    is($editorial_rejection_notification->AdId, 'ad id', 'can get ad id');
    is($editorial_rejection_notification->AdTitle, 'ad title', 'can get ad title');
    is($editorial_rejection_notification->CampaignId, 'campaign id', 'can get campaign id');
    is($editorial_rejection_notification->CampaignName, 'campaign name', 'can get campaign name');
    is($editorial_rejection_notification->CustomerName, 'customer name', 'can get customer name');
    is($editorial_rejection_notification->DestinationURL, 'destination url', 'can get destination url');
    is($editorial_rejection_notification->DisplayURL, 'display url', 'can get display url');
    is($editorial_rejection_notification->KeywordsAccepted, 'keywords accepted', 'can get keywords accepted');
    is($editorial_rejection_notification->KeywordsPending, 'keywords pending', 'can get keywords pending');
    is($editorial_rejection_notification->KeywordsRejected, 'keywords rejected', 'can get keywords rejected');
    is($editorial_rejection_notification->OrderId, 'order id', 'can get order id');
    is($editorial_rejection_notification->OrderName, 'order name', 'can get order name');
    is($editorial_rejection_notification->Top1Keyword, 'top1 keyword', 'can get top1 keyword');
    is($editorial_rejection_notification->Top1KeywordReason, 'top1 keyword reason', 'can get top1 keyword reason');
    is($editorial_rejection_notification->Top2Keyword, 'top2 keyword', 'can get top2 keyword');
    is($editorial_rejection_notification->Top2KeywordReason, 'top2 keyword reason', 'can get top2 keyword reason');
    is($editorial_rejection_notification->Top3Keyword, 'top3 keyword', 'can get top3 keyword');
    is($editorial_rejection_notification->Top3KeywordReason, 'top3 keyword reason', 'can get top3 keyword reason');
    is($editorial_rejection_notification->Top4Keyword, 'top4 keyword', 'can get top4 keyword');
    is($editorial_rejection_notification->Top4KeywordReason, 'top4 keyword reason', 'can get top4 keyword reason');
    is($editorial_rejection_notification->Top5Keyword, 'top5 keyword', 'can get top5 keyword');
    is($editorial_rejection_notification->Top5KeywordReason, 'top5 keyword reason', 'can get top5 keyword reason');
};

1;
