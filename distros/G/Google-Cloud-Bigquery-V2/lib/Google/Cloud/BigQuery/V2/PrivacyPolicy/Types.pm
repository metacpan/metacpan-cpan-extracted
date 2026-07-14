package Google::Cloud::BigQuery::V2::PrivacyPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AggregationThresholdPolicy',
    as InstanceOf['Google::Cloud::BigQuery::V2::PrivacyPolicy::AggregationThresholdPolicy'];

coerce 'AggregationThresholdPolicy',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::AggregationThresholdPolicy'->new($_) };

declare 'RepeatedAggregationThresholdPolicy',
    as ArrayRef[AggregationThresholdPolicy()];

coerce 'RepeatedAggregationThresholdPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::AggregationThresholdPolicy'->new($_) } @$_ ] };

declare 'MapStringAggregationThresholdPolicy',
    as HashRef[AggregationThresholdPolicy()];

declare 'DifferentialPrivacyPolicy',
    as InstanceOf['Google::Cloud::BigQuery::V2::PrivacyPolicy::DifferentialPrivacyPolicy'];

coerce 'DifferentialPrivacyPolicy',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::DifferentialPrivacyPolicy'->new($_) };

declare 'RepeatedDifferentialPrivacyPolicy',
    as ArrayRef[DifferentialPrivacyPolicy()];

coerce 'RepeatedDifferentialPrivacyPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::DifferentialPrivacyPolicy'->new($_) } @$_ ] };

declare 'MapStringDifferentialPrivacyPolicy',
    as HashRef[DifferentialPrivacyPolicy()];

declare 'JoinRestrictionPolicy',
    as InstanceOf['Google::Cloud::BigQuery::V2::PrivacyPolicy::JoinRestrictionPolicy'];

coerce 'JoinRestrictionPolicy',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::JoinRestrictionPolicy'->new($_) };

declare 'RepeatedJoinRestrictionPolicy',
    as ArrayRef[JoinRestrictionPolicy()];

coerce 'RepeatedJoinRestrictionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::JoinRestrictionPolicy'->new($_) } @$_ ] };

declare 'MapStringJoinRestrictionPolicy',
    as HashRef[JoinRestrictionPolicy()];

declare 'JoinCondition',
    as (Int | Str);

declare 'PrivacyPolicy',
    as InstanceOf['Google::Cloud::BigQuery::V2::PrivacyPolicy::PrivacyPolicy'];

coerce 'PrivacyPolicy',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::PrivacyPolicy'->new($_) };

declare 'RepeatedPrivacyPolicy',
    as ArrayRef[PrivacyPolicy()];

coerce 'RepeatedPrivacyPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::PrivacyPolicy::PrivacyPolicy'->new($_) } @$_ ] };

declare 'MapStringPrivacyPolicy',
    as HashRef[PrivacyPolicy()];

1;
