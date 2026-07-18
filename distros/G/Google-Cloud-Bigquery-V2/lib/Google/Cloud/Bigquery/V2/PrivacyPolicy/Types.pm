# Copyright (C) 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Cloud::Bigquery::V2::PrivacyPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ColumnUsageConfig',
    as InstanceOf['Google::Cloud::Bigquery::V2::PrivacyPolicy::ColumnUsageConfig'];

coerce 'ColumnUsageConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::ColumnUsageConfig'->new($_) };

declare 'RepeatedColumnUsageConfig',
    as ArrayRef[ColumnUsageConfig()];

coerce 'RepeatedColumnUsageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::ColumnUsageConfig'->new($_) } @$_ ] };

declare 'MapStringColumnUsageConfig',
    as HashRef[ColumnUsageConfig()];

declare 'AggregationThresholdPolicy',
    as InstanceOf['Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy'];

coerce 'AggregationThresholdPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy'->new($_) };

declare 'RepeatedAggregationThresholdPolicy',
    as ArrayRef[AggregationThresholdPolicy()];

coerce 'RepeatedAggregationThresholdPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::AggregationThresholdPolicy'->new($_) } @$_ ] };

declare 'MapStringAggregationThresholdPolicy',
    as HashRef[AggregationThresholdPolicy()];

declare 'DifferentialPrivacyPolicy',
    as InstanceOf['Google::Cloud::Bigquery::V2::PrivacyPolicy::DifferentialPrivacyPolicy'];

coerce 'DifferentialPrivacyPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::DifferentialPrivacyPolicy'->new($_) };

declare 'RepeatedDifferentialPrivacyPolicy',
    as ArrayRef[DifferentialPrivacyPolicy()];

coerce 'RepeatedDifferentialPrivacyPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::DifferentialPrivacyPolicy'->new($_) } @$_ ] };

declare 'MapStringDifferentialPrivacyPolicy',
    as HashRef[DifferentialPrivacyPolicy()];

declare 'JoinRestrictionPolicy',
    as InstanceOf['Google::Cloud::Bigquery::V2::PrivacyPolicy::JoinRestrictionPolicy'];

coerce 'JoinRestrictionPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::JoinRestrictionPolicy'->new($_) };

declare 'RepeatedJoinRestrictionPolicy',
    as ArrayRef[JoinRestrictionPolicy()];

coerce 'RepeatedJoinRestrictionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::JoinRestrictionPolicy'->new($_) } @$_ ] };

declare 'MapStringJoinRestrictionPolicy',
    as HashRef[JoinRestrictionPolicy()];

declare 'JoinCondition',
    as (Int | Str);

declare 'PrivacyPolicy',
    as InstanceOf['Google::Cloud::Bigquery::V2::PrivacyPolicy::PrivacyPolicy'];

coerce 'PrivacyPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::PrivacyPolicy'->new($_) };

declare 'RepeatedPrivacyPolicy',
    as ArrayRef[PrivacyPolicy()];

coerce 'RepeatedPrivacyPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::PrivacyPolicy::PrivacyPolicy'->new($_) } @$_ ] };

declare 'MapStringPrivacyPolicy',
    as HashRef[PrivacyPolicy()];

1;
