package Google::Cloud::Observability::V1::Observability::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CmekSettings',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::CmekSettings'];

coerce 'CmekSettings',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::CmekSettings'->new($_) };

declare 'RepeatedCmekSettings',
    as ArrayRef[CmekSettings()];

coerce 'RepeatedCmekSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::CmekSettings'->new($_) } @$_ ] };

declare 'MapStringCmekSettings',
    as HashRef[CmekSettings()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'Bucket',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'CreateBucketRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::CreateBucketRequest'];

coerce 'CreateBucketRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::CreateBucketRequest'->new($_) };

declare 'RepeatedCreateBucketRequest',
    as ArrayRef[CreateBucketRequest()];

coerce 'RepeatedCreateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::CreateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBucketRequest',
    as HashRef[CreateBucketRequest()];

declare 'UpdateBucketRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::UpdateBucketRequest'];

coerce 'UpdateBucketRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::UpdateBucketRequest'->new($_) };

declare 'RepeatedUpdateBucketRequest',
    as ArrayRef[UpdateBucketRequest()];

coerce 'RepeatedUpdateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::UpdateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBucketRequest',
    as HashRef[UpdateBucketRequest()];

declare 'GetBucketRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetBucketRequest'];

coerce 'GetBucketRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetBucketRequest'->new($_) };

declare 'RepeatedGetBucketRequest',
    as ArrayRef[GetBucketRequest()];

coerce 'RepeatedGetBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetBucketRequest'->new($_) } @$_ ] };

declare 'MapStringGetBucketRequest',
    as HashRef[GetBucketRequest()];

declare 'ListBucketsRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListBucketsRequest'];

coerce 'ListBucketsRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListBucketsRequest'->new($_) };

declare 'RepeatedListBucketsRequest',
    as ArrayRef[ListBucketsRequest()];

coerce 'RepeatedListBucketsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListBucketsRequest'->new($_) } @$_ ] };

declare 'MapStringListBucketsRequest',
    as HashRef[ListBucketsRequest()];

declare 'ListBucketsResponse',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListBucketsResponse'];

coerce 'ListBucketsResponse',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListBucketsResponse'->new($_) };

declare 'RepeatedListBucketsResponse',
    as ArrayRef[ListBucketsResponse()];

coerce 'RepeatedListBucketsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListBucketsResponse'->new($_) } @$_ ] };

declare 'MapStringListBucketsResponse',
    as HashRef[ListBucketsResponse()];

declare 'Dataset',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListDatasetsResponse',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListDatasetsResponse'];

coerce 'ListDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListDatasetsResponse'->new($_) };

declare 'RepeatedListDatasetsResponse',
    as ArrayRef[ListDatasetsResponse()];

coerce 'RepeatedListDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetsResponse',
    as HashRef[ListDatasetsResponse()];

declare 'View',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::View'];

coerce 'View',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::View'->new($_) };

declare 'RepeatedView',
    as ArrayRef[View()];

coerce 'RepeatedView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::View'->new($_) } @$_ ] };

declare 'MapStringView',
    as HashRef[View()];

declare 'GetViewRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetViewRequest'];

coerce 'GetViewRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetViewRequest'->new($_) };

declare 'RepeatedGetViewRequest',
    as ArrayRef[GetViewRequest()];

coerce 'RepeatedGetViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetViewRequest',
    as HashRef[GetViewRequest()];

declare 'ListViewsRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListViewsRequest'];

coerce 'ListViewsRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListViewsRequest'->new($_) };

declare 'RepeatedListViewsRequest',
    as ArrayRef[ListViewsRequest()];

coerce 'RepeatedListViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListViewsRequest',
    as HashRef[ListViewsRequest()];

declare 'ListViewsResponse',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListViewsResponse'];

coerce 'ListViewsResponse',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListViewsResponse'->new($_) };

declare 'RepeatedListViewsResponse',
    as ArrayRef[ListViewsResponse()];

coerce 'RepeatedListViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListViewsResponse',
    as HashRef[ListViewsResponse()];

declare 'Link',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'CreateLinkRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::CreateLinkRequest'];

coerce 'CreateLinkRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::CreateLinkRequest'->new($_) };

declare 'RepeatedCreateLinkRequest',
    as ArrayRef[CreateLinkRequest()];

coerce 'RepeatedCreateLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::CreateLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLinkRequest',
    as HashRef[CreateLinkRequest()];

declare 'UpdateLinkRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::UpdateLinkRequest'];

coerce 'UpdateLinkRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::UpdateLinkRequest'->new($_) };

declare 'RepeatedUpdateLinkRequest',
    as ArrayRef[UpdateLinkRequest()];

coerce 'RepeatedUpdateLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::UpdateLinkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLinkRequest',
    as HashRef[UpdateLinkRequest()];

declare 'GetLinkRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetLinkRequest'];

coerce 'GetLinkRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetLinkRequest'->new($_) };

declare 'RepeatedGetLinkRequest',
    as ArrayRef[GetLinkRequest()];

coerce 'RepeatedGetLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetLinkRequest'->new($_) } @$_ ] };

declare 'MapStringGetLinkRequest',
    as HashRef[GetLinkRequest()];

declare 'ListLinksRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListLinksRequest'];

coerce 'ListLinksRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListLinksRequest'->new($_) };

declare 'RepeatedListLinksRequest',
    as ArrayRef[ListLinksRequest()];

coerce 'RepeatedListLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListLinksRequest'->new($_) } @$_ ] };

declare 'MapStringListLinksRequest',
    as HashRef[ListLinksRequest()];

declare 'ListLinksResponse',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListLinksResponse'];

coerce 'ListLinksResponse',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListLinksResponse'->new($_) };

declare 'RepeatedListLinksResponse',
    as ArrayRef[ListLinksResponse()];

coerce 'RepeatedListLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListLinksResponse'->new($_) } @$_ ] };

declare 'MapStringListLinksResponse',
    as HashRef[ListLinksResponse()];

declare 'DeleteLinkRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::DeleteLinkRequest'];

coerce 'DeleteLinkRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::DeleteLinkRequest'->new($_) };

declare 'RepeatedDeleteLinkRequest',
    as ArrayRef[DeleteLinkRequest()];

coerce 'RepeatedDeleteLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::DeleteLinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLinkRequest',
    as HashRef[DeleteLinkRequest()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'GetScopeRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetScopeRequest'];

coerce 'GetScopeRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetScopeRequest'->new($_) };

declare 'RepeatedGetScopeRequest',
    as ArrayRef[GetScopeRequest()];

coerce 'RepeatedGetScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetScopeRequest'->new($_) } @$_ ] };

declare 'MapStringGetScopeRequest',
    as HashRef[GetScopeRequest()];

declare 'UpdateScopeRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::UpdateScopeRequest'];

coerce 'UpdateScopeRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::UpdateScopeRequest'->new($_) };

declare 'RepeatedUpdateScopeRequest',
    as ArrayRef[UpdateScopeRequest()];

coerce 'RepeatedUpdateScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::UpdateScopeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateScopeRequest',
    as HashRef[UpdateScopeRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'TraceScope',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::TraceScope'];

coerce 'TraceScope',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::TraceScope'->new($_) };

declare 'RepeatedTraceScope',
    as ArrayRef[TraceScope()];

coerce 'RepeatedTraceScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::TraceScope'->new($_) } @$_ ] };

declare 'MapStringTraceScope',
    as HashRef[TraceScope()];

declare 'CreateTraceScopeRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::CreateTraceScopeRequest'];

coerce 'CreateTraceScopeRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::CreateTraceScopeRequest'->new($_) };

declare 'RepeatedCreateTraceScopeRequest',
    as ArrayRef[CreateTraceScopeRequest()];

coerce 'RepeatedCreateTraceScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::CreateTraceScopeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTraceScopeRequest',
    as HashRef[CreateTraceScopeRequest()];

declare 'GetTraceScopeRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetTraceScopeRequest'];

coerce 'GetTraceScopeRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetTraceScopeRequest'->new($_) };

declare 'RepeatedGetTraceScopeRequest',
    as ArrayRef[GetTraceScopeRequest()];

coerce 'RepeatedGetTraceScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetTraceScopeRequest'->new($_) } @$_ ] };

declare 'MapStringGetTraceScopeRequest',
    as HashRef[GetTraceScopeRequest()];

declare 'ListTraceScopesRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListTraceScopesRequest'];

coerce 'ListTraceScopesRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListTraceScopesRequest'->new($_) };

declare 'RepeatedListTraceScopesRequest',
    as ArrayRef[ListTraceScopesRequest()];

coerce 'RepeatedListTraceScopesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListTraceScopesRequest'->new($_) } @$_ ] };

declare 'MapStringListTraceScopesRequest',
    as HashRef[ListTraceScopesRequest()];

declare 'ListTraceScopesResponse',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::ListTraceScopesResponse'];

coerce 'ListTraceScopesResponse',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::ListTraceScopesResponse'->new($_) };

declare 'RepeatedListTraceScopesResponse',
    as ArrayRef[ListTraceScopesResponse()];

coerce 'RepeatedListTraceScopesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::ListTraceScopesResponse'->new($_) } @$_ ] };

declare 'MapStringListTraceScopesResponse',
    as HashRef[ListTraceScopesResponse()];

declare 'UpdateTraceScopeRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::UpdateTraceScopeRequest'];

coerce 'UpdateTraceScopeRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::UpdateTraceScopeRequest'->new($_) };

declare 'RepeatedUpdateTraceScopeRequest',
    as ArrayRef[UpdateTraceScopeRequest()];

coerce 'RepeatedUpdateTraceScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::UpdateTraceScopeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTraceScopeRequest',
    as HashRef[UpdateTraceScopeRequest()];

declare 'DeleteTraceScopeRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::DeleteTraceScopeRequest'];

coerce 'DeleteTraceScopeRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::DeleteTraceScopeRequest'->new($_) };

declare 'RepeatedDeleteTraceScopeRequest',
    as ArrayRef[DeleteTraceScopeRequest()];

coerce 'RepeatedDeleteTraceScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::DeleteTraceScopeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTraceScopeRequest',
    as HashRef[DeleteTraceScopeRequest()];

declare 'GetSettingsRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::GetSettingsRequest'];

coerce 'GetSettingsRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::GetSettingsRequest'->new($_) };

declare 'RepeatedGetSettingsRequest',
    as ArrayRef[GetSettingsRequest()];

coerce 'RepeatedGetSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::GetSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSettingsRequest',
    as HashRef[GetSettingsRequest()];

declare 'UpdateSettingsRequest',
    as InstanceOf['Google::Cloud::Observability::V1::Observability::UpdateSettingsRequest'];

coerce 'UpdateSettingsRequest',
    from HashRef, via { 'Google::Cloud::Observability::V1::Observability::UpdateSettingsRequest'->new($_) };

declare 'RepeatedUpdateSettingsRequest',
    as ArrayRef[UpdateSettingsRequest()];

coerce 'RepeatedUpdateSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Observability::V1::Observability::UpdateSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSettingsRequest',
    as HashRef[UpdateSettingsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Observability::V1::Observability::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
