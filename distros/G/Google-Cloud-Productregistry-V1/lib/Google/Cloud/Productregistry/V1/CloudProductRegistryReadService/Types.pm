package Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetProductSuiteRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest'];

coerce 'GetProductSuiteRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest'->new($_) };

declare 'RepeatedGetProductSuiteRequest',
    as ArrayRef[GetProductSuiteRequest()];

coerce 'RepeatedGetProductSuiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetProductSuiteRequest'->new($_) } @$_ ] };

declare 'MapStringGetProductSuiteRequest',
    as HashRef[GetProductSuiteRequest()];

declare 'GetLogicalProductRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductRequest'];

coerce 'GetLogicalProductRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductRequest'->new($_) };

declare 'RepeatedGetLogicalProductRequest',
    as ArrayRef[GetLogicalProductRequest()];

coerce 'RepeatedGetLogicalProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductRequest'->new($_) } @$_ ] };

declare 'MapStringGetLogicalProductRequest',
    as HashRef[GetLogicalProductRequest()];

declare 'GetLogicalProductVariantRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductVariantRequest'];

coerce 'GetLogicalProductVariantRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductVariantRequest'->new($_) };

declare 'RepeatedGetLogicalProductVariantRequest',
    as ArrayRef[GetLogicalProductVariantRequest()];

coerce 'RepeatedGetLogicalProductVariantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::GetLogicalProductVariantRequest'->new($_) } @$_ ] };

declare 'MapStringGetLogicalProductVariantRequest',
    as HashRef[GetLogicalProductVariantRequest()];

declare 'ListProductSuitesRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesRequest'];

coerce 'ListProductSuitesRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesRequest'->new($_) };

declare 'RepeatedListProductSuitesRequest',
    as ArrayRef[ListProductSuitesRequest()];

coerce 'RepeatedListProductSuitesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesRequest'->new($_) } @$_ ] };

declare 'MapStringListProductSuitesRequest',
    as HashRef[ListProductSuitesRequest()];

declare 'ListProductSuitesResponse',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesResponse'];

coerce 'ListProductSuitesResponse',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesResponse'->new($_) };

declare 'RepeatedListProductSuitesResponse',
    as ArrayRef[ListProductSuitesResponse()];

coerce 'RepeatedListProductSuitesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListProductSuitesResponse'->new($_) } @$_ ] };

declare 'MapStringListProductSuitesResponse',
    as HashRef[ListProductSuitesResponse()];

declare 'ListLogicalProductsRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsRequest'];

coerce 'ListLogicalProductsRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsRequest'->new($_) };

declare 'RepeatedListLogicalProductsRequest',
    as ArrayRef[ListLogicalProductsRequest()];

coerce 'RepeatedListLogicalProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsRequest'->new($_) } @$_ ] };

declare 'MapStringListLogicalProductsRequest',
    as HashRef[ListLogicalProductsRequest()];

declare 'ListLogicalProductsResponse',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsResponse'];

coerce 'ListLogicalProductsResponse',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsResponse'->new($_) };

declare 'RepeatedListLogicalProductsResponse',
    as ArrayRef[ListLogicalProductsResponse()];

coerce 'RepeatedListLogicalProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductsResponse'->new($_) } @$_ ] };

declare 'MapStringListLogicalProductsResponse',
    as HashRef[ListLogicalProductsResponse()];

declare 'ListLogicalProductVariantsRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsRequest'];

coerce 'ListLogicalProductVariantsRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsRequest'->new($_) };

declare 'RepeatedListLogicalProductVariantsRequest',
    as ArrayRef[ListLogicalProductVariantsRequest()];

coerce 'RepeatedListLogicalProductVariantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsRequest'->new($_) } @$_ ] };

declare 'MapStringListLogicalProductVariantsRequest',
    as HashRef[ListLogicalProductVariantsRequest()];

declare 'ListLogicalProductVariantsResponse',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsResponse'];

coerce 'ListLogicalProductVariantsResponse',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsResponse'->new($_) };

declare 'RepeatedListLogicalProductVariantsResponse',
    as ArrayRef[ListLogicalProductVariantsResponse()];

coerce 'RepeatedListLogicalProductVariantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::ListLogicalProductVariantsResponse'->new($_) } @$_ ] };

declare 'MapStringListLogicalProductVariantsResponse',
    as HashRef[ListLogicalProductVariantsResponse()];

declare 'LookupEntityRequest',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityRequest'];

coerce 'LookupEntityRequest',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityRequest'->new($_) };

declare 'RepeatedLookupEntityRequest',
    as ArrayRef[LookupEntityRequest()];

coerce 'RepeatedLookupEntityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEntityRequest',
    as HashRef[LookupEntityRequest()];

declare 'LookupEntityResponse',
    as InstanceOf['Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityResponse'];

coerce 'LookupEntityResponse',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityResponse'->new($_) };

declare 'RepeatedLookupEntityResponse',
    as ArrayRef[LookupEntityResponse()];

coerce 'RepeatedLookupEntityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::LookupEntityResponse'->new($_) } @$_ ] };

declare 'MapStringLookupEntityResponse',
    as HashRef[LookupEntityResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Productregistry::V1::CloudProductRegistryReadService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
