package Google::Cloud::Designcenter::V1::AuthoringMessages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListApplicationTemplatesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplatesRequest'];

coerce 'ListApplicationTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplatesRequest'->new($_) };

declare 'RepeatedListApplicationTemplatesRequest',
    as ArrayRef[ListApplicationTemplatesRequest()];

coerce 'RepeatedListApplicationTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListApplicationTemplatesRequest',
    as HashRef[ListApplicationTemplatesRequest()];

declare 'ListApplicationTemplatesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplatesResponse'];

coerce 'ListApplicationTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplatesResponse'->new($_) };

declare 'RepeatedListApplicationTemplatesResponse',
    as ArrayRef[ListApplicationTemplatesResponse()];

coerce 'RepeatedListApplicationTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListApplicationTemplatesResponse',
    as HashRef[ListApplicationTemplatesResponse()];

declare 'GetApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateRequest'];

coerce 'GetApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateRequest'->new($_) };

declare 'RepeatedGetApplicationTemplateRequest',
    as ArrayRef[GetApplicationTemplateRequest()];

coerce 'RepeatedGetApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationTemplateRequest',
    as HashRef[GetApplicationTemplateRequest()];

declare 'CreateApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::CreateApplicationTemplateRequest'];

coerce 'CreateApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CreateApplicationTemplateRequest'->new($_) };

declare 'RepeatedCreateApplicationTemplateRequest',
    as ArrayRef[CreateApplicationTemplateRequest()];

coerce 'RepeatedCreateApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CreateApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationTemplateRequest',
    as HashRef[CreateApplicationTemplateRequest()];

declare 'UpdateApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateApplicationTemplateRequest'];

coerce 'UpdateApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateApplicationTemplateRequest'->new($_) };

declare 'RepeatedUpdateApplicationTemplateRequest',
    as ArrayRef[UpdateApplicationTemplateRequest()];

coerce 'RepeatedUpdateApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationTemplateRequest',
    as HashRef[UpdateApplicationTemplateRequest()];

declare 'DeleteApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteApplicationTemplateRequest'];

coerce 'DeleteApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteApplicationTemplateRequest'->new($_) };

declare 'RepeatedDeleteApplicationTemplateRequest',
    as ArrayRef[DeleteApplicationTemplateRequest()];

coerce 'RepeatedDeleteApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationTemplateRequest',
    as HashRef[DeleteApplicationTemplateRequest()];

declare 'CommitApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::CommitApplicationTemplateRequest'];

coerce 'CommitApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CommitApplicationTemplateRequest'->new($_) };

declare 'RepeatedCommitApplicationTemplateRequest',
    as ArrayRef[CommitApplicationTemplateRequest()];

coerce 'RepeatedCommitApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CommitApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCommitApplicationTemplateRequest',
    as HashRef[CommitApplicationTemplateRequest()];

declare 'SnapshotApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::SnapshotApplicationTemplateRequest'];

coerce 'SnapshotApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::SnapshotApplicationTemplateRequest'->new($_) };

declare 'RepeatedSnapshotApplicationTemplateRequest',
    as ArrayRef[SnapshotApplicationTemplateRequest()];

coerce 'RepeatedSnapshotApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::SnapshotApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringSnapshotApplicationTemplateRequest',
    as HashRef[SnapshotApplicationTemplateRequest()];

declare 'SnapshotApplicationTemplateResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::SnapshotApplicationTemplateResponse'];

coerce 'SnapshotApplicationTemplateResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::SnapshotApplicationTemplateResponse'->new($_) };

declare 'RepeatedSnapshotApplicationTemplateResponse',
    as ArrayRef[SnapshotApplicationTemplateResponse()];

coerce 'RepeatedSnapshotApplicationTemplateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::SnapshotApplicationTemplateResponse'->new($_) } @$_ ] };

declare 'MapStringSnapshotApplicationTemplateResponse',
    as HashRef[SnapshotApplicationTemplateResponse()];

declare 'ImportApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateRequest'];

coerce 'ImportApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateRequest'->new($_) };

declare 'RepeatedImportApplicationTemplateRequest',
    as ArrayRef[ImportApplicationTemplateRequest()];

coerce 'RepeatedImportApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringImportApplicationTemplateRequest',
    as HashRef[ImportApplicationTemplateRequest()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateRequest::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateRequest::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateRequest::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'GenerateApplicationTemplateRevisionIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateRevisionIaCRequest'];

coerce 'GenerateApplicationTemplateRevisionIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateRevisionIaCRequest'->new($_) };

declare 'RepeatedGenerateApplicationTemplateRevisionIaCRequest',
    as ArrayRef[GenerateApplicationTemplateRevisionIaCRequest()];

coerce 'RepeatedGenerateApplicationTemplateRevisionIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateRevisionIaCRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationTemplateRevisionIaCRequest',
    as HashRef[GenerateApplicationTemplateRevisionIaCRequest()];

declare 'IACFormat',
    as (Int | Str);

declare 'GenerateApplicationTemplateRevisionIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateRevisionIaCResponse'];

coerce 'GenerateApplicationTemplateRevisionIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateRevisionIaCResponse'->new($_) };

declare 'RepeatedGenerateApplicationTemplateRevisionIaCResponse',
    as ArrayRef[GenerateApplicationTemplateRevisionIaCResponse()];

coerce 'RepeatedGenerateApplicationTemplateRevisionIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateRevisionIaCResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationTemplateRevisionIaCResponse',
    as HashRef[GenerateApplicationTemplateRevisionIaCResponse()];

declare 'GenerateApplicationTemplateIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateIaCRequest'];

coerce 'GenerateApplicationTemplateIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateIaCRequest'->new($_) };

declare 'RepeatedGenerateApplicationTemplateIaCRequest',
    as ArrayRef[GenerateApplicationTemplateIaCRequest()];

coerce 'RepeatedGenerateApplicationTemplateIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateIaCRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationTemplateIaCRequest',
    as HashRef[GenerateApplicationTemplateIaCRequest()];

declare 'IACFormat',
    as (Int | Str);

declare 'GenerateApplicationTemplateIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateIaCResponse'];

coerce 'GenerateApplicationTemplateIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateIaCResponse'->new($_) };

declare 'RepeatedGenerateApplicationTemplateIaCResponse',
    as ArrayRef[GenerateApplicationTemplateIaCResponse()];

coerce 'RepeatedGenerateApplicationTemplateIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GenerateApplicationTemplateIaCResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateApplicationTemplateIaCResponse',
    as HashRef[GenerateApplicationTemplateIaCResponse()];

declare 'ExportApplicationTemplateIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateIaCRequest'];

coerce 'ExportApplicationTemplateIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateIaCRequest'->new($_) };

declare 'RepeatedExportApplicationTemplateIaCRequest',
    as ArrayRef[ExportApplicationTemplateIaCRequest()];

coerce 'RepeatedExportApplicationTemplateIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateIaCRequest'->new($_) } @$_ ] };

declare 'MapStringExportApplicationTemplateIaCRequest',
    as HashRef[ExportApplicationTemplateIaCRequest()];

declare 'ExportApplicationTemplateIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateIaCResponse'];

coerce 'ExportApplicationTemplateIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateIaCResponse'->new($_) };

declare 'RepeatedExportApplicationTemplateIaCResponse',
    as ArrayRef[ExportApplicationTemplateIaCResponse()];

coerce 'RepeatedExportApplicationTemplateIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateIaCResponse'->new($_) } @$_ ] };

declare 'MapStringExportApplicationTemplateIaCResponse',
    as HashRef[ExportApplicationTemplateIaCResponse()];

declare 'ExportApplicationTemplateRevisionIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateRevisionIaCRequest'];

coerce 'ExportApplicationTemplateRevisionIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateRevisionIaCRequest'->new($_) };

declare 'RepeatedExportApplicationTemplateRevisionIaCRequest',
    as ArrayRef[ExportApplicationTemplateRevisionIaCRequest()];

coerce 'RepeatedExportApplicationTemplateRevisionIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateRevisionIaCRequest'->new($_) } @$_ ] };

declare 'MapStringExportApplicationTemplateRevisionIaCRequest',
    as HashRef[ExportApplicationTemplateRevisionIaCRequest()];

declare 'ExportApplicationTemplateRevisionIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateRevisionIaCResponse'];

coerce 'ExportApplicationTemplateRevisionIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateRevisionIaCResponse'->new($_) };

declare 'RepeatedExportApplicationTemplateRevisionIaCResponse',
    as ArrayRef[ExportApplicationTemplateRevisionIaCResponse()];

coerce 'RepeatedExportApplicationTemplateRevisionIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ExportApplicationTemplateRevisionIaCResponse'->new($_) } @$_ ] };

declare 'MapStringExportApplicationTemplateRevisionIaCResponse',
    as HashRef[ExportApplicationTemplateRevisionIaCResponse()];

declare 'ImportApplicationTemplateIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateIaCRequest'];

coerce 'ImportApplicationTemplateIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateIaCRequest'->new($_) };

declare 'RepeatedImportApplicationTemplateIaCRequest',
    as ArrayRef[ImportApplicationTemplateIaCRequest()];

coerce 'RepeatedImportApplicationTemplateIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateIaCRequest'->new($_) } @$_ ] };

declare 'MapStringImportApplicationTemplateIaCRequest',
    as HashRef[ImportApplicationTemplateIaCRequest()];

declare 'ImportApplicationTemplateIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateIaCResponse'];

coerce 'ImportApplicationTemplateIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateIaCResponse'->new($_) };

declare 'RepeatedImportApplicationTemplateIaCResponse',
    as ArrayRef[ImportApplicationTemplateIaCResponse()];

coerce 'RepeatedImportApplicationTemplateIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportApplicationTemplateIaCResponse'->new($_) } @$_ ] };

declare 'MapStringImportApplicationTemplateIaCResponse',
    as HashRef[ImportApplicationTemplateIaCResponse()];

declare 'State',
    as (Int | Str);

declare 'IngestApplicationTemplateIaCRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::IngestApplicationTemplateIaCRequest'];

coerce 'IngestApplicationTemplateIaCRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::IngestApplicationTemplateIaCRequest'->new($_) };

declare 'RepeatedIngestApplicationTemplateIaCRequest',
    as ArrayRef[IngestApplicationTemplateIaCRequest()];

coerce 'RepeatedIngestApplicationTemplateIaCRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::IngestApplicationTemplateIaCRequest'->new($_) } @$_ ] };

declare 'MapStringIngestApplicationTemplateIaCRequest',
    as HashRef[IngestApplicationTemplateIaCRequest()];

declare 'IngestApplicationTemplateIaCResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::IngestApplicationTemplateIaCResponse'];

coerce 'IngestApplicationTemplateIaCResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::IngestApplicationTemplateIaCResponse'->new($_) };

declare 'RepeatedIngestApplicationTemplateIaCResponse',
    as ArrayRef[IngestApplicationTemplateIaCResponse()];

coerce 'RepeatedIngestApplicationTemplateIaCResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::IngestApplicationTemplateIaCResponse'->new($_) } @$_ ] };

declare 'MapStringIngestApplicationTemplateIaCResponse',
    as HashRef[IngestApplicationTemplateIaCResponse()];

declare 'ListComponentsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListComponentsRequest'];

coerce 'ListComponentsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListComponentsRequest'->new($_) };

declare 'RepeatedListComponentsRequest',
    as ArrayRef[ListComponentsRequest()];

coerce 'RepeatedListComponentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListComponentsRequest'->new($_) } @$_ ] };

declare 'MapStringListComponentsRequest',
    as HashRef[ListComponentsRequest()];

declare 'ListComponentsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListComponentsResponse'];

coerce 'ListComponentsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListComponentsResponse'->new($_) };

declare 'RepeatedListComponentsResponse',
    as ArrayRef[ListComponentsResponse()];

coerce 'RepeatedListComponentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListComponentsResponse'->new($_) } @$_ ] };

declare 'MapStringListComponentsResponse',
    as HashRef[ListComponentsResponse()];

declare 'GetComponentRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GetComponentRequest'];

coerce 'GetComponentRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetComponentRequest'->new($_) };

declare 'RepeatedGetComponentRequest',
    as ArrayRef[GetComponentRequest()];

coerce 'RepeatedGetComponentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetComponentRequest'->new($_) } @$_ ] };

declare 'MapStringGetComponentRequest',
    as HashRef[GetComponentRequest()];

declare 'CreateComponentRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::CreateComponentRequest'];

coerce 'CreateComponentRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CreateComponentRequest'->new($_) };

declare 'RepeatedCreateComponentRequest',
    as ArrayRef[CreateComponentRequest()];

coerce 'RepeatedCreateComponentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CreateComponentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateComponentRequest',
    as HashRef[CreateComponentRequest()];

declare 'UpdateComponentRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateComponentRequest'];

coerce 'UpdateComponentRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateComponentRequest'->new($_) };

declare 'RepeatedUpdateComponentRequest',
    as ArrayRef[UpdateComponentRequest()];

coerce 'RepeatedUpdateComponentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateComponentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateComponentRequest',
    as HashRef[UpdateComponentRequest()];

declare 'DeleteComponentRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteComponentRequest'];

coerce 'DeleteComponentRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteComponentRequest'->new($_) };

declare 'RepeatedDeleteComponentRequest',
    as ArrayRef[DeleteComponentRequest()];

coerce 'RepeatedDeleteComponentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteComponentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteComponentRequest',
    as HashRef[DeleteComponentRequest()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'ImportSerializedApplicationTemplateRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ImportSerializedApplicationTemplateRequest'];

coerce 'ImportSerializedApplicationTemplateRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportSerializedApplicationTemplateRequest'->new($_) };

declare 'RepeatedImportSerializedApplicationTemplateRequest',
    as ArrayRef[ImportSerializedApplicationTemplateRequest()];

coerce 'RepeatedImportSerializedApplicationTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ImportSerializedApplicationTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringImportSerializedApplicationTemplateRequest',
    as HashRef[ImportSerializedApplicationTemplateRequest()];

declare 'ListApplicationTemplateRevisionsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateRevisionsRequest'];

coerce 'ListApplicationTemplateRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateRevisionsRequest'->new($_) };

declare 'RepeatedListApplicationTemplateRevisionsRequest',
    as ArrayRef[ListApplicationTemplateRevisionsRequest()];

coerce 'RepeatedListApplicationTemplateRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListApplicationTemplateRevisionsRequest',
    as HashRef[ListApplicationTemplateRevisionsRequest()];

declare 'ListApplicationTemplateRevisionsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateRevisionsResponse'];

coerce 'ListApplicationTemplateRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateRevisionsResponse'->new($_) };

declare 'RepeatedListApplicationTemplateRevisionsResponse',
    as ArrayRef[ListApplicationTemplateRevisionsResponse()];

coerce 'RepeatedListApplicationTemplateRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListApplicationTemplateRevisionsResponse',
    as HashRef[ListApplicationTemplateRevisionsResponse()];

declare 'GetApplicationTemplateRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateRevisionRequest'];

coerce 'GetApplicationTemplateRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateRevisionRequest'->new($_) };

declare 'RepeatedGetApplicationTemplateRevisionRequest',
    as ArrayRef[GetApplicationTemplateRevisionRequest()];

coerce 'RepeatedGetApplicationTemplateRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationTemplateRevisionRequest',
    as HashRef[GetApplicationTemplateRevisionRequest()];

declare 'DeleteApplicationTemplateRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteApplicationTemplateRevisionRequest'];

coerce 'DeleteApplicationTemplateRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteApplicationTemplateRevisionRequest'->new($_) };

declare 'RepeatedDeleteApplicationTemplateRevisionRequest',
    as ArrayRef[DeleteApplicationTemplateRevisionRequest()];

coerce 'RepeatedDeleteApplicationTemplateRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::DeleteApplicationTemplateRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationTemplateRevisionRequest',
    as HashRef[DeleteApplicationTemplateRevisionRequest()];

declare 'ListApplicationTemplateSystemRevisionsRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateSystemRevisionsRequest'];

coerce 'ListApplicationTemplateSystemRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateSystemRevisionsRequest'->new($_) };

declare 'RepeatedListApplicationTemplateSystemRevisionsRequest',
    as ArrayRef[ListApplicationTemplateSystemRevisionsRequest()];

coerce 'RepeatedListApplicationTemplateSystemRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateSystemRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListApplicationTemplateSystemRevisionsRequest',
    as HashRef[ListApplicationTemplateSystemRevisionsRequest()];

declare 'ListApplicationTemplateSystemRevisionsResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateSystemRevisionsResponse'];

coerce 'ListApplicationTemplateSystemRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateSystemRevisionsResponse'->new($_) };

declare 'RepeatedListApplicationTemplateSystemRevisionsResponse',
    as ArrayRef[ListApplicationTemplateSystemRevisionsResponse()];

coerce 'RepeatedListApplicationTemplateSystemRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::ListApplicationTemplateSystemRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListApplicationTemplateSystemRevisionsResponse',
    as HashRef[ListApplicationTemplateSystemRevisionsResponse()];

declare 'GetApplicationTemplateSystemRevisionRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateSystemRevisionRequest'];

coerce 'GetApplicationTemplateSystemRevisionRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateSystemRevisionRequest'->new($_) };

declare 'RepeatedGetApplicationTemplateSystemRevisionRequest',
    as ArrayRef[GetApplicationTemplateSystemRevisionRequest()];

coerce 'RepeatedGetApplicationTemplateSystemRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::AuthoringMessages::GetApplicationTemplateSystemRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationTemplateSystemRevisionRequest',
    as HashRef[GetApplicationTemplateSystemRevisionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::AuthoringMessages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
