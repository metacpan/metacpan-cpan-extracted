package Google::Cloud::Vision::V1::ProductSearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Product',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::Product'];

coerce 'Product',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

declare 'KeyValue',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::Product::KeyValue'];

coerce 'KeyValue',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::Product::KeyValue'->new($_) };

declare 'RepeatedKeyValue',
    as ArrayRef[KeyValue()];

coerce 'RepeatedKeyValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::Product::KeyValue'->new($_) } @$_ ] };

declare 'MapStringKeyValue',
    as HashRef[KeyValue()];

declare 'ProductSet',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ProductSet'];

coerce 'ProductSet',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ProductSet'->new($_) };

declare 'RepeatedProductSet',
    as ArrayRef[ProductSet()];

coerce 'RepeatedProductSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ProductSet'->new($_) } @$_ ] };

declare 'MapStringProductSet',
    as HashRef[ProductSet()];

declare 'ReferenceImage',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ReferenceImage'];

coerce 'ReferenceImage',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ReferenceImage'->new($_) };

declare 'RepeatedReferenceImage',
    as ArrayRef[ReferenceImage()];

coerce 'RepeatedReferenceImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ReferenceImage'->new($_) } @$_ ] };

declare 'MapStringReferenceImage',
    as HashRef[ReferenceImage()];

declare 'CreateProductRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::CreateProductRequest'];

coerce 'CreateProductRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::CreateProductRequest'->new($_) };

declare 'RepeatedCreateProductRequest',
    as ArrayRef[CreateProductRequest()];

coerce 'RepeatedCreateProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::CreateProductRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProductRequest',
    as HashRef[CreateProductRequest()];

declare 'ListProductsRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListProductsRequest'];

coerce 'ListProductsRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsRequest'->new($_) };

declare 'RepeatedListProductsRequest',
    as ArrayRef[ListProductsRequest()];

coerce 'RepeatedListProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsRequest'->new($_) } @$_ ] };

declare 'MapStringListProductsRequest',
    as HashRef[ListProductsRequest()];

declare 'ListProductsResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListProductsResponse'];

coerce 'ListProductsResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsResponse'->new($_) };

declare 'RepeatedListProductsResponse',
    as ArrayRef[ListProductsResponse()];

coerce 'RepeatedListProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsResponse'->new($_) } @$_ ] };

declare 'MapStringListProductsResponse',
    as HashRef[ListProductsResponse()];

declare 'GetProductRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::GetProductRequest'];

coerce 'GetProductRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::GetProductRequest'->new($_) };

declare 'RepeatedGetProductRequest',
    as ArrayRef[GetProductRequest()];

coerce 'RepeatedGetProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::GetProductRequest'->new($_) } @$_ ] };

declare 'MapStringGetProductRequest',
    as HashRef[GetProductRequest()];

declare 'UpdateProductRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::UpdateProductRequest'];

coerce 'UpdateProductRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::UpdateProductRequest'->new($_) };

declare 'RepeatedUpdateProductRequest',
    as ArrayRef[UpdateProductRequest()];

coerce 'RepeatedUpdateProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::UpdateProductRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProductRequest',
    as HashRef[UpdateProductRequest()];

declare 'DeleteProductRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::DeleteProductRequest'];

coerce 'DeleteProductRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::DeleteProductRequest'->new($_) };

declare 'RepeatedDeleteProductRequest',
    as ArrayRef[DeleteProductRequest()];

coerce 'RepeatedDeleteProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::DeleteProductRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProductRequest',
    as HashRef[DeleteProductRequest()];

declare 'CreateProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::CreateProductSetRequest'];

coerce 'CreateProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::CreateProductSetRequest'->new($_) };

declare 'RepeatedCreateProductSetRequest',
    as ArrayRef[CreateProductSetRequest()];

coerce 'RepeatedCreateProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::CreateProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProductSetRequest',
    as HashRef[CreateProductSetRequest()];

declare 'ListProductSetsRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListProductSetsRequest'];

coerce 'ListProductSetsRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductSetsRequest'->new($_) };

declare 'RepeatedListProductSetsRequest',
    as ArrayRef[ListProductSetsRequest()];

coerce 'RepeatedListProductSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListProductSetsRequest',
    as HashRef[ListProductSetsRequest()];

declare 'ListProductSetsResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListProductSetsResponse'];

coerce 'ListProductSetsResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductSetsResponse'->new($_) };

declare 'RepeatedListProductSetsResponse',
    as ArrayRef[ListProductSetsResponse()];

coerce 'RepeatedListProductSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListProductSetsResponse',
    as HashRef[ListProductSetsResponse()];

declare 'GetProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::GetProductSetRequest'];

coerce 'GetProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::GetProductSetRequest'->new($_) };

declare 'RepeatedGetProductSetRequest',
    as ArrayRef[GetProductSetRequest()];

coerce 'RepeatedGetProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::GetProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetProductSetRequest',
    as HashRef[GetProductSetRequest()];

declare 'UpdateProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::UpdateProductSetRequest'];

coerce 'UpdateProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::UpdateProductSetRequest'->new($_) };

declare 'RepeatedUpdateProductSetRequest',
    as ArrayRef[UpdateProductSetRequest()];

coerce 'RepeatedUpdateProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::UpdateProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProductSetRequest',
    as HashRef[UpdateProductSetRequest()];

declare 'DeleteProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::DeleteProductSetRequest'];

coerce 'DeleteProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::DeleteProductSetRequest'->new($_) };

declare 'RepeatedDeleteProductSetRequest',
    as ArrayRef[DeleteProductSetRequest()];

coerce 'RepeatedDeleteProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::DeleteProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProductSetRequest',
    as HashRef[DeleteProductSetRequest()];

declare 'CreateReferenceImageRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::CreateReferenceImageRequest'];

coerce 'CreateReferenceImageRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::CreateReferenceImageRequest'->new($_) };

declare 'RepeatedCreateReferenceImageRequest',
    as ArrayRef[CreateReferenceImageRequest()];

coerce 'RepeatedCreateReferenceImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::CreateReferenceImageRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReferenceImageRequest',
    as HashRef[CreateReferenceImageRequest()];

declare 'ListReferenceImagesRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListReferenceImagesRequest'];

coerce 'ListReferenceImagesRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListReferenceImagesRequest'->new($_) };

declare 'RepeatedListReferenceImagesRequest',
    as ArrayRef[ListReferenceImagesRequest()];

coerce 'RepeatedListReferenceImagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListReferenceImagesRequest'->new($_) } @$_ ] };

declare 'MapStringListReferenceImagesRequest',
    as HashRef[ListReferenceImagesRequest()];

declare 'ListReferenceImagesResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListReferenceImagesResponse'];

coerce 'ListReferenceImagesResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListReferenceImagesResponse'->new($_) };

declare 'RepeatedListReferenceImagesResponse',
    as ArrayRef[ListReferenceImagesResponse()];

coerce 'RepeatedListReferenceImagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListReferenceImagesResponse'->new($_) } @$_ ] };

declare 'MapStringListReferenceImagesResponse',
    as HashRef[ListReferenceImagesResponse()];

declare 'GetReferenceImageRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::GetReferenceImageRequest'];

coerce 'GetReferenceImageRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::GetReferenceImageRequest'->new($_) };

declare 'RepeatedGetReferenceImageRequest',
    as ArrayRef[GetReferenceImageRequest()];

coerce 'RepeatedGetReferenceImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::GetReferenceImageRequest'->new($_) } @$_ ] };

declare 'MapStringGetReferenceImageRequest',
    as HashRef[GetReferenceImageRequest()];

declare 'DeleteReferenceImageRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::DeleteReferenceImageRequest'];

coerce 'DeleteReferenceImageRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::DeleteReferenceImageRequest'->new($_) };

declare 'RepeatedDeleteReferenceImageRequest',
    as ArrayRef[DeleteReferenceImageRequest()];

coerce 'RepeatedDeleteReferenceImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::DeleteReferenceImageRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReferenceImageRequest',
    as HashRef[DeleteReferenceImageRequest()];

declare 'AddProductToProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::AddProductToProductSetRequest'];

coerce 'AddProductToProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::AddProductToProductSetRequest'->new($_) };

declare 'RepeatedAddProductToProductSetRequest',
    as ArrayRef[AddProductToProductSetRequest()];

coerce 'RepeatedAddProductToProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::AddProductToProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringAddProductToProductSetRequest',
    as HashRef[AddProductToProductSetRequest()];

declare 'RemoveProductFromProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::RemoveProductFromProductSetRequest'];

coerce 'RemoveProductFromProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::RemoveProductFromProductSetRequest'->new($_) };

declare 'RepeatedRemoveProductFromProductSetRequest',
    as ArrayRef[RemoveProductFromProductSetRequest()];

coerce 'RepeatedRemoveProductFromProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::RemoveProductFromProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveProductFromProductSetRequest',
    as HashRef[RemoveProductFromProductSetRequest()];

declare 'ListProductsInProductSetRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListProductsInProductSetRequest'];

coerce 'ListProductsInProductSetRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsInProductSetRequest'->new($_) };

declare 'RepeatedListProductsInProductSetRequest',
    as ArrayRef[ListProductsInProductSetRequest()];

coerce 'RepeatedListProductsInProductSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsInProductSetRequest'->new($_) } @$_ ] };

declare 'MapStringListProductsInProductSetRequest',
    as HashRef[ListProductsInProductSetRequest()];

declare 'ListProductsInProductSetResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ListProductsInProductSetResponse'];

coerce 'ListProductsInProductSetResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsInProductSetResponse'->new($_) };

declare 'RepeatedListProductsInProductSetResponse',
    as ArrayRef[ListProductsInProductSetResponse()];

coerce 'RepeatedListProductsInProductSetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ListProductsInProductSetResponse'->new($_) } @$_ ] };

declare 'MapStringListProductsInProductSetResponse',
    as HashRef[ListProductsInProductSetResponse()];

declare 'ImportProductSetsGcsSource',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsGcsSource'];

coerce 'ImportProductSetsGcsSource',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsGcsSource'->new($_) };

declare 'RepeatedImportProductSetsGcsSource',
    as ArrayRef[ImportProductSetsGcsSource()];

coerce 'RepeatedImportProductSetsGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsGcsSource'->new($_) } @$_ ] };

declare 'MapStringImportProductSetsGcsSource',
    as HashRef[ImportProductSetsGcsSource()];

declare 'ImportProductSetsInputConfig',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsInputConfig'];

coerce 'ImportProductSetsInputConfig',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsInputConfig'->new($_) };

declare 'RepeatedImportProductSetsInputConfig',
    as ArrayRef[ImportProductSetsInputConfig()];

coerce 'RepeatedImportProductSetsInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsInputConfig'->new($_) } @$_ ] };

declare 'MapStringImportProductSetsInputConfig',
    as HashRef[ImportProductSetsInputConfig()];

declare 'ImportProductSetsRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsRequest'];

coerce 'ImportProductSetsRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsRequest'->new($_) };

declare 'RepeatedImportProductSetsRequest',
    as ArrayRef[ImportProductSetsRequest()];

coerce 'RepeatedImportProductSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsRequest'->new($_) } @$_ ] };

declare 'MapStringImportProductSetsRequest',
    as HashRef[ImportProductSetsRequest()];

declare 'ImportProductSetsResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsResponse'];

coerce 'ImportProductSetsResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsResponse'->new($_) };

declare 'RepeatedImportProductSetsResponse',
    as ArrayRef[ImportProductSetsResponse()];

coerce 'RepeatedImportProductSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ImportProductSetsResponse'->new($_) } @$_ ] };

declare 'MapStringImportProductSetsResponse',
    as HashRef[ImportProductSetsResponse()];

declare 'BatchOperationMetadata',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::BatchOperationMetadata'];

coerce 'BatchOperationMetadata',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::BatchOperationMetadata'->new($_) };

declare 'RepeatedBatchOperationMetadata',
    as ArrayRef[BatchOperationMetadata()];

coerce 'RepeatedBatchOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::BatchOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchOperationMetadata',
    as HashRef[BatchOperationMetadata()];

declare 'State',
    as (Int | Str);

declare 'ProductSetPurgeConfig',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::ProductSetPurgeConfig'];

coerce 'ProductSetPurgeConfig',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::ProductSetPurgeConfig'->new($_) };

declare 'RepeatedProductSetPurgeConfig',
    as ArrayRef[ProductSetPurgeConfig()];

coerce 'RepeatedProductSetPurgeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::ProductSetPurgeConfig'->new($_) } @$_ ] };

declare 'MapStringProductSetPurgeConfig',
    as HashRef[ProductSetPurgeConfig()];

declare 'PurgeProductsRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearchService::PurgeProductsRequest'];

coerce 'PurgeProductsRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearchService::PurgeProductsRequest'->new($_) };

declare 'RepeatedPurgeProductsRequest',
    as ArrayRef[PurgeProductsRequest()];

coerce 'RepeatedPurgeProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearchService::PurgeProductsRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeProductsRequest',
    as HashRef[PurgeProductsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Vision::V1::ProductSearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
