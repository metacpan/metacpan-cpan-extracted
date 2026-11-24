package Google::Cloud::Retail::V2alpha::CatalogService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCatalogsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsRequest'];

coerce 'ListCatalogsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsRequest'->new($_) };

declare 'RepeatedListCatalogsRequest',
    as ArrayRef[ListCatalogsRequest()];

coerce 'RepeatedListCatalogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsRequest'->new($_) } @$_ ] };

declare 'MapStringListCatalogsRequest',
    as HashRef[ListCatalogsRequest()];

declare 'ListCatalogsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsResponse'];

coerce 'ListCatalogsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsResponse'->new($_) };

declare 'RepeatedListCatalogsResponse',
    as ArrayRef[ListCatalogsResponse()];

coerce 'RepeatedListCatalogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::ListCatalogsResponse'->new($_) } @$_ ] };

declare 'MapStringListCatalogsResponse',
    as HashRef[ListCatalogsResponse()];

declare 'UpdateCatalogRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::UpdateCatalogRequest'];

coerce 'UpdateCatalogRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateCatalogRequest'->new($_) };

declare 'RepeatedUpdateCatalogRequest',
    as ArrayRef[UpdateCatalogRequest()];

coerce 'RepeatedUpdateCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCatalogRequest',
    as HashRef[UpdateCatalogRequest()];

declare 'SetDefaultBranchRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::SetDefaultBranchRequest'];

coerce 'SetDefaultBranchRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::SetDefaultBranchRequest'->new($_) };

declare 'RepeatedSetDefaultBranchRequest',
    as ArrayRef[SetDefaultBranchRequest()];

coerce 'RepeatedSetDefaultBranchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::SetDefaultBranchRequest'->new($_) } @$_ ] };

declare 'MapStringSetDefaultBranchRequest',
    as HashRef[SetDefaultBranchRequest()];

declare 'GetDefaultBranchRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::GetDefaultBranchRequest'];

coerce 'GetDefaultBranchRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::GetDefaultBranchRequest'->new($_) };

declare 'RepeatedGetDefaultBranchRequest',
    as ArrayRef[GetDefaultBranchRequest()];

coerce 'RepeatedGetDefaultBranchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::GetDefaultBranchRequest'->new($_) } @$_ ] };

declare 'MapStringGetDefaultBranchRequest',
    as HashRef[GetDefaultBranchRequest()];

declare 'GetDefaultBranchResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::GetDefaultBranchResponse'];

coerce 'GetDefaultBranchResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::GetDefaultBranchResponse'->new($_) };

declare 'RepeatedGetDefaultBranchResponse',
    as ArrayRef[GetDefaultBranchResponse()];

coerce 'RepeatedGetDefaultBranchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::GetDefaultBranchResponse'->new($_) } @$_ ] };

declare 'MapStringGetDefaultBranchResponse',
    as HashRef[GetDefaultBranchResponse()];

declare 'GetCompletionConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::GetCompletionConfigRequest'];

coerce 'GetCompletionConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::GetCompletionConfigRequest'->new($_) };

declare 'RepeatedGetCompletionConfigRequest',
    as ArrayRef[GetCompletionConfigRequest()];

coerce 'RepeatedGetCompletionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::GetCompletionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetCompletionConfigRequest',
    as HashRef[GetCompletionConfigRequest()];

declare 'UpdateCompletionConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::UpdateCompletionConfigRequest'];

coerce 'UpdateCompletionConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateCompletionConfigRequest'->new($_) };

declare 'RepeatedUpdateCompletionConfigRequest',
    as ArrayRef[UpdateCompletionConfigRequest()];

coerce 'RepeatedUpdateCompletionConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateCompletionConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCompletionConfigRequest',
    as HashRef[UpdateCompletionConfigRequest()];

declare 'GetAttributesConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::GetAttributesConfigRequest'];

coerce 'GetAttributesConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::GetAttributesConfigRequest'->new($_) };

declare 'RepeatedGetAttributesConfigRequest',
    as ArrayRef[GetAttributesConfigRequest()];

coerce 'RepeatedGetAttributesConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::GetAttributesConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttributesConfigRequest',
    as HashRef[GetAttributesConfigRequest()];

declare 'UpdateAttributesConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::UpdateAttributesConfigRequest'];

coerce 'UpdateAttributesConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateAttributesConfigRequest'->new($_) };

declare 'RepeatedUpdateAttributesConfigRequest',
    as ArrayRef[UpdateAttributesConfigRequest()];

coerce 'RepeatedUpdateAttributesConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::UpdateAttributesConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAttributesConfigRequest',
    as HashRef[UpdateAttributesConfigRequest()];

declare 'AddCatalogAttributeRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::AddCatalogAttributeRequest'];

coerce 'AddCatalogAttributeRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::AddCatalogAttributeRequest'->new($_) };

declare 'RepeatedAddCatalogAttributeRequest',
    as ArrayRef[AddCatalogAttributeRequest()];

coerce 'RepeatedAddCatalogAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::AddCatalogAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringAddCatalogAttributeRequest',
    as HashRef[AddCatalogAttributeRequest()];

declare 'RemoveCatalogAttributeRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::RemoveCatalogAttributeRequest'];

coerce 'RemoveCatalogAttributeRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::RemoveCatalogAttributeRequest'->new($_) };

declare 'RepeatedRemoveCatalogAttributeRequest',
    as ArrayRef[RemoveCatalogAttributeRequest()];

coerce 'RepeatedRemoveCatalogAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::RemoveCatalogAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveCatalogAttributeRequest',
    as HashRef[RemoveCatalogAttributeRequest()];

declare 'BatchRemoveCatalogAttributesRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::BatchRemoveCatalogAttributesRequest'];

coerce 'BatchRemoveCatalogAttributesRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::BatchRemoveCatalogAttributesRequest'->new($_) };

declare 'RepeatedBatchRemoveCatalogAttributesRequest',
    as ArrayRef[BatchRemoveCatalogAttributesRequest()];

coerce 'RepeatedBatchRemoveCatalogAttributesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::BatchRemoveCatalogAttributesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchRemoveCatalogAttributesRequest',
    as HashRef[BatchRemoveCatalogAttributesRequest()];

declare 'BatchRemoveCatalogAttributesResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::BatchRemoveCatalogAttributesResponse'];

coerce 'BatchRemoveCatalogAttributesResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::BatchRemoveCatalogAttributesResponse'->new($_) };

declare 'RepeatedBatchRemoveCatalogAttributesResponse',
    as ArrayRef[BatchRemoveCatalogAttributesResponse()];

coerce 'RepeatedBatchRemoveCatalogAttributesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::BatchRemoveCatalogAttributesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchRemoveCatalogAttributesResponse',
    as HashRef[BatchRemoveCatalogAttributesResponse()];

declare 'ReplaceCatalogAttributeRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::CatalogService::ReplaceCatalogAttributeRequest'];

coerce 'ReplaceCatalogAttributeRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::CatalogService::ReplaceCatalogAttributeRequest'->new($_) };

declare 'RepeatedReplaceCatalogAttributeRequest',
    as ArrayRef[ReplaceCatalogAttributeRequest()];

coerce 'RepeatedReplaceCatalogAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::CatalogService::ReplaceCatalogAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringReplaceCatalogAttributeRequest',
    as HashRef[ReplaceCatalogAttributeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::CatalogService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
