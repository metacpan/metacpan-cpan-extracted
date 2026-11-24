package Google::Cloud::Retail::V2alpha::ProductService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateProductRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::CreateProductRequest'];

coerce 'CreateProductRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::CreateProductRequest'->new($_) };

declare 'RepeatedCreateProductRequest',
    as ArrayRef[CreateProductRequest()];

coerce 'RepeatedCreateProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::CreateProductRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProductRequest',
    as HashRef[CreateProductRequest()];

declare 'GetProductRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::GetProductRequest'];

coerce 'GetProductRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::GetProductRequest'->new($_) };

declare 'RepeatedGetProductRequest',
    as ArrayRef[GetProductRequest()];

coerce 'RepeatedGetProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::GetProductRequest'->new($_) } @$_ ] };

declare 'MapStringGetProductRequest',
    as HashRef[GetProductRequest()];

declare 'UpdateProductRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::UpdateProductRequest'];

coerce 'UpdateProductRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::UpdateProductRequest'->new($_) };

declare 'RepeatedUpdateProductRequest',
    as ArrayRef[UpdateProductRequest()];

coerce 'RepeatedUpdateProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::UpdateProductRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProductRequest',
    as HashRef[UpdateProductRequest()];

declare 'DeleteProductRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::DeleteProductRequest'];

coerce 'DeleteProductRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::DeleteProductRequest'->new($_) };

declare 'RepeatedDeleteProductRequest',
    as ArrayRef[DeleteProductRequest()];

coerce 'RepeatedDeleteProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::DeleteProductRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProductRequest',
    as HashRef[DeleteProductRequest()];

declare 'ListProductsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::ListProductsRequest'];

coerce 'ListProductsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::ListProductsRequest'->new($_) };

declare 'RepeatedListProductsRequest',
    as ArrayRef[ListProductsRequest()];

coerce 'RepeatedListProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::ListProductsRequest'->new($_) } @$_ ] };

declare 'MapStringListProductsRequest',
    as HashRef[ListProductsRequest()];

declare 'ListProductsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::ListProductsResponse'];

coerce 'ListProductsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::ListProductsResponse'->new($_) };

declare 'RepeatedListProductsResponse',
    as ArrayRef[ListProductsResponse()];

coerce 'RepeatedListProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::ListProductsResponse'->new($_) } @$_ ] };

declare 'MapStringListProductsResponse',
    as HashRef[ListProductsResponse()];

declare 'SetInventoryRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::SetInventoryRequest'];

coerce 'SetInventoryRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::SetInventoryRequest'->new($_) };

declare 'RepeatedSetInventoryRequest',
    as ArrayRef[SetInventoryRequest()];

coerce 'RepeatedSetInventoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::SetInventoryRequest'->new($_) } @$_ ] };

declare 'MapStringSetInventoryRequest',
    as HashRef[SetInventoryRequest()];

declare 'SetInventoryMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::SetInventoryMetadata'];

coerce 'SetInventoryMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::SetInventoryMetadata'->new($_) };

declare 'RepeatedSetInventoryMetadata',
    as ArrayRef[SetInventoryMetadata()];

coerce 'RepeatedSetInventoryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::SetInventoryMetadata'->new($_) } @$_ ] };

declare 'MapStringSetInventoryMetadata',
    as HashRef[SetInventoryMetadata()];

declare 'SetInventoryResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::SetInventoryResponse'];

coerce 'SetInventoryResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::SetInventoryResponse'->new($_) };

declare 'RepeatedSetInventoryResponse',
    as ArrayRef[SetInventoryResponse()];

coerce 'RepeatedSetInventoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::SetInventoryResponse'->new($_) } @$_ ] };

declare 'MapStringSetInventoryResponse',
    as HashRef[SetInventoryResponse()];

declare 'AddFulfillmentPlacesRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesRequest'];

coerce 'AddFulfillmentPlacesRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesRequest'->new($_) };

declare 'RepeatedAddFulfillmentPlacesRequest',
    as ArrayRef[AddFulfillmentPlacesRequest()];

coerce 'RepeatedAddFulfillmentPlacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesRequest'->new($_) } @$_ ] };

declare 'MapStringAddFulfillmentPlacesRequest',
    as HashRef[AddFulfillmentPlacesRequest()];

declare 'AddFulfillmentPlacesMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesMetadata'];

coerce 'AddFulfillmentPlacesMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesMetadata'->new($_) };

declare 'RepeatedAddFulfillmentPlacesMetadata',
    as ArrayRef[AddFulfillmentPlacesMetadata()];

coerce 'RepeatedAddFulfillmentPlacesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesMetadata'->new($_) } @$_ ] };

declare 'MapStringAddFulfillmentPlacesMetadata',
    as HashRef[AddFulfillmentPlacesMetadata()];

declare 'AddFulfillmentPlacesResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesResponse'];

coerce 'AddFulfillmentPlacesResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesResponse'->new($_) };

declare 'RepeatedAddFulfillmentPlacesResponse',
    as ArrayRef[AddFulfillmentPlacesResponse()];

coerce 'RepeatedAddFulfillmentPlacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::AddFulfillmentPlacesResponse'->new($_) } @$_ ] };

declare 'MapStringAddFulfillmentPlacesResponse',
    as HashRef[AddFulfillmentPlacesResponse()];

declare 'AddLocalInventoriesRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesRequest'];

coerce 'AddLocalInventoriesRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesRequest'->new($_) };

declare 'RepeatedAddLocalInventoriesRequest',
    as ArrayRef[AddLocalInventoriesRequest()];

coerce 'RepeatedAddLocalInventoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesRequest'->new($_) } @$_ ] };

declare 'MapStringAddLocalInventoriesRequest',
    as HashRef[AddLocalInventoriesRequest()];

declare 'AddLocalInventoriesMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesMetadata'];

coerce 'AddLocalInventoriesMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesMetadata'->new($_) };

declare 'RepeatedAddLocalInventoriesMetadata',
    as ArrayRef[AddLocalInventoriesMetadata()];

coerce 'RepeatedAddLocalInventoriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesMetadata'->new($_) } @$_ ] };

declare 'MapStringAddLocalInventoriesMetadata',
    as HashRef[AddLocalInventoriesMetadata()];

declare 'AddLocalInventoriesResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesResponse'];

coerce 'AddLocalInventoriesResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesResponse'->new($_) };

declare 'RepeatedAddLocalInventoriesResponse',
    as ArrayRef[AddLocalInventoriesResponse()];

coerce 'RepeatedAddLocalInventoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::AddLocalInventoriesResponse'->new($_) } @$_ ] };

declare 'MapStringAddLocalInventoriesResponse',
    as HashRef[AddLocalInventoriesResponse()];

declare 'RemoveLocalInventoriesRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesRequest'];

coerce 'RemoveLocalInventoriesRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesRequest'->new($_) };

declare 'RepeatedRemoveLocalInventoriesRequest',
    as ArrayRef[RemoveLocalInventoriesRequest()];

coerce 'RepeatedRemoveLocalInventoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveLocalInventoriesRequest',
    as HashRef[RemoveLocalInventoriesRequest()];

declare 'RemoveLocalInventoriesMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesMetadata'];

coerce 'RemoveLocalInventoriesMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesMetadata'->new($_) };

declare 'RepeatedRemoveLocalInventoriesMetadata',
    as ArrayRef[RemoveLocalInventoriesMetadata()];

coerce 'RepeatedRemoveLocalInventoriesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesMetadata'->new($_) } @$_ ] };

declare 'MapStringRemoveLocalInventoriesMetadata',
    as HashRef[RemoveLocalInventoriesMetadata()];

declare 'RemoveLocalInventoriesResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesResponse'];

coerce 'RemoveLocalInventoriesResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesResponse'->new($_) };

declare 'RepeatedRemoveLocalInventoriesResponse',
    as ArrayRef[RemoveLocalInventoriesResponse()];

coerce 'RepeatedRemoveLocalInventoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveLocalInventoriesResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveLocalInventoriesResponse',
    as HashRef[RemoveLocalInventoriesResponse()];

declare 'RemoveFulfillmentPlacesRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesRequest'];

coerce 'RemoveFulfillmentPlacesRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesRequest'->new($_) };

declare 'RepeatedRemoveFulfillmentPlacesRequest',
    as ArrayRef[RemoveFulfillmentPlacesRequest()];

coerce 'RepeatedRemoveFulfillmentPlacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveFulfillmentPlacesRequest',
    as HashRef[RemoveFulfillmentPlacesRequest()];

declare 'RemoveFulfillmentPlacesMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesMetadata'];

coerce 'RemoveFulfillmentPlacesMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesMetadata'->new($_) };

declare 'RepeatedRemoveFulfillmentPlacesMetadata',
    as ArrayRef[RemoveFulfillmentPlacesMetadata()];

coerce 'RepeatedRemoveFulfillmentPlacesMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesMetadata'->new($_) } @$_ ] };

declare 'MapStringRemoveFulfillmentPlacesMetadata',
    as HashRef[RemoveFulfillmentPlacesMetadata()];

declare 'RemoveFulfillmentPlacesResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesResponse'];

coerce 'RemoveFulfillmentPlacesResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesResponse'->new($_) };

declare 'RepeatedRemoveFulfillmentPlacesResponse',
    as ArrayRef[RemoveFulfillmentPlacesResponse()];

coerce 'RepeatedRemoveFulfillmentPlacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProductService::RemoveFulfillmentPlacesResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveFulfillmentPlacesResponse',
    as HashRef[RemoveFulfillmentPlacesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ProductService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
