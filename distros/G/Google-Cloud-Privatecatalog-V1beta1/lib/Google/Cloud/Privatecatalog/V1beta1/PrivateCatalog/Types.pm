package Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SearchCatalogsRequest',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsRequest'];

coerce 'SearchCatalogsRequest',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsRequest'->new($_) };

declare 'RepeatedSearchCatalogsRequest',
    as ArrayRef[SearchCatalogsRequest()];

coerce 'RepeatedSearchCatalogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogsRequest',
    as HashRef[SearchCatalogsRequest()];

declare 'SearchCatalogsResponse',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsResponse'];

coerce 'SearchCatalogsResponse',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsResponse'->new($_) };

declare 'RepeatedSearchCatalogsResponse',
    as ArrayRef[SearchCatalogsResponse()];

coerce 'RepeatedSearchCatalogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchCatalogsResponse',
    as HashRef[SearchCatalogsResponse()];

declare 'SearchProductsRequest',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsRequest'];

coerce 'SearchProductsRequest',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsRequest'->new($_) };

declare 'RepeatedSearchProductsRequest',
    as ArrayRef[SearchProductsRequest()];

coerce 'RepeatedSearchProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchProductsRequest',
    as HashRef[SearchProductsRequest()];

declare 'SearchProductsResponse',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsResponse'];

coerce 'SearchProductsResponse',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsResponse'->new($_) };

declare 'RepeatedSearchProductsResponse',
    as ArrayRef[SearchProductsResponse()];

coerce 'RepeatedSearchProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchProductsResponse',
    as HashRef[SearchProductsResponse()];

declare 'SearchVersionsRequest',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsRequest'];

coerce 'SearchVersionsRequest',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsRequest'->new($_) };

declare 'RepeatedSearchVersionsRequest',
    as ArrayRef[SearchVersionsRequest()];

coerce 'RepeatedSearchVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchVersionsRequest',
    as HashRef[SearchVersionsRequest()];

declare 'SearchVersionsResponse',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsResponse'];

coerce 'SearchVersionsResponse',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsResponse'->new($_) };

declare 'RepeatedSearchVersionsResponse',
    as ArrayRef[SearchVersionsResponse()];

coerce 'RepeatedSearchVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchVersionsResponse',
    as HashRef[SearchVersionsResponse()];

declare 'Catalog',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Catalog'];

coerce 'Catalog',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Catalog'->new($_) };

declare 'RepeatedCatalog',
    as ArrayRef[Catalog()];

coerce 'RepeatedCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Catalog'->new($_) } @$_ ] };

declare 'MapStringCatalog',
    as HashRef[Catalog()];

declare 'Product',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Product'];

coerce 'Product',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

declare 'AssetReference',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::AssetReference'];

coerce 'AssetReference',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::AssetReference'->new($_) };

declare 'RepeatedAssetReference',
    as ArrayRef[AssetReference()];

coerce 'RepeatedAssetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::AssetReference'->new($_) } @$_ ] };

declare 'MapStringAssetReference',
    as HashRef[AssetReference()];

declare 'AssetValidationState',
    as (Int | Str);

declare 'Inputs',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Inputs'];

coerce 'Inputs',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Inputs'->new($_) };

declare 'RepeatedInputs',
    as ArrayRef[Inputs()];

coerce 'RepeatedInputs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Inputs'->new($_) } @$_ ] };

declare 'MapStringInputs',
    as HashRef[Inputs()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'GitSource',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::GitSource'];

coerce 'GitSource',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::GitSource'->new($_) };

declare 'RepeatedGitSource',
    as ArrayRef[GitSource()];

coerce 'RepeatedGitSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::GitSource'->new($_) } @$_ ] };

declare 'MapStringGitSource',
    as HashRef[GitSource()];

declare 'Version',
    as InstanceOf['Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

1;

__END__

=head1 NAME

Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
