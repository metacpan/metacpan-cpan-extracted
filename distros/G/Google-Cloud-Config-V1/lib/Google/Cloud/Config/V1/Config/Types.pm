package Google::Cloud::Config::V1::Config::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'QuotaValidation',
    as (Int | Str);

declare 'Deployment',
    as InstanceOf['Google::Cloud::Config::V1::Config::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'State',
    as (Int | Str);

declare 'ErrorCode',
    as (Int | Str);

declare 'LockState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::Deployment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Deployment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Deployment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::Deployment::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Deployment::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Deployment::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'TerraformBlueprint',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformBlueprint'];

coerce 'TerraformBlueprint',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformBlueprint'->new($_) };

declare 'RepeatedTerraformBlueprint',
    as ArrayRef[TerraformBlueprint()];

coerce 'RepeatedTerraformBlueprint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformBlueprint'->new($_) } @$_ ] };

declare 'MapStringTerraformBlueprint',
    as HashRef[TerraformBlueprint()];

declare 'InputValuesEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformBlueprint::InputValuesEntry'];

coerce 'InputValuesEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformBlueprint::InputValuesEntry'->new($_) };

declare 'RepeatedInputValuesEntry',
    as ArrayRef[InputValuesEntry()];

coerce 'RepeatedInputValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformBlueprint::InputValuesEntry'->new($_) } @$_ ] };

declare 'MapStringInputValuesEntry',
    as HashRef[InputValuesEntry()];

declare 'ExternalValuesEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformBlueprint::ExternalValuesEntry'];

coerce 'ExternalValuesEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformBlueprint::ExternalValuesEntry'->new($_) };

declare 'RepeatedExternalValuesEntry',
    as ArrayRef[ExternalValuesEntry()];

coerce 'RepeatedExternalValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformBlueprint::ExternalValuesEntry'->new($_) } @$_ ] };

declare 'MapStringExternalValuesEntry',
    as HashRef[ExternalValuesEntry()];

declare 'TerraformVariable',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformVariable'];

coerce 'TerraformVariable',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformVariable'->new($_) };

declare 'RepeatedTerraformVariable',
    as ArrayRef[TerraformVariable()];

coerce 'RepeatedTerraformVariable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformVariable'->new($_) } @$_ ] };

declare 'MapStringTerraformVariable',
    as HashRef[TerraformVariable()];

declare 'ExternalValueSource',
    as InstanceOf['Google::Cloud::Config::V1::Config::ExternalValueSource'];

coerce 'ExternalValueSource',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ExternalValueSource'->new($_) };

declare 'RepeatedExternalValueSource',
    as ArrayRef[ExternalValueSource()];

coerce 'RepeatedExternalValueSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ExternalValueSource'->new($_) } @$_ ] };

declare 'MapStringExternalValueSource',
    as HashRef[ExternalValueSource()];

declare 'DeploymentSource',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentSource'];

coerce 'DeploymentSource',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentSource'->new($_) };

declare 'RepeatedDeploymentSource',
    as ArrayRef[DeploymentSource()];

coerce 'RepeatedDeploymentSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentSource'->new($_) } @$_ ] };

declare 'MapStringDeploymentSource',
    as HashRef[DeploymentSource()];

declare 'ApplyResults',
    as InstanceOf['Google::Cloud::Config::V1::Config::ApplyResults'];

coerce 'ApplyResults',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ApplyResults'->new($_) };

declare 'RepeatedApplyResults',
    as ArrayRef[ApplyResults()];

coerce 'RepeatedApplyResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ApplyResults'->new($_) } @$_ ] };

declare 'MapStringApplyResults',
    as HashRef[ApplyResults()];

declare 'OutputsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::ApplyResults::OutputsEntry'];

coerce 'OutputsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ApplyResults::OutputsEntry'->new($_) };

declare 'RepeatedOutputsEntry',
    as ArrayRef[OutputsEntry()];

coerce 'RepeatedOutputsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ApplyResults::OutputsEntry'->new($_) } @$_ ] };

declare 'MapStringOutputsEntry',
    as HashRef[OutputsEntry()];

declare 'TerraformOutput',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformOutput'];

coerce 'TerraformOutput',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformOutput'->new($_) };

declare 'RepeatedTerraformOutput',
    as ArrayRef[TerraformOutput()];

coerce 'RepeatedTerraformOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformOutput'->new($_) } @$_ ] };

declare 'MapStringTerraformOutput',
    as HashRef[TerraformOutput()];

declare 'ListDeploymentsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListDeploymentsRequest'];

coerce 'ListDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListDeploymentsRequest'->new($_) };

declare 'RepeatedListDeploymentsRequest',
    as ArrayRef[ListDeploymentsRequest()];

coerce 'RepeatedListDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsRequest',
    as HashRef[ListDeploymentsRequest()];

declare 'ListDeploymentsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListDeploymentsResponse'];

coerce 'ListDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListDeploymentsResponse'->new($_) };

declare 'RepeatedListDeploymentsResponse',
    as ArrayRef[ListDeploymentsResponse()];

coerce 'RepeatedListDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsResponse',
    as HashRef[ListDeploymentsResponse()];

declare 'GetDeploymentRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetDeploymentRequest'];

coerce 'GetDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetDeploymentRequest'->new($_) };

declare 'RepeatedGetDeploymentRequest',
    as ArrayRef[GetDeploymentRequest()];

coerce 'RepeatedGetDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentRequest',
    as HashRef[GetDeploymentRequest()];

declare 'ListRevisionsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListRevisionsRequest'];

coerce 'ListRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListRevisionsRequest'->new($_) };

declare 'RepeatedListRevisionsRequest',
    as ArrayRef[ListRevisionsRequest()];

coerce 'RepeatedListRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListRevisionsRequest',
    as HashRef[ListRevisionsRequest()];

declare 'ListRevisionsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListRevisionsResponse'];

coerce 'ListRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListRevisionsResponse'->new($_) };

declare 'RepeatedListRevisionsResponse',
    as ArrayRef[ListRevisionsResponse()];

coerce 'RepeatedListRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListRevisionsResponse',
    as HashRef[ListRevisionsResponse()];

declare 'GetRevisionRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetRevisionRequest'];

coerce 'GetRevisionRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetRevisionRequest'->new($_) };

declare 'RepeatedGetRevisionRequest',
    as ArrayRef[GetRevisionRequest()];

coerce 'RepeatedGetRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetRevisionRequest',
    as HashRef[GetRevisionRequest()];

declare 'CreateDeploymentRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::CreateDeploymentRequest'];

coerce 'CreateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::CreateDeploymentRequest'->new($_) };

declare 'RepeatedCreateDeploymentRequest',
    as ArrayRef[CreateDeploymentRequest()];

coerce 'RepeatedCreateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::CreateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeploymentRequest',
    as HashRef[CreateDeploymentRequest()];

declare 'CreateDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::CreateDeploymentGroupRequest'];

coerce 'CreateDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::CreateDeploymentGroupRequest'->new($_) };

declare 'RepeatedCreateDeploymentGroupRequest',
    as ArrayRef[CreateDeploymentGroupRequest()];

coerce 'RepeatedCreateDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::CreateDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeploymentGroupRequest',
    as HashRef[CreateDeploymentGroupRequest()];

declare 'UpdateDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::UpdateDeploymentGroupRequest'];

coerce 'UpdateDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::UpdateDeploymentGroupRequest'->new($_) };

declare 'RepeatedUpdateDeploymentGroupRequest',
    as ArrayRef[UpdateDeploymentGroupRequest()];

coerce 'RepeatedUpdateDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::UpdateDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeploymentGroupRequest',
    as HashRef[UpdateDeploymentGroupRequest()];

declare 'DeleteDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeleteDeploymentGroupRequest'];

coerce 'DeleteDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeleteDeploymentGroupRequest'->new($_) };

declare 'RepeatedDeleteDeploymentGroupRequest',
    as ArrayRef[DeleteDeploymentGroupRequest()];

coerce 'RepeatedDeleteDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeleteDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeploymentGroupRequest',
    as HashRef[DeleteDeploymentGroupRequest()];

declare 'DeploymentReferencePolicy',
    as (Int | Str);

declare 'UpdateDeploymentRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::UpdateDeploymentRequest'];

coerce 'UpdateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::UpdateDeploymentRequest'->new($_) };

declare 'RepeatedUpdateDeploymentRequest',
    as ArrayRef[UpdateDeploymentRequest()];

coerce 'RepeatedUpdateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::UpdateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeploymentRequest',
    as HashRef[UpdateDeploymentRequest()];

declare 'DeleteDeploymentRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeleteDeploymentRequest'];

coerce 'DeleteDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeleteDeploymentRequest'->new($_) };

declare 'RepeatedDeleteDeploymentRequest',
    as ArrayRef[DeleteDeploymentRequest()];

coerce 'RepeatedDeleteDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeleteDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeploymentRequest',
    as HashRef[DeleteDeploymentRequest()];

declare 'DeletePolicy',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Config::V1::Config::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Revision',
    as InstanceOf['Google::Cloud::Config::V1::Config::Revision'];

coerce 'Revision',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Revision'->new($_) };

declare 'RepeatedRevision',
    as ArrayRef[Revision()];

coerce 'RepeatedRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Revision'->new($_) } @$_ ] };

declare 'MapStringRevision',
    as HashRef[Revision()];

declare 'Action',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'ErrorCode',
    as (Int | Str);

declare 'TerraformError',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformError'];

coerce 'TerraformError',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformError'->new($_) };

declare 'RepeatedTerraformError',
    as ArrayRef[TerraformError()];

coerce 'RepeatedTerraformError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformError'->new($_) } @$_ ] };

declare 'MapStringTerraformError',
    as HashRef[TerraformError()];

declare 'GitSource',
    as InstanceOf['Google::Cloud::Config::V1::Config::GitSource'];

coerce 'GitSource',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GitSource'->new($_) };

declare 'RepeatedGitSource',
    as ArrayRef[GitSource()];

coerce 'RepeatedGitSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GitSource'->new($_) } @$_ ] };

declare 'MapStringGitSource',
    as HashRef[GitSource()];

declare 'DeploymentOperationMetadata',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentOperationMetadata'];

coerce 'DeploymentOperationMetadata',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentOperationMetadata'->new($_) };

declare 'RepeatedDeploymentOperationMetadata',
    as ArrayRef[DeploymentOperationMetadata()];

coerce 'RepeatedDeploymentOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeploymentOperationMetadata',
    as HashRef[DeploymentOperationMetadata()];

declare 'DeploymentStep',
    as (Int | Str);

declare 'Resource',
    as InstanceOf['Google::Cloud::Config::V1::Config::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'Intent',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'CaiAssetsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::Resource::CaiAssetsEntry'];

coerce 'CaiAssetsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Resource::CaiAssetsEntry'->new($_) };

declare 'RepeatedCaiAssetsEntry',
    as ArrayRef[CaiAssetsEntry()];

coerce 'RepeatedCaiAssetsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Resource::CaiAssetsEntry'->new($_) } @$_ ] };

declare 'MapStringCaiAssetsEntry',
    as HashRef[CaiAssetsEntry()];

declare 'ResourceTerraformInfo',
    as InstanceOf['Google::Cloud::Config::V1::Config::ResourceTerraformInfo'];

coerce 'ResourceTerraformInfo',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ResourceTerraformInfo'->new($_) };

declare 'RepeatedResourceTerraformInfo',
    as ArrayRef[ResourceTerraformInfo()];

coerce 'RepeatedResourceTerraformInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ResourceTerraformInfo'->new($_) } @$_ ] };

declare 'MapStringResourceTerraformInfo',
    as HashRef[ResourceTerraformInfo()];

declare 'ResourceCAIInfo',
    as InstanceOf['Google::Cloud::Config::V1::Config::ResourceCAIInfo'];

coerce 'ResourceCAIInfo',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ResourceCAIInfo'->new($_) };

declare 'RepeatedResourceCAIInfo',
    as ArrayRef[ResourceCAIInfo()];

coerce 'RepeatedResourceCAIInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ResourceCAIInfo'->new($_) } @$_ ] };

declare 'MapStringResourceCAIInfo',
    as HashRef[ResourceCAIInfo()];

declare 'GetResourceRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetResourceRequest'];

coerce 'GetResourceRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetResourceRequest'->new($_) };

declare 'RepeatedGetResourceRequest',
    as ArrayRef[GetResourceRequest()];

coerce 'RepeatedGetResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetResourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceRequest',
    as HashRef[GetResourceRequest()];

declare 'ListResourcesRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListResourcesRequest'];

coerce 'ListResourcesRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListResourcesRequest'->new($_) };

declare 'RepeatedListResourcesRequest',
    as ArrayRef[ListResourcesRequest()];

coerce 'RepeatedListResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListResourcesRequest',
    as HashRef[ListResourcesRequest()];

declare 'ListResourcesResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListResourcesResponse'];

coerce 'ListResourcesResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListResourcesResponse'->new($_) };

declare 'RepeatedListResourcesResponse',
    as ArrayRef[ListResourcesResponse()];

coerce 'RepeatedListResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListResourcesResponse',
    as HashRef[ListResourcesResponse()];

declare 'Statefile',
    as InstanceOf['Google::Cloud::Config::V1::Config::Statefile'];

coerce 'Statefile',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Statefile'->new($_) };

declare 'RepeatedStatefile',
    as ArrayRef[Statefile()];

coerce 'RepeatedStatefile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Statefile'->new($_) } @$_ ] };

declare 'MapStringStatefile',
    as HashRef[Statefile()];

declare 'ExportDeploymentStatefileRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ExportDeploymentStatefileRequest'];

coerce 'ExportDeploymentStatefileRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ExportDeploymentStatefileRequest'->new($_) };

declare 'RepeatedExportDeploymentStatefileRequest',
    as ArrayRef[ExportDeploymentStatefileRequest()];

coerce 'RepeatedExportDeploymentStatefileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ExportDeploymentStatefileRequest'->new($_) } @$_ ] };

declare 'MapStringExportDeploymentStatefileRequest',
    as HashRef[ExportDeploymentStatefileRequest()];

declare 'ExportRevisionStatefileRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ExportRevisionStatefileRequest'];

coerce 'ExportRevisionStatefileRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ExportRevisionStatefileRequest'->new($_) };

declare 'RepeatedExportRevisionStatefileRequest',
    as ArrayRef[ExportRevisionStatefileRequest()];

coerce 'RepeatedExportRevisionStatefileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ExportRevisionStatefileRequest'->new($_) } @$_ ] };

declare 'MapStringExportRevisionStatefileRequest',
    as HashRef[ExportRevisionStatefileRequest()];

declare 'ImportStatefileRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ImportStatefileRequest'];

coerce 'ImportStatefileRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ImportStatefileRequest'->new($_) };

declare 'RepeatedImportStatefileRequest',
    as ArrayRef[ImportStatefileRequest()];

coerce 'RepeatedImportStatefileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ImportStatefileRequest'->new($_) } @$_ ] };

declare 'MapStringImportStatefileRequest',
    as HashRef[ImportStatefileRequest()];

declare 'DeleteStatefileRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeleteStatefileRequest'];

coerce 'DeleteStatefileRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeleteStatefileRequest'->new($_) };

declare 'RepeatedDeleteStatefileRequest',
    as ArrayRef[DeleteStatefileRequest()];

coerce 'RepeatedDeleteStatefileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeleteStatefileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteStatefileRequest',
    as HashRef[DeleteStatefileRequest()];

declare 'LockDeploymentRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::LockDeploymentRequest'];

coerce 'LockDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::LockDeploymentRequest'->new($_) };

declare 'RepeatedLockDeploymentRequest',
    as ArrayRef[LockDeploymentRequest()];

coerce 'RepeatedLockDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::LockDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringLockDeploymentRequest',
    as HashRef[LockDeploymentRequest()];

declare 'UnlockDeploymentRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::UnlockDeploymentRequest'];

coerce 'UnlockDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::UnlockDeploymentRequest'->new($_) };

declare 'RepeatedUnlockDeploymentRequest',
    as ArrayRef[UnlockDeploymentRequest()];

coerce 'RepeatedUnlockDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::UnlockDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUnlockDeploymentRequest',
    as HashRef[UnlockDeploymentRequest()];

declare 'ExportLockInfoRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ExportLockInfoRequest'];

coerce 'ExportLockInfoRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ExportLockInfoRequest'->new($_) };

declare 'RepeatedExportLockInfoRequest',
    as ArrayRef[ExportLockInfoRequest()];

coerce 'RepeatedExportLockInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ExportLockInfoRequest'->new($_) } @$_ ] };

declare 'MapStringExportLockInfoRequest',
    as HashRef[ExportLockInfoRequest()];

declare 'LockInfo',
    as InstanceOf['Google::Cloud::Config::V1::Config::LockInfo'];

coerce 'LockInfo',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::LockInfo'->new($_) };

declare 'RepeatedLockInfo',
    as ArrayRef[LockInfo()];

coerce 'RepeatedLockInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::LockInfo'->new($_) } @$_ ] };

declare 'MapStringLockInfo',
    as HashRef[LockInfo()];

declare 'Preview',
    as InstanceOf['Google::Cloud::Config::V1::Config::Preview'];

coerce 'Preview',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Preview'->new($_) };

declare 'RepeatedPreview',
    as ArrayRef[Preview()];

coerce 'RepeatedPreview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Preview'->new($_) } @$_ ] };

declare 'MapStringPreview',
    as HashRef[Preview()];

declare 'State',
    as (Int | Str);

declare 'PreviewMode',
    as (Int | Str);

declare 'ErrorCode',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::Preview::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Preview::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Preview::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::Preview::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::Preview::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::Preview::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PreviewOperationMetadata',
    as InstanceOf['Google::Cloud::Config::V1::Config::PreviewOperationMetadata'];

coerce 'PreviewOperationMetadata',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::PreviewOperationMetadata'->new($_) };

declare 'RepeatedPreviewOperationMetadata',
    as ArrayRef[PreviewOperationMetadata()];

coerce 'RepeatedPreviewOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::PreviewOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringPreviewOperationMetadata',
    as HashRef[PreviewOperationMetadata()];

declare 'PreviewStep',
    as (Int | Str);

declare 'PreviewArtifacts',
    as InstanceOf['Google::Cloud::Config::V1::Config::PreviewArtifacts'];

coerce 'PreviewArtifacts',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::PreviewArtifacts'->new($_) };

declare 'RepeatedPreviewArtifacts',
    as ArrayRef[PreviewArtifacts()];

coerce 'RepeatedPreviewArtifacts',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::PreviewArtifacts'->new($_) } @$_ ] };

declare 'MapStringPreviewArtifacts',
    as HashRef[PreviewArtifacts()];

declare 'CreatePreviewRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::CreatePreviewRequest'];

coerce 'CreatePreviewRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::CreatePreviewRequest'->new($_) };

declare 'RepeatedCreatePreviewRequest',
    as ArrayRef[CreatePreviewRequest()];

coerce 'RepeatedCreatePreviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::CreatePreviewRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePreviewRequest',
    as HashRef[CreatePreviewRequest()];

declare 'GetPreviewRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetPreviewRequest'];

coerce 'GetPreviewRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetPreviewRequest'->new($_) };

declare 'RepeatedGetPreviewRequest',
    as ArrayRef[GetPreviewRequest()];

coerce 'RepeatedGetPreviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetPreviewRequest'->new($_) } @$_ ] };

declare 'MapStringGetPreviewRequest',
    as HashRef[GetPreviewRequest()];

declare 'ListPreviewsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListPreviewsRequest'];

coerce 'ListPreviewsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListPreviewsRequest'->new($_) };

declare 'RepeatedListPreviewsRequest',
    as ArrayRef[ListPreviewsRequest()];

coerce 'RepeatedListPreviewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListPreviewsRequest'->new($_) } @$_ ] };

declare 'MapStringListPreviewsRequest',
    as HashRef[ListPreviewsRequest()];

declare 'ListPreviewsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListPreviewsResponse'];

coerce 'ListPreviewsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListPreviewsResponse'->new($_) };

declare 'RepeatedListPreviewsResponse',
    as ArrayRef[ListPreviewsResponse()];

coerce 'RepeatedListPreviewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListPreviewsResponse'->new($_) } @$_ ] };

declare 'MapStringListPreviewsResponse',
    as HashRef[ListPreviewsResponse()];

declare 'DeletePreviewRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeletePreviewRequest'];

coerce 'DeletePreviewRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeletePreviewRequest'->new($_) };

declare 'RepeatedDeletePreviewRequest',
    as ArrayRef[DeletePreviewRequest()];

coerce 'RepeatedDeletePreviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeletePreviewRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePreviewRequest',
    as HashRef[DeletePreviewRequest()];

declare 'ExportPreviewResultRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ExportPreviewResultRequest'];

coerce 'ExportPreviewResultRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ExportPreviewResultRequest'->new($_) };

declare 'RepeatedExportPreviewResultRequest',
    as ArrayRef[ExportPreviewResultRequest()];

coerce 'RepeatedExportPreviewResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ExportPreviewResultRequest'->new($_) } @$_ ] };

declare 'MapStringExportPreviewResultRequest',
    as HashRef[ExportPreviewResultRequest()];

declare 'ExportPreviewResultResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ExportPreviewResultResponse'];

coerce 'ExportPreviewResultResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ExportPreviewResultResponse'->new($_) };

declare 'RepeatedExportPreviewResultResponse',
    as ArrayRef[ExportPreviewResultResponse()];

coerce 'RepeatedExportPreviewResultResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ExportPreviewResultResponse'->new($_) } @$_ ] };

declare 'MapStringExportPreviewResultResponse',
    as HashRef[ExportPreviewResultResponse()];

declare 'PreviewResult',
    as InstanceOf['Google::Cloud::Config::V1::Config::PreviewResult'];

coerce 'PreviewResult',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::PreviewResult'->new($_) };

declare 'RepeatedPreviewResult',
    as ArrayRef[PreviewResult()];

coerce 'RepeatedPreviewResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::PreviewResult'->new($_) } @$_ ] };

declare 'MapStringPreviewResult',
    as HashRef[PreviewResult()];

declare 'GetTerraformVersionRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetTerraformVersionRequest'];

coerce 'GetTerraformVersionRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetTerraformVersionRequest'->new($_) };

declare 'RepeatedGetTerraformVersionRequest',
    as ArrayRef[GetTerraformVersionRequest()];

coerce 'RepeatedGetTerraformVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetTerraformVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetTerraformVersionRequest',
    as HashRef[GetTerraformVersionRequest()];

declare 'ListTerraformVersionsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListTerraformVersionsRequest'];

coerce 'ListTerraformVersionsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListTerraformVersionsRequest'->new($_) };

declare 'RepeatedListTerraformVersionsRequest',
    as ArrayRef[ListTerraformVersionsRequest()];

coerce 'RepeatedListTerraformVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListTerraformVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListTerraformVersionsRequest',
    as HashRef[ListTerraformVersionsRequest()];

declare 'ListTerraformVersionsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListTerraformVersionsResponse'];

coerce 'ListTerraformVersionsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListTerraformVersionsResponse'->new($_) };

declare 'RepeatedListTerraformVersionsResponse',
    as ArrayRef[ListTerraformVersionsResponse()];

coerce 'RepeatedListTerraformVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListTerraformVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListTerraformVersionsResponse',
    as HashRef[ListTerraformVersionsResponse()];

declare 'TerraformVersion',
    as InstanceOf['Google::Cloud::Config::V1::Config::TerraformVersion'];

coerce 'TerraformVersion',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::TerraformVersion'->new($_) };

declare 'RepeatedTerraformVersion',
    as ArrayRef[TerraformVersion()];

coerce 'RepeatedTerraformVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::TerraformVersion'->new($_) } @$_ ] };

declare 'MapStringTerraformVersion',
    as HashRef[TerraformVersion()];

declare 'State',
    as (Int | Str);

declare 'ResourceChangeTerraformInfo',
    as InstanceOf['Google::Cloud::Config::V1::Config::ResourceChangeTerraformInfo'];

coerce 'ResourceChangeTerraformInfo',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ResourceChangeTerraformInfo'->new($_) };

declare 'RepeatedResourceChangeTerraformInfo',
    as ArrayRef[ResourceChangeTerraformInfo()];

coerce 'RepeatedResourceChangeTerraformInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ResourceChangeTerraformInfo'->new($_) } @$_ ] };

declare 'MapStringResourceChangeTerraformInfo',
    as HashRef[ResourceChangeTerraformInfo()];

declare 'ResourceChange',
    as InstanceOf['Google::Cloud::Config::V1::Config::ResourceChange'];

coerce 'ResourceChange',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ResourceChange'->new($_) };

declare 'RepeatedResourceChange',
    as ArrayRef[ResourceChange()];

coerce 'RepeatedResourceChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ResourceChange'->new($_) } @$_ ] };

declare 'MapStringResourceChange',
    as HashRef[ResourceChange()];

declare 'Intent',
    as (Int | Str);

declare 'PropertyChange',
    as InstanceOf['Google::Cloud::Config::V1::Config::PropertyChange'];

coerce 'PropertyChange',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::PropertyChange'->new($_) };

declare 'RepeatedPropertyChange',
    as ArrayRef[PropertyChange()];

coerce 'RepeatedPropertyChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::PropertyChange'->new($_) } @$_ ] };

declare 'MapStringPropertyChange',
    as HashRef[PropertyChange()];

declare 'ListResourceChangesRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListResourceChangesRequest'];

coerce 'ListResourceChangesRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListResourceChangesRequest'->new($_) };

declare 'RepeatedListResourceChangesRequest',
    as ArrayRef[ListResourceChangesRequest()];

coerce 'RepeatedListResourceChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListResourceChangesRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceChangesRequest',
    as HashRef[ListResourceChangesRequest()];

declare 'ListResourceChangesResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListResourceChangesResponse'];

coerce 'ListResourceChangesResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListResourceChangesResponse'->new($_) };

declare 'RepeatedListResourceChangesResponse',
    as ArrayRef[ListResourceChangesResponse()];

coerce 'RepeatedListResourceChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListResourceChangesResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceChangesResponse',
    as HashRef[ListResourceChangesResponse()];

declare 'GetResourceChangeRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetResourceChangeRequest'];

coerce 'GetResourceChangeRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetResourceChangeRequest'->new($_) };

declare 'RepeatedGetResourceChangeRequest',
    as ArrayRef[GetResourceChangeRequest()];

coerce 'RepeatedGetResourceChangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetResourceChangeRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceChangeRequest',
    as HashRef[GetResourceChangeRequest()];

declare 'ResourceDriftTerraformInfo',
    as InstanceOf['Google::Cloud::Config::V1::Config::ResourceDriftTerraformInfo'];

coerce 'ResourceDriftTerraformInfo',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ResourceDriftTerraformInfo'->new($_) };

declare 'RepeatedResourceDriftTerraformInfo',
    as ArrayRef[ResourceDriftTerraformInfo()];

coerce 'RepeatedResourceDriftTerraformInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ResourceDriftTerraformInfo'->new($_) } @$_ ] };

declare 'MapStringResourceDriftTerraformInfo',
    as HashRef[ResourceDriftTerraformInfo()];

declare 'ResourceDrift',
    as InstanceOf['Google::Cloud::Config::V1::Config::ResourceDrift'];

coerce 'ResourceDrift',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ResourceDrift'->new($_) };

declare 'RepeatedResourceDrift',
    as ArrayRef[ResourceDrift()];

coerce 'RepeatedResourceDrift',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ResourceDrift'->new($_) } @$_ ] };

declare 'MapStringResourceDrift',
    as HashRef[ResourceDrift()];

declare 'PropertyDrift',
    as InstanceOf['Google::Cloud::Config::V1::Config::PropertyDrift'];

coerce 'PropertyDrift',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::PropertyDrift'->new($_) };

declare 'RepeatedPropertyDrift',
    as ArrayRef[PropertyDrift()];

coerce 'RepeatedPropertyDrift',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::PropertyDrift'->new($_) } @$_ ] };

declare 'MapStringPropertyDrift',
    as HashRef[PropertyDrift()];

declare 'ListResourceDriftsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListResourceDriftsRequest'];

coerce 'ListResourceDriftsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListResourceDriftsRequest'->new($_) };

declare 'RepeatedListResourceDriftsRequest',
    as ArrayRef[ListResourceDriftsRequest()];

coerce 'RepeatedListResourceDriftsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListResourceDriftsRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceDriftsRequest',
    as HashRef[ListResourceDriftsRequest()];

declare 'ListResourceDriftsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListResourceDriftsResponse'];

coerce 'ListResourceDriftsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListResourceDriftsResponse'->new($_) };

declare 'RepeatedListResourceDriftsResponse',
    as ArrayRef[ListResourceDriftsResponse()];

coerce 'RepeatedListResourceDriftsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListResourceDriftsResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceDriftsResponse',
    as HashRef[ListResourceDriftsResponse()];

declare 'GetResourceDriftRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetResourceDriftRequest'];

coerce 'GetResourceDriftRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetResourceDriftRequest'->new($_) };

declare 'RepeatedGetResourceDriftRequest',
    as ArrayRef[GetResourceDriftRequest()];

coerce 'RepeatedGetResourceDriftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetResourceDriftRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceDriftRequest',
    as HashRef[GetResourceDriftRequest()];

declare 'ProviderConfig',
    as InstanceOf['Google::Cloud::Config::V1::Config::ProviderConfig'];

coerce 'ProviderConfig',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ProviderConfig'->new($_) };

declare 'RepeatedProviderConfig',
    as ArrayRef[ProviderConfig()];

coerce 'RepeatedProviderConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ProviderConfig'->new($_) } @$_ ] };

declare 'MapStringProviderConfig',
    as HashRef[ProviderConfig()];

declare 'ProviderSource',
    as (Int | Str);

declare 'GetAutoMigrationConfigRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetAutoMigrationConfigRequest'];

coerce 'GetAutoMigrationConfigRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetAutoMigrationConfigRequest'->new($_) };

declare 'RepeatedGetAutoMigrationConfigRequest',
    as ArrayRef[GetAutoMigrationConfigRequest()];

coerce 'RepeatedGetAutoMigrationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetAutoMigrationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutoMigrationConfigRequest',
    as HashRef[GetAutoMigrationConfigRequest()];

declare 'AutoMigrationConfig',
    as InstanceOf['Google::Cloud::Config::V1::Config::AutoMigrationConfig'];

coerce 'AutoMigrationConfig',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::AutoMigrationConfig'->new($_) };

declare 'RepeatedAutoMigrationConfig',
    as ArrayRef[AutoMigrationConfig()];

coerce 'RepeatedAutoMigrationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::AutoMigrationConfig'->new($_) } @$_ ] };

declare 'MapStringAutoMigrationConfig',
    as HashRef[AutoMigrationConfig()];

declare 'UpdateAutoMigrationConfigRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::UpdateAutoMigrationConfigRequest'];

coerce 'UpdateAutoMigrationConfigRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::UpdateAutoMigrationConfigRequest'->new($_) };

declare 'RepeatedUpdateAutoMigrationConfigRequest',
    as ArrayRef[UpdateAutoMigrationConfigRequest()];

coerce 'RepeatedUpdateAutoMigrationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::UpdateAutoMigrationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAutoMigrationConfigRequest',
    as HashRef[UpdateAutoMigrationConfigRequest()];

declare 'DeploymentGroup',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentGroup'];

coerce 'DeploymentGroup',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentGroup'->new($_) };

declare 'RepeatedDeploymentGroup',
    as ArrayRef[DeploymentGroup()];

coerce 'RepeatedDeploymentGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentGroup'->new($_) } @$_ ] };

declare 'MapStringDeploymentGroup',
    as HashRef[DeploymentGroup()];

declare 'State',
    as (Int | Str);

declare 'ProvisioningState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentGroup::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentGroup::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentGroup::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'DeploymentUnit',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentUnit'];

coerce 'DeploymentUnit',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentUnit'->new($_) };

declare 'RepeatedDeploymentUnit',
    as ArrayRef[DeploymentUnit()];

coerce 'RepeatedDeploymentUnit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentUnit'->new($_) } @$_ ] };

declare 'MapStringDeploymentUnit',
    as HashRef[DeploymentUnit()];

declare 'DeploymentSpec',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentSpec'];

coerce 'DeploymentSpec',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentSpec'->new($_) };

declare 'RepeatedDeploymentSpec',
    as ArrayRef[DeploymentSpec()];

coerce 'RepeatedDeploymentSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentSpec'->new($_) } @$_ ] };

declare 'MapStringDeploymentSpec',
    as HashRef[DeploymentSpec()];

declare 'GetDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetDeploymentGroupRequest'];

coerce 'GetDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetDeploymentGroupRequest'->new($_) };

declare 'RepeatedGetDeploymentGroupRequest',
    as ArrayRef[GetDeploymentGroupRequest()];

coerce 'RepeatedGetDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentGroupRequest',
    as HashRef[GetDeploymentGroupRequest()];

declare 'ListDeploymentGroupsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListDeploymentGroupsRequest'];

coerce 'ListDeploymentGroupsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupsRequest'->new($_) };

declare 'RepeatedListDeploymentGroupsRequest',
    as ArrayRef[ListDeploymentGroupsRequest()];

coerce 'RepeatedListDeploymentGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentGroupsRequest',
    as HashRef[ListDeploymentGroupsRequest()];

declare 'ListDeploymentGroupsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListDeploymentGroupsResponse'];

coerce 'ListDeploymentGroupsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupsResponse'->new($_) };

declare 'RepeatedListDeploymentGroupsResponse',
    as ArrayRef[ListDeploymentGroupsResponse()];

coerce 'RepeatedListDeploymentGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentGroupsResponse',
    as HashRef[ListDeploymentGroupsResponse()];

declare 'ProvisionDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupRequest'];

coerce 'ProvisionDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupRequest'->new($_) };

declare 'RepeatedProvisionDeploymentGroupRequest',
    as ArrayRef[ProvisionDeploymentGroupRequest()];

coerce 'RepeatedProvisionDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringProvisionDeploymentGroupRequest',
    as HashRef[ProvisionDeploymentGroupRequest()];

declare 'DeploymentSpecsEntry',
    as InstanceOf['Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupRequest::DeploymentSpecsEntry'];

coerce 'DeploymentSpecsEntry',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupRequest::DeploymentSpecsEntry'->new($_) };

declare 'RepeatedDeploymentSpecsEntry',
    as ArrayRef[DeploymentSpecsEntry()];

coerce 'RepeatedDeploymentSpecsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupRequest::DeploymentSpecsEntry'->new($_) } @$_ ] };

declare 'MapStringDeploymentSpecsEntry',
    as HashRef[DeploymentSpecsEntry()];

declare 'DeprovisionDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeprovisionDeploymentGroupRequest'];

coerce 'DeprovisionDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeprovisionDeploymentGroupRequest'->new($_) };

declare 'RepeatedDeprovisionDeploymentGroupRequest',
    as ArrayRef[DeprovisionDeploymentGroupRequest()];

coerce 'RepeatedDeprovisionDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeprovisionDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeprovisionDeploymentGroupRequest',
    as HashRef[DeprovisionDeploymentGroupRequest()];

declare 'DeploymentOperationSummary',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentOperationSummary'];

coerce 'DeploymentOperationSummary',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentOperationSummary'->new($_) };

declare 'RepeatedDeploymentOperationSummary',
    as ArrayRef[DeploymentOperationSummary()];

coerce 'RepeatedDeploymentOperationSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentOperationSummary'->new($_) } @$_ ] };

declare 'MapStringDeploymentOperationSummary',
    as HashRef[DeploymentOperationSummary()];

declare 'DeploymentUnitProgress',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentUnitProgress'];

coerce 'DeploymentUnitProgress',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentUnitProgress'->new($_) };

declare 'RepeatedDeploymentUnitProgress',
    as ArrayRef[DeploymentUnitProgress()];

coerce 'RepeatedDeploymentUnitProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentUnitProgress'->new($_) } @$_ ] };

declare 'MapStringDeploymentUnitProgress',
    as HashRef[DeploymentUnitProgress()];

declare 'State',
    as (Int | Str);

declare 'Intent',
    as (Int | Str);

declare 'ProvisionDeploymentGroupOperationMetadata',
    as InstanceOf['Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupOperationMetadata'];

coerce 'ProvisionDeploymentGroupOperationMetadata',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupOperationMetadata'->new($_) };

declare 'RepeatedProvisionDeploymentGroupOperationMetadata',
    as ArrayRef[ProvisionDeploymentGroupOperationMetadata()];

coerce 'RepeatedProvisionDeploymentGroupOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ProvisionDeploymentGroupOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringProvisionDeploymentGroupOperationMetadata',
    as HashRef[ProvisionDeploymentGroupOperationMetadata()];

declare 'ProvisionDeploymentGroupStep',
    as (Int | Str);

declare 'DeploymentGroupRevision',
    as InstanceOf['Google::Cloud::Config::V1::Config::DeploymentGroupRevision'];

coerce 'DeploymentGroupRevision',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::DeploymentGroupRevision'->new($_) };

declare 'RepeatedDeploymentGroupRevision',
    as ArrayRef[DeploymentGroupRevision()];

coerce 'RepeatedDeploymentGroupRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::DeploymentGroupRevision'->new($_) } @$_ ] };

declare 'MapStringDeploymentGroupRevision',
    as HashRef[DeploymentGroupRevision()];

declare 'GetDeploymentGroupRevisionRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::GetDeploymentGroupRevisionRequest'];

coerce 'GetDeploymentGroupRevisionRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::GetDeploymentGroupRevisionRequest'->new($_) };

declare 'RepeatedGetDeploymentGroupRevisionRequest',
    as ArrayRef[GetDeploymentGroupRevisionRequest()];

coerce 'RepeatedGetDeploymentGroupRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::GetDeploymentGroupRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentGroupRevisionRequest',
    as HashRef[GetDeploymentGroupRevisionRequest()];

declare 'ListDeploymentGroupRevisionsRequest',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListDeploymentGroupRevisionsRequest'];

coerce 'ListDeploymentGroupRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupRevisionsRequest'->new($_) };

declare 'RepeatedListDeploymentGroupRevisionsRequest',
    as ArrayRef[ListDeploymentGroupRevisionsRequest()];

coerce 'RepeatedListDeploymentGroupRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentGroupRevisionsRequest',
    as HashRef[ListDeploymentGroupRevisionsRequest()];

declare 'ListDeploymentGroupRevisionsResponse',
    as InstanceOf['Google::Cloud::Config::V1::Config::ListDeploymentGroupRevisionsResponse'];

coerce 'ListDeploymentGroupRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupRevisionsResponse'->new($_) };

declare 'RepeatedListDeploymentGroupRevisionsResponse',
    as ArrayRef[ListDeploymentGroupRevisionsResponse()];

coerce 'RepeatedListDeploymentGroupRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Config::V1::Config::ListDeploymentGroupRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentGroupRevisionsResponse',
    as HashRef[ListDeploymentGroupRevisionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Config::V1::Config::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
