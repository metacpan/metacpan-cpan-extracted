package Google::Devtools::Resultstore::V2::ResultstoreDownload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetInvocationRequest'];

coerce 'GetInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetInvocationRequest'->new($_) };

declare 'RepeatedGetInvocationRequest',
    as ArrayRef[GetInvocationRequest()];

coerce 'RepeatedGetInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringGetInvocationRequest',
    as HashRef[GetInvocationRequest()];

declare 'SearchInvocationsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchInvocationsRequest'];

coerce 'SearchInvocationsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchInvocationsRequest'->new($_) };

declare 'RepeatedSearchInvocationsRequest',
    as ArrayRef[SearchInvocationsRequest()];

coerce 'RepeatedSearchInvocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchInvocationsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchInvocationsRequest',
    as HashRef[SearchInvocationsRequest()];

declare 'SearchInvocationsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchInvocationsResponse'];

coerce 'SearchInvocationsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchInvocationsResponse'->new($_) };

declare 'RepeatedSearchInvocationsResponse',
    as ArrayRef[SearchInvocationsResponse()];

coerce 'RepeatedSearchInvocationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchInvocationsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchInvocationsResponse',
    as HashRef[SearchInvocationsResponse()];

declare 'ExportInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ExportInvocationRequest'];

coerce 'ExportInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ExportInvocationRequest'->new($_) };

declare 'RepeatedExportInvocationRequest',
    as ArrayRef[ExportInvocationRequest()];

coerce 'RepeatedExportInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ExportInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringExportInvocationRequest',
    as HashRef[ExportInvocationRequest()];

declare 'ExportInvocationResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ExportInvocationResponse'];

coerce 'ExportInvocationResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ExportInvocationResponse'->new($_) };

declare 'RepeatedExportInvocationResponse',
    as ArrayRef[ExportInvocationResponse()];

coerce 'RepeatedExportInvocationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ExportInvocationResponse'->new($_) } @$_ ] };

declare 'MapStringExportInvocationResponse',
    as HashRef[ExportInvocationResponse()];

declare 'GetInvocationDownloadMetadataRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetInvocationDownloadMetadataRequest'];

coerce 'GetInvocationDownloadMetadataRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetInvocationDownloadMetadataRequest'->new($_) };

declare 'RepeatedGetInvocationDownloadMetadataRequest',
    as ArrayRef[GetInvocationDownloadMetadataRequest()];

coerce 'RepeatedGetInvocationDownloadMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetInvocationDownloadMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringGetInvocationDownloadMetadataRequest',
    as HashRef[GetInvocationDownloadMetadataRequest()];

declare 'GetConfigurationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetConfigurationRequest'];

coerce 'GetConfigurationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetConfigurationRequest'->new($_) };

declare 'RepeatedGetConfigurationRequest',
    as ArrayRef[GetConfigurationRequest()];

coerce 'RepeatedGetConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfigurationRequest',
    as HashRef[GetConfigurationRequest()];

declare 'ListConfigurationsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfigurationsRequest'];

coerce 'ListConfigurationsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfigurationsRequest'->new($_) };

declare 'RepeatedListConfigurationsRequest',
    as ArrayRef[ListConfigurationsRequest()];

coerce 'RepeatedListConfigurationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfigurationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConfigurationsRequest',
    as HashRef[ListConfigurationsRequest()];

declare 'ListConfigurationsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfigurationsResponse'];

coerce 'ListConfigurationsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfigurationsResponse'->new($_) };

declare 'RepeatedListConfigurationsResponse',
    as ArrayRef[ListConfigurationsResponse()];

coerce 'RepeatedListConfigurationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfigurationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConfigurationsResponse',
    as HashRef[ListConfigurationsResponse()];

declare 'GetTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetTargetRequest'];

coerce 'GetTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetTargetRequest'->new($_) };

declare 'RepeatedGetTargetRequest',
    as ArrayRef[GetTargetRequest()];

coerce 'RepeatedGetTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetTargetRequest'->new($_) } @$_ ] };

declare 'MapStringGetTargetRequest',
    as HashRef[GetTargetRequest()];

declare 'ListTargetsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListTargetsRequest'];

coerce 'ListTargetsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListTargetsRequest'->new($_) };

declare 'RepeatedListTargetsRequest',
    as ArrayRef[ListTargetsRequest()];

coerce 'RepeatedListTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringListTargetsRequest',
    as HashRef[ListTargetsRequest()];

declare 'ListTargetsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListTargetsResponse'];

coerce 'ListTargetsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListTargetsResponse'->new($_) };

declare 'RepeatedListTargetsResponse',
    as ArrayRef[ListTargetsResponse()];

coerce 'RepeatedListTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringListTargetsResponse',
    as HashRef[ListTargetsResponse()];

declare 'GetConfiguredTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetConfiguredTargetRequest'];

coerce 'GetConfiguredTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetConfiguredTargetRequest'->new($_) };

declare 'RepeatedGetConfiguredTargetRequest',
    as ArrayRef[GetConfiguredTargetRequest()];

coerce 'RepeatedGetConfiguredTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetConfiguredTargetRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfiguredTargetRequest',
    as HashRef[GetConfiguredTargetRequest()];

declare 'ListConfiguredTargetsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfiguredTargetsRequest'];

coerce 'ListConfiguredTargetsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfiguredTargetsRequest'->new($_) };

declare 'RepeatedListConfiguredTargetsRequest',
    as ArrayRef[ListConfiguredTargetsRequest()];

coerce 'RepeatedListConfiguredTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfiguredTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringListConfiguredTargetsRequest',
    as HashRef[ListConfiguredTargetsRequest()];

declare 'ListConfiguredTargetsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfiguredTargetsResponse'];

coerce 'ListConfiguredTargetsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfiguredTargetsResponse'->new($_) };

declare 'RepeatedListConfiguredTargetsResponse',
    as ArrayRef[ListConfiguredTargetsResponse()];

coerce 'RepeatedListConfiguredTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListConfiguredTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringListConfiguredTargetsResponse',
    as HashRef[ListConfiguredTargetsResponse()];

declare 'SearchConfiguredTargetsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchConfiguredTargetsRequest'];

coerce 'SearchConfiguredTargetsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchConfiguredTargetsRequest'->new($_) };

declare 'RepeatedSearchConfiguredTargetsRequest',
    as ArrayRef[SearchConfiguredTargetsRequest()];

coerce 'RepeatedSearchConfiguredTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchConfiguredTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchConfiguredTargetsRequest',
    as HashRef[SearchConfiguredTargetsRequest()];

declare 'SearchConfiguredTargetsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchConfiguredTargetsResponse'];

coerce 'SearchConfiguredTargetsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchConfiguredTargetsResponse'->new($_) };

declare 'RepeatedSearchConfiguredTargetsResponse',
    as ArrayRef[SearchConfiguredTargetsResponse()];

coerce 'RepeatedSearchConfiguredTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::SearchConfiguredTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchConfiguredTargetsResponse',
    as HashRef[SearchConfiguredTargetsResponse()];

declare 'GetActionRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetActionRequest'];

coerce 'GetActionRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetActionRequest'->new($_) };

declare 'RepeatedGetActionRequest',
    as ArrayRef[GetActionRequest()];

coerce 'RepeatedGetActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetActionRequest'->new($_) } @$_ ] };

declare 'MapStringGetActionRequest',
    as HashRef[GetActionRequest()];

declare 'ListActionsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListActionsRequest'];

coerce 'ListActionsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListActionsRequest'->new($_) };

declare 'RepeatedListActionsRequest',
    as ArrayRef[ListActionsRequest()];

coerce 'RepeatedListActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListActionsRequest'->new($_) } @$_ ] };

declare 'MapStringListActionsRequest',
    as HashRef[ListActionsRequest()];

declare 'ListActionsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListActionsResponse'];

coerce 'ListActionsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListActionsResponse'->new($_) };

declare 'RepeatedListActionsResponse',
    as ArrayRef[ListActionsResponse()];

coerce 'RepeatedListActionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListActionsResponse'->new($_) } @$_ ] };

declare 'MapStringListActionsResponse',
    as HashRef[ListActionsResponse()];

declare 'BatchListActionsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::BatchListActionsRequest'];

coerce 'BatchListActionsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::BatchListActionsRequest'->new($_) };

declare 'RepeatedBatchListActionsRequest',
    as ArrayRef[BatchListActionsRequest()];

coerce 'RepeatedBatchListActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::BatchListActionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchListActionsRequest',
    as HashRef[BatchListActionsRequest()];

declare 'BatchListActionsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::BatchListActionsResponse'];

coerce 'BatchListActionsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::BatchListActionsResponse'->new($_) };

declare 'RepeatedBatchListActionsResponse',
    as ArrayRef[BatchListActionsResponse()];

coerce 'RepeatedBatchListActionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::BatchListActionsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchListActionsResponse',
    as HashRef[BatchListActionsResponse()];

declare 'GetFileSetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::GetFileSetRequest'];

coerce 'GetFileSetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetFileSetRequest'->new($_) };

declare 'RepeatedGetFileSetRequest',
    as ArrayRef[GetFileSetRequest()];

coerce 'RepeatedGetFileSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::GetFileSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileSetRequest',
    as HashRef[GetFileSetRequest()];

declare 'ListFileSetsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListFileSetsRequest'];

coerce 'ListFileSetsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListFileSetsRequest'->new($_) };

declare 'RepeatedListFileSetsRequest',
    as ArrayRef[ListFileSetsRequest()];

coerce 'RepeatedListFileSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListFileSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListFileSetsRequest',
    as HashRef[ListFileSetsRequest()];

declare 'ListFileSetsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::ListFileSetsResponse'];

coerce 'ListFileSetsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListFileSetsResponse'->new($_) };

declare 'RepeatedListFileSetsResponse',
    as ArrayRef[ListFileSetsResponse()];

coerce 'RepeatedListFileSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::ListFileSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListFileSetsResponse',
    as HashRef[ListFileSetsResponse()];

declare 'TraverseFileSetsRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::TraverseFileSetsRequest'];

coerce 'TraverseFileSetsRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::TraverseFileSetsRequest'->new($_) };

declare 'RepeatedTraverseFileSetsRequest',
    as ArrayRef[TraverseFileSetsRequest()];

coerce 'RepeatedTraverseFileSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::TraverseFileSetsRequest'->new($_) } @$_ ] };

declare 'MapStringTraverseFileSetsRequest',
    as HashRef[TraverseFileSetsRequest()];

declare 'TraverseFileSetsResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreDownload::TraverseFileSetsResponse'];

coerce 'TraverseFileSetsResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::TraverseFileSetsResponse'->new($_) };

declare 'RepeatedTraverseFileSetsResponse',
    as ArrayRef[TraverseFileSetsResponse()];

coerce 'RepeatedTraverseFileSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreDownload::TraverseFileSetsResponse'->new($_) } @$_ ] };

declare 'MapStringTraverseFileSetsResponse',
    as HashRef[TraverseFileSetsResponse()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::ResultstoreDownload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
