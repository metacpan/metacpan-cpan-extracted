package Google::Api::Quota::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Quota',
    as InstanceOf['Google::Api::Quota::Quota'];

coerce 'Quota',
    from HashRef, via { 'Google::Api::Quota::Quota'->new($_) };

declare 'RepeatedQuota',
    as ArrayRef[Quota()];

coerce 'RepeatedQuota',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Quota::Quota'->new($_) } @$_ ] };

declare 'MapStringQuota',
    as HashRef[Quota()];

declare 'MetricRule',
    as InstanceOf['Google::Api::Quota::MetricRule'];

coerce 'MetricRule',
    from HashRef, via { 'Google::Api::Quota::MetricRule'->new($_) };

declare 'RepeatedMetricRule',
    as ArrayRef[MetricRule()];

coerce 'RepeatedMetricRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Quota::MetricRule'->new($_) } @$_ ] };

declare 'MapStringMetricRule',
    as HashRef[MetricRule()];

declare 'MetricCostsEntry',
    as InstanceOf['Google::Api::Quota::MetricRule::MetricCostsEntry'];

coerce 'MetricCostsEntry',
    from HashRef, via { 'Google::Api::Quota::MetricRule::MetricCostsEntry'->new($_) };

declare 'RepeatedMetricCostsEntry',
    as ArrayRef[MetricCostsEntry()];

coerce 'RepeatedMetricCostsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Quota::MetricRule::MetricCostsEntry'->new($_) } @$_ ] };

declare 'MapStringMetricCostsEntry',
    as HashRef[MetricCostsEntry()];

declare 'QuotaLimit',
    as InstanceOf['Google::Api::Quota::QuotaLimit'];

coerce 'QuotaLimit',
    from HashRef, via { 'Google::Api::Quota::QuotaLimit'->new($_) };

declare 'RepeatedQuotaLimit',
    as ArrayRef[QuotaLimit()];

coerce 'RepeatedQuotaLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Quota::QuotaLimit'->new($_) } @$_ ] };

declare 'MapStringQuotaLimit',
    as HashRef[QuotaLimit()];

declare 'ValuesEntry',
    as InstanceOf['Google::Api::Quota::QuotaLimit::ValuesEntry'];

coerce 'ValuesEntry',
    from HashRef, via { 'Google::Api::Quota::QuotaLimit::ValuesEntry'->new($_) };

declare 'RepeatedValuesEntry',
    as ArrayRef[ValuesEntry()];

coerce 'RepeatedValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Quota::QuotaLimit::ValuesEntry'->new($_) } @$_ ] };

declare 'MapStringValuesEntry',
    as HashRef[ValuesEntry()];

1;
