package Google::Cloud::Commerceproducer::V1beta::Sku::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Sku',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku'];

coerce 'Sku',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku'->new($_) };

declare 'RepeatedSku',
    as ArrayRef[Sku()];

coerce 'RepeatedSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku'->new($_) } @$_ ] };

declare 'MapStringSku',
    as HashRef[Sku()];

declare 'SkuPrice',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice'];

coerce 'SkuPrice',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice'->new($_) };

declare 'RepeatedSkuPrice',
    as ArrayRef[SkuPrice()];

coerce 'RepeatedSkuPrice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice'->new($_) } @$_ ] };

declare 'MapStringSkuPrice',
    as HashRef[SkuPrice()];

declare 'InactiveSkuPrice',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::InactiveSkuPrice'];

coerce 'InactiveSkuPrice',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::InactiveSkuPrice'->new($_) };

declare 'RepeatedInactiveSkuPrice',
    as ArrayRef[InactiveSkuPrice()];

coerce 'RepeatedInactiveSkuPrice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::InactiveSkuPrice'->new($_) } @$_ ] };

declare 'MapStringInactiveSkuPrice',
    as HashRef[InactiveSkuPrice()];

declare 'ManagedServiceMetricUsageFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ManagedServiceMetricUsageFee'];

coerce 'ManagedServiceMetricUsageFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ManagedServiceMetricUsageFee'->new($_) };

declare 'RepeatedManagedServiceMetricUsageFee',
    as ArrayRef[ManagedServiceMetricUsageFee()];

coerce 'RepeatedManagedServiceMetricUsageFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ManagedServiceMetricUsageFee'->new($_) } @$_ ] };

declare 'MapStringManagedServiceMetricUsageFee',
    as HashRef[ManagedServiceMetricUsageFee()];

declare 'ComputeEngineLicenseUsageFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ComputeEngineLicenseUsageFee'];

coerce 'ComputeEngineLicenseUsageFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ComputeEngineLicenseUsageFee'->new($_) };

declare 'RepeatedComputeEngineLicenseUsageFee',
    as ArrayRef[ComputeEngineLicenseUsageFee()];

coerce 'RepeatedComputeEngineLicenseUsageFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ComputeEngineLicenseUsageFee'->new($_) } @$_ ] };

declare 'MapStringComputeEngineLicenseUsageFee',
    as HashRef[ComputeEngineLicenseUsageFee()];

declare 'MachineResource',
    as (Int | Str);

declare 'UsageCalculation',
    as (Int | Str);

declare 'MachineResourceRange',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ComputeEngineLicenseUsageFee::MachineResourceRange'];

coerce 'MachineResourceRange',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ComputeEngineLicenseUsageFee::MachineResourceRange'->new($_) };

declare 'RepeatedMachineResourceRange',
    as ArrayRef[MachineResourceRange()];

coerce 'RepeatedMachineResourceRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::ComputeEngineLicenseUsageFee::MachineResourceRange'->new($_) } @$_ ] };

declare 'MapStringMachineResourceRange',
    as HashRef[MachineResourceRange()];

declare 'KubernetesEnginePodUsageFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::KubernetesEnginePodUsageFee'];

coerce 'KubernetesEnginePodUsageFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::KubernetesEnginePodUsageFee'->new($_) };

declare 'RepeatedKubernetesEnginePodUsageFee',
    as ArrayRef[KubernetesEnginePodUsageFee()];

coerce 'RepeatedKubernetesEnginePodUsageFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::KubernetesEnginePodUsageFee'->new($_) } @$_ ] };

declare 'MapStringKubernetesEnginePodUsageFee',
    as HashRef[KubernetesEnginePodUsageFee()];

declare 'PodResource',
    as (Int | Str);

declare 'UsageCalculation',
    as (Int | Str);

declare 'PodResourceRange',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::KubernetesEnginePodUsageFee::PodResourceRange'];

coerce 'PodResourceRange',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::KubernetesEnginePodUsageFee::PodResourceRange'->new($_) };

declare 'RepeatedPodResourceRange',
    as ArrayRef[PodResourceRange()];

coerce 'RepeatedPodResourceRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::KubernetesEnginePodUsageFee::PodResourceRange'->new($_) } @$_ ] };

declare 'MapStringPodResourceRange',
    as HashRef[PodResourceRange()];

declare 'AiPlatformManagedModelUsageFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee'];

coerce 'AiPlatformManagedModelUsageFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee'->new($_) };

declare 'RepeatedAiPlatformManagedModelUsageFee',
    as ArrayRef[AiPlatformManagedModelUsageFee()];

coerce 'RepeatedAiPlatformManagedModelUsageFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee'->new($_) } @$_ ] };

declare 'MapStringAiPlatformManagedModelUsageFee',
    as HashRef[AiPlatformManagedModelUsageFee()];

declare 'PredictionMode',
    as (Int | Str);

declare 'AiPlatformManagedModelUsageMetric',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric'];

coerce 'AiPlatformManagedModelUsageMetric',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric'->new($_) };

declare 'RepeatedAiPlatformManagedModelUsageMetric',
    as ArrayRef[AiPlatformManagedModelUsageMetric()];

coerce 'RepeatedAiPlatformManagedModelUsageMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric'->new($_) } @$_ ] };

declare 'MapStringAiPlatformManagedModelUsageMetric',
    as HashRef[AiPlatformManagedModelUsageMetric()];

declare 'InputTokensMetric',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::InputTokensMetric'];

coerce 'InputTokensMetric',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::InputTokensMetric'->new($_) };

declare 'RepeatedInputTokensMetric',
    as ArrayRef[InputTokensMetric()];

coerce 'RepeatedInputTokensMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::InputTokensMetric'->new($_) } @$_ ] };

declare 'MapStringInputTokensMetric',
    as HashRef[InputTokensMetric()];

declare 'CacheReadInputTokensMetric',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::CacheReadInputTokensMetric'];

coerce 'CacheReadInputTokensMetric',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::CacheReadInputTokensMetric'->new($_) };

declare 'RepeatedCacheReadInputTokensMetric',
    as ArrayRef[CacheReadInputTokensMetric()];

coerce 'RepeatedCacheReadInputTokensMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::CacheReadInputTokensMetric'->new($_) } @$_ ] };

declare 'MapStringCacheReadInputTokensMetric',
    as HashRef[CacheReadInputTokensMetric()];

declare 'CacheWriteInputTokensMetric',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::CacheWriteInputTokensMetric'];

coerce 'CacheWriteInputTokensMetric',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::CacheWriteInputTokensMetric'->new($_) };

declare 'RepeatedCacheWriteInputTokensMetric',
    as ArrayRef[CacheWriteInputTokensMetric()];

coerce 'RepeatedCacheWriteInputTokensMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::CacheWriteInputTokensMetric'->new($_) } @$_ ] };

declare 'MapStringCacheWriteInputTokensMetric',
    as HashRef[CacheWriteInputTokensMetric()];

declare 'OutputTokensMetric',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::OutputTokensMetric'];

coerce 'OutputTokensMetric',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::OutputTokensMetric'->new($_) };

declare 'RepeatedOutputTokensMetric',
    as ArrayRef[OutputTokensMetric()];

coerce 'RepeatedOutputTokensMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::OutputTokensMetric'->new($_) } @$_ ] };

declare 'MapStringOutputTokensMetric',
    as HashRef[OutputTokensMetric()];

declare 'WebSearchRequestsMetric',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::WebSearchRequestsMetric'];

coerce 'WebSearchRequestsMetric',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::WebSearchRequestsMetric'->new($_) };

declare 'RepeatedWebSearchRequestsMetric',
    as ArrayRef[WebSearchRequestsMetric()];

coerce 'RepeatedWebSearchRequestsMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::AiPlatformManagedModelUsageMetric::WebSearchRequestsMetric'->new($_) } @$_ ] };

declare 'MapStringWebSearchRequestsMetric',
    as HashRef[WebSearchRequestsMetric()];

declare 'CombinedRequestInputTokensRange',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::CombinedRequestInputTokensRange'];

coerce 'CombinedRequestInputTokensRange',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::CombinedRequestInputTokensRange'->new($_) };

declare 'RepeatedCombinedRequestInputTokensRange',
    as ArrayRef[CombinedRequestInputTokensRange()];

coerce 'RepeatedCombinedRequestInputTokensRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::CombinedRequestInputTokensRange'->new($_) } @$_ ] };

declare 'MapStringCombinedRequestInputTokensRange',
    as HashRef[CombinedRequestInputTokensRange()];

declare 'ProvisionedThroughputOverage',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::ProvisionedThroughputOverage'];

coerce 'ProvisionedThroughputOverage',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::ProvisionedThroughputOverage'->new($_) };

declare 'RepeatedProvisionedThroughputOverage',
    as ArrayRef[ProvisionedThroughputOverage()];

coerce 'RepeatedProvisionedThroughputOverage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelUsageFee::ProvisionedThroughputOverage'->new($_) } @$_ ] };

declare 'MapStringProvisionedThroughputOverage',
    as HashRef[ProvisionedThroughputOverage()];

declare 'AiPlatformProvisionedThroughputFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformProvisionedThroughputFee'];

coerce 'AiPlatformProvisionedThroughputFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformProvisionedThroughputFee'->new($_) };

declare 'RepeatedAiPlatformProvisionedThroughputFee',
    as ArrayRef[AiPlatformProvisionedThroughputFee()];

coerce 'RepeatedAiPlatformProvisionedThroughputFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformProvisionedThroughputFee'->new($_) } @$_ ] };

declare 'MapStringAiPlatformProvisionedThroughputFee',
    as HashRef[AiPlatformProvisionedThroughputFee()];

declare 'AiPlatformDeployedModelUsageFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformDeployedModelUsageFee'];

coerce 'AiPlatformDeployedModelUsageFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformDeployedModelUsageFee'->new($_) };

declare 'RepeatedAiPlatformDeployedModelUsageFee',
    as ArrayRef[AiPlatformDeployedModelUsageFee()];

coerce 'RepeatedAiPlatformDeployedModelUsageFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformDeployedModelUsageFee'->new($_) } @$_ ] };

declare 'MapStringAiPlatformDeployedModelUsageFee',
    as HashRef[AiPlatformDeployedModelUsageFee()];

declare 'UsageCalculation',
    as (Int | Str);

declare 'FlatSubscriptionFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::FlatSubscriptionFee'];

coerce 'FlatSubscriptionFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::FlatSubscriptionFee'->new($_) };

declare 'RepeatedFlatSubscriptionFee',
    as ArrayRef[FlatSubscriptionFee()];

coerce 'RepeatedFlatSubscriptionFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::FlatSubscriptionFee'->new($_) } @$_ ] };

declare 'MapStringFlatSubscriptionFee',
    as HashRef[FlatSubscriptionFee()];

declare 'TieredPrice',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::TieredPrice'];

coerce 'TieredPrice',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::TieredPrice'->new($_) };

declare 'RepeatedTieredPrice',
    as ArrayRef[TieredPrice()];

coerce 'RepeatedTieredPrice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::TieredPrice'->new($_) } @$_ ] };

declare 'MapStringTieredPrice',
    as HashRef[TieredPrice()];

declare 'PriceTier',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::TieredPrice::PriceTier'];

coerce 'PriceTier',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::TieredPrice::PriceTier'->new($_) };

declare 'RepeatedPriceTier',
    as ArrayRef[PriceTier()];

coerce 'RepeatedPriceTier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::TieredPrice::PriceTier'->new($_) } @$_ ] };

declare 'MapStringPriceTier',
    as HashRef[PriceTier()];

declare 'AiPlatformManagedModelEndpointLocation',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelEndpointLocation'];

coerce 'AiPlatformManagedModelEndpointLocation',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelEndpointLocation'->new($_) };

declare 'RepeatedAiPlatformManagedModelEndpointLocation',
    as ArrayRef[AiPlatformManagedModelEndpointLocation()];

coerce 'RepeatedAiPlatformManagedModelEndpointLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::Sku::Sku::SkuPrice::AiPlatformManagedModelEndpointLocation'->new($_) } @$_ ] };

declare 'MapStringAiPlatformManagedModelEndpointLocation',
    as HashRef[AiPlatformManagedModelEndpointLocation()];

1;

__END__

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::Sku::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
