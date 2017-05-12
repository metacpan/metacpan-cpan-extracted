package Microsoft::AdCenter::V8::OptimizerService::ErrorCodes;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::OptimizerService::ErrorCodes - Represents "ErrorCodes" in Microsoft AdCenter Optimizer Service.

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=head1 ENUMERATION VALUES

    AccountIdHasToBeSpecified
    APIExecutionError
    ApiInputValidationError
    BidAmountsLessThanFloorPrice
    BidsAmountsGreaterThanCeilingPrice
    CampaignBudgetAmountIsAboveLimit
    CampaignBudgetAmountIsBelowConfiguredLimit
    CampaignBudgetAmountIsLessThanSpendAmount
    CampaignBudgetLessThanAdGroupBudget
    CampaignDailyTargetBudgetAmountIsInvalid
    ConcurrentRequestOverLimit
    CustomerIdHasToBeSpecified
    EntityNotExistent
    FilterListOverLimit
    FutureFeatureCode
    IncrementalBudgetAmountRequiredForDayTarget
    InternalError
    InvalidAccount
    InvalidAccountId
    InvalidCredentials
    InvalidCustomerId
    InvalidDateObject
    InvalidOpportunityKey
    InvalidOpportunityKeysList
    InvalidVersion
    KeywordBroadBidAmountsGreaterThanCeilingPrice
    KeywordBroadBidAmountsLessThanFloorPrice
    KeywordExactBidAmountsGreaterThanCeilingPrice
    KeywordExactBidAmountsLessThanFloorPrice
    KeywordPhraseBidAmountsGreaterThanCeilingPrice
    KeywordPhraseBidAmountsLessThanFloorPrice
    NameTooLong
    NullArrayArgument
    NullParameter
    NullRequest
    OperationNotSupported
    OpportunityAlreadyApplied
    OpportunityExpired
    OpportunityKeysArrayExceedsLimit
    OpportunityKeysArrayShouldNotBeNullOrEmpty
    QuotaNotAvailable
    RequestMissingHeaders
    TimestampNotMatch
    UserIsNotAuthorized

=cut

sub AccountIdHasToBeSpecified {
    return 'AccountIdHasToBeSpecified';
}

sub APIExecutionError {
    return 'APIExecutionError';
}

sub ApiInputValidationError {
    return 'ApiInputValidationError';
}

sub BidAmountsLessThanFloorPrice {
    return 'BidAmountsLessThanFloorPrice';
}

sub BidsAmountsGreaterThanCeilingPrice {
    return 'BidsAmountsGreaterThanCeilingPrice';
}

sub CampaignBudgetAmountIsAboveLimit {
    return 'CampaignBudgetAmountIsAboveLimit';
}

sub CampaignBudgetAmountIsBelowConfiguredLimit {
    return 'CampaignBudgetAmountIsBelowConfiguredLimit';
}

sub CampaignBudgetAmountIsLessThanSpendAmount {
    return 'CampaignBudgetAmountIsLessThanSpendAmount';
}

sub CampaignBudgetLessThanAdGroupBudget {
    return 'CampaignBudgetLessThanAdGroupBudget';
}

sub CampaignDailyTargetBudgetAmountIsInvalid {
    return 'CampaignDailyTargetBudgetAmountIsInvalid';
}

sub ConcurrentRequestOverLimit {
    return 'ConcurrentRequestOverLimit';
}

sub CustomerIdHasToBeSpecified {
    return 'CustomerIdHasToBeSpecified';
}

sub EntityNotExistent {
    return 'EntityNotExistent';
}

sub FilterListOverLimit {
    return 'FilterListOverLimit';
}

sub FutureFeatureCode {
    return 'FutureFeatureCode';
}

sub IncrementalBudgetAmountRequiredForDayTarget {
    return 'IncrementalBudgetAmountRequiredForDayTarget';
}

sub InternalError {
    return 'InternalError';
}

sub InvalidAccount {
    return 'InvalidAccount';
}

sub InvalidAccountId {
    return 'InvalidAccountId';
}

sub InvalidCredentials {
    return 'InvalidCredentials';
}

sub InvalidCustomerId {
    return 'InvalidCustomerId';
}

sub InvalidDateObject {
    return 'InvalidDateObject';
}

sub InvalidOpportunityKey {
    return 'InvalidOpportunityKey';
}

sub InvalidOpportunityKeysList {
    return 'InvalidOpportunityKeysList';
}

sub InvalidVersion {
    return 'InvalidVersion';
}

sub KeywordBroadBidAmountsGreaterThanCeilingPrice {
    return 'KeywordBroadBidAmountsGreaterThanCeilingPrice';
}

sub KeywordBroadBidAmountsLessThanFloorPrice {
    return 'KeywordBroadBidAmountsLessThanFloorPrice';
}

sub KeywordExactBidAmountsGreaterThanCeilingPrice {
    return 'KeywordExactBidAmountsGreaterThanCeilingPrice';
}

sub KeywordExactBidAmountsLessThanFloorPrice {
    return 'KeywordExactBidAmountsLessThanFloorPrice';
}

sub KeywordPhraseBidAmountsGreaterThanCeilingPrice {
    return 'KeywordPhraseBidAmountsGreaterThanCeilingPrice';
}

sub KeywordPhraseBidAmountsLessThanFloorPrice {
    return 'KeywordPhraseBidAmountsLessThanFloorPrice';
}

sub NameTooLong {
    return 'NameTooLong';
}

sub NullArrayArgument {
    return 'NullArrayArgument';
}

sub NullParameter {
    return 'NullParameter';
}

sub NullRequest {
    return 'NullRequest';
}

sub OperationNotSupported {
    return 'OperationNotSupported';
}

sub OpportunityAlreadyApplied {
    return 'OpportunityAlreadyApplied';
}

sub OpportunityExpired {
    return 'OpportunityExpired';
}

sub OpportunityKeysArrayExceedsLimit {
    return 'OpportunityKeysArrayExceedsLimit';
}

sub OpportunityKeysArrayShouldNotBeNullOrEmpty {
    return 'OpportunityKeysArrayShouldNotBeNullOrEmpty';
}

sub QuotaNotAvailable {
    return 'QuotaNotAvailable';
}

sub RequestMissingHeaders {
    return 'RequestMissingHeaders';
}

sub TimestampNotMatch {
    return 'TimestampNotMatch';
}

sub UserIsNotAuthorized {
    return 'UserIsNotAuthorized';
}

1;
