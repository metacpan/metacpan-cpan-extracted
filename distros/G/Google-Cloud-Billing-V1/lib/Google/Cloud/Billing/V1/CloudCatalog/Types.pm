package Google::Cloud::Billing::V1::CloudCatalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'Sku',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::Sku'];

coerce 'Sku',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::Sku'->new($_) };

declare 'RepeatedSku',
    as ArrayRef[Sku()];

coerce 'RepeatedSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::Sku'->new($_) } @$_ ] };

declare 'MapStringSku',
    as HashRef[Sku()];

declare 'Category',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::Category'];

coerce 'Category',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::Category'->new($_) };

declare 'RepeatedCategory',
    as ArrayRef[Category()];

coerce 'RepeatedCategory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::Category'->new($_) } @$_ ] };

declare 'MapStringCategory',
    as HashRef[Category()];

declare 'PricingInfo',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::PricingInfo'];

coerce 'PricingInfo',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::PricingInfo'->new($_) };

declare 'RepeatedPricingInfo',
    as ArrayRef[PricingInfo()];

coerce 'RepeatedPricingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::PricingInfo'->new($_) } @$_ ] };

declare 'MapStringPricingInfo',
    as HashRef[PricingInfo()];

declare 'PricingExpression',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::PricingExpression'];

coerce 'PricingExpression',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::PricingExpression'->new($_) };

declare 'RepeatedPricingExpression',
    as ArrayRef[PricingExpression()];

coerce 'RepeatedPricingExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::PricingExpression'->new($_) } @$_ ] };

declare 'MapStringPricingExpression',
    as HashRef[PricingExpression()];

declare 'TierRate',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::PricingExpression::TierRate'];

coerce 'TierRate',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::PricingExpression::TierRate'->new($_) };

declare 'RepeatedTierRate',
    as ArrayRef[TierRate()];

coerce 'RepeatedTierRate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::PricingExpression::TierRate'->new($_) } @$_ ] };

declare 'MapStringTierRate',
    as HashRef[TierRate()];

declare 'AggregationInfo',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::AggregationInfo'];

coerce 'AggregationInfo',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::AggregationInfo'->new($_) };

declare 'RepeatedAggregationInfo',
    as ArrayRef[AggregationInfo()];

coerce 'RepeatedAggregationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::AggregationInfo'->new($_) } @$_ ] };

declare 'MapStringAggregationInfo',
    as HashRef[AggregationInfo()];

declare 'AggregationLevel',
    as (Int | Str);

declare 'AggregationInterval',
    as (Int | Str);

declare 'GeoTaxonomy',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::GeoTaxonomy'];

coerce 'GeoTaxonomy',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::GeoTaxonomy'->new($_) };

declare 'RepeatedGeoTaxonomy',
    as ArrayRef[GeoTaxonomy()];

coerce 'RepeatedGeoTaxonomy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::GeoTaxonomy'->new($_) } @$_ ] };

declare 'MapStringGeoTaxonomy',
    as HashRef[GeoTaxonomy()];

declare 'Type',
    as (Int | Str);

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'ListSkusRequest',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest'];

coerce 'ListSkusRequest',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest'->new($_) };

declare 'RepeatedListSkusRequest',
    as ArrayRef[ListSkusRequest()];

coerce 'RepeatedListSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListSkusRequest',
    as HashRef[ListSkusRequest()];

declare 'ListSkusResponse',
    as InstanceOf['Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse'];

coerce 'ListSkusResponse',
    from HashRef, via { 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse'->new($_) };

declare 'RepeatedListSkusResponse',
    as ArrayRef[ListSkusResponse()];

coerce 'RepeatedListSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListSkusResponse',
    as HashRef[ListSkusResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Billing::V1::CloudCatalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
