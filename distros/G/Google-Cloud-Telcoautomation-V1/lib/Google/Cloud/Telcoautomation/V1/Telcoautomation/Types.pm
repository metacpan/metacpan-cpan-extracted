package Google::Cloud::Telcoautomation::V1::Telcoautomation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BlueprintView',
    as (Int | Str);

declare 'DeploymentView',
    as (Int | Str);

declare 'ResourceType',
    as (Int | Str);

declare 'Status',
    as (Int | Str);

declare 'DeploymentLevel',
    as (Int | Str);

declare 'OrchestrationCluster',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::OrchestrationCluster'];

coerce 'OrchestrationCluster',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::OrchestrationCluster'->new($_) };

declare 'RepeatedOrchestrationCluster',
    as ArrayRef[OrchestrationCluster()];

coerce 'RepeatedOrchestrationCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::OrchestrationCluster'->new($_) } @$_ ] };

declare 'MapStringOrchestrationCluster',
    as HashRef[OrchestrationCluster()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::OrchestrationCluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::OrchestrationCluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::OrchestrationCluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EdgeSlm',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::EdgeSlm'];

coerce 'EdgeSlm',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::EdgeSlm'->new($_) };

declare 'RepeatedEdgeSlm',
    as ArrayRef[EdgeSlm()];

coerce 'RepeatedEdgeSlm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::EdgeSlm'->new($_) } @$_ ] };

declare 'MapStringEdgeSlm',
    as HashRef[EdgeSlm()];

declare 'State',
    as (Int | Str);

declare 'WorkloadClusterType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::EdgeSlm::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::EdgeSlm::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::EdgeSlm::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Blueprint',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::Blueprint'];

coerce 'Blueprint',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Blueprint'->new($_) };

declare 'RepeatedBlueprint',
    as ArrayRef[Blueprint()];

coerce 'RepeatedBlueprint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Blueprint'->new($_) } @$_ ] };

declare 'MapStringBlueprint',
    as HashRef[Blueprint()];

declare 'ApprovalState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::Blueprint::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Blueprint::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Blueprint::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PublicBlueprint',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::PublicBlueprint'];

coerce 'PublicBlueprint',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::PublicBlueprint'->new($_) };

declare 'RepeatedPublicBlueprint',
    as ArrayRef[PublicBlueprint()];

coerce 'RepeatedPublicBlueprint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::PublicBlueprint'->new($_) } @$_ ] };

declare 'MapStringPublicBlueprint',
    as HashRef[PublicBlueprint()];

declare 'Deployment',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::Deployment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Deployment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::Deployment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'HydratedDeployment',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::HydratedDeployment'];

coerce 'HydratedDeployment',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::HydratedDeployment'->new($_) };

declare 'RepeatedHydratedDeployment',
    as ArrayRef[HydratedDeployment()];

coerce 'RepeatedHydratedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::HydratedDeployment'->new($_) } @$_ ] };

declare 'MapStringHydratedDeployment',
    as HashRef[HydratedDeployment()];

declare 'State',
    as (Int | Str);

declare 'ListOrchestrationClustersRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListOrchestrationClustersRequest'];

coerce 'ListOrchestrationClustersRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListOrchestrationClustersRequest'->new($_) };

declare 'RepeatedListOrchestrationClustersRequest',
    as ArrayRef[ListOrchestrationClustersRequest()];

coerce 'RepeatedListOrchestrationClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListOrchestrationClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListOrchestrationClustersRequest',
    as HashRef[ListOrchestrationClustersRequest()];

declare 'ListOrchestrationClustersResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListOrchestrationClustersResponse'];

coerce 'ListOrchestrationClustersResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListOrchestrationClustersResponse'->new($_) };

declare 'RepeatedListOrchestrationClustersResponse',
    as ArrayRef[ListOrchestrationClustersResponse()];

coerce 'RepeatedListOrchestrationClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListOrchestrationClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListOrchestrationClustersResponse',
    as HashRef[ListOrchestrationClustersResponse()];

declare 'GetOrchestrationClusterRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::GetOrchestrationClusterRequest'];

coerce 'GetOrchestrationClusterRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetOrchestrationClusterRequest'->new($_) };

declare 'RepeatedGetOrchestrationClusterRequest',
    as ArrayRef[GetOrchestrationClusterRequest()];

coerce 'RepeatedGetOrchestrationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetOrchestrationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrchestrationClusterRequest',
    as HashRef[GetOrchestrationClusterRequest()];

declare 'CreateOrchestrationClusterRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateOrchestrationClusterRequest'];

coerce 'CreateOrchestrationClusterRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateOrchestrationClusterRequest'->new($_) };

declare 'RepeatedCreateOrchestrationClusterRequest',
    as ArrayRef[CreateOrchestrationClusterRequest()];

coerce 'RepeatedCreateOrchestrationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateOrchestrationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOrchestrationClusterRequest',
    as HashRef[CreateOrchestrationClusterRequest()];

declare 'DeleteOrchestrationClusterRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteOrchestrationClusterRequest'];

coerce 'DeleteOrchestrationClusterRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteOrchestrationClusterRequest'->new($_) };

declare 'RepeatedDeleteOrchestrationClusterRequest',
    as ArrayRef[DeleteOrchestrationClusterRequest()];

coerce 'RepeatedDeleteOrchestrationClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteOrchestrationClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOrchestrationClusterRequest',
    as HashRef[DeleteOrchestrationClusterRequest()];

declare 'ListEdgeSlmsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListEdgeSlmsRequest'];

coerce 'ListEdgeSlmsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListEdgeSlmsRequest'->new($_) };

declare 'RepeatedListEdgeSlmsRequest',
    as ArrayRef[ListEdgeSlmsRequest()];

coerce 'RepeatedListEdgeSlmsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListEdgeSlmsRequest'->new($_) } @$_ ] };

declare 'MapStringListEdgeSlmsRequest',
    as HashRef[ListEdgeSlmsRequest()];

declare 'ListEdgeSlmsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListEdgeSlmsResponse'];

coerce 'ListEdgeSlmsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListEdgeSlmsResponse'->new($_) };

declare 'RepeatedListEdgeSlmsResponse',
    as ArrayRef[ListEdgeSlmsResponse()];

coerce 'RepeatedListEdgeSlmsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListEdgeSlmsResponse'->new($_) } @$_ ] };

declare 'MapStringListEdgeSlmsResponse',
    as HashRef[ListEdgeSlmsResponse()];

declare 'GetEdgeSlmRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::GetEdgeSlmRequest'];

coerce 'GetEdgeSlmRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetEdgeSlmRequest'->new($_) };

declare 'RepeatedGetEdgeSlmRequest',
    as ArrayRef[GetEdgeSlmRequest()];

coerce 'RepeatedGetEdgeSlmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetEdgeSlmRequest'->new($_) } @$_ ] };

declare 'MapStringGetEdgeSlmRequest',
    as HashRef[GetEdgeSlmRequest()];

declare 'CreateEdgeSlmRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateEdgeSlmRequest'];

coerce 'CreateEdgeSlmRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateEdgeSlmRequest'->new($_) };

declare 'RepeatedCreateEdgeSlmRequest',
    as ArrayRef[CreateEdgeSlmRequest()];

coerce 'RepeatedCreateEdgeSlmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateEdgeSlmRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEdgeSlmRequest',
    as HashRef[CreateEdgeSlmRequest()];

declare 'DeleteEdgeSlmRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteEdgeSlmRequest'];

coerce 'DeleteEdgeSlmRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteEdgeSlmRequest'->new($_) };

declare 'RepeatedDeleteEdgeSlmRequest',
    as ArrayRef[DeleteEdgeSlmRequest()];

coerce 'RepeatedDeleteEdgeSlmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteEdgeSlmRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEdgeSlmRequest',
    as HashRef[DeleteEdgeSlmRequest()];

declare 'CreateBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateBlueprintRequest'];

coerce 'CreateBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateBlueprintRequest'->new($_) };

declare 'RepeatedCreateBlueprintRequest',
    as ArrayRef[CreateBlueprintRequest()];

coerce 'RepeatedCreateBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBlueprintRequest',
    as HashRef[CreateBlueprintRequest()];

declare 'UpdateBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateBlueprintRequest'];

coerce 'UpdateBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateBlueprintRequest'->new($_) };

declare 'RepeatedUpdateBlueprintRequest',
    as ArrayRef[UpdateBlueprintRequest()];

coerce 'RepeatedUpdateBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBlueprintRequest',
    as HashRef[UpdateBlueprintRequest()];

declare 'GetBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::GetBlueprintRequest'];

coerce 'GetBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetBlueprintRequest'->new($_) };

declare 'RepeatedGetBlueprintRequest',
    as ArrayRef[GetBlueprintRequest()];

coerce 'RepeatedGetBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringGetBlueprintRequest',
    as HashRef[GetBlueprintRequest()];

declare 'DeleteBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteBlueprintRequest'];

coerce 'DeleteBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteBlueprintRequest'->new($_) };

declare 'RepeatedDeleteBlueprintRequest',
    as ArrayRef[DeleteBlueprintRequest()];

coerce 'RepeatedDeleteBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DeleteBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBlueprintRequest',
    as HashRef[DeleteBlueprintRequest()];

declare 'ListBlueprintsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintsRequest'];

coerce 'ListBlueprintsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintsRequest'->new($_) };

declare 'RepeatedListBlueprintsRequest',
    as ArrayRef[ListBlueprintsRequest()];

coerce 'RepeatedListBlueprintsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintsRequest'->new($_) } @$_ ] };

declare 'MapStringListBlueprintsRequest',
    as HashRef[ListBlueprintsRequest()];

declare 'ListBlueprintsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintsResponse'];

coerce 'ListBlueprintsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintsResponse'->new($_) };

declare 'RepeatedListBlueprintsResponse',
    as ArrayRef[ListBlueprintsResponse()];

coerce 'RepeatedListBlueprintsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintsResponse'->new($_) } @$_ ] };

declare 'MapStringListBlueprintsResponse',
    as HashRef[ListBlueprintsResponse()];

declare 'ApproveBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ApproveBlueprintRequest'];

coerce 'ApproveBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ApproveBlueprintRequest'->new($_) };

declare 'RepeatedApproveBlueprintRequest',
    as ArrayRef[ApproveBlueprintRequest()];

coerce 'RepeatedApproveBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ApproveBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringApproveBlueprintRequest',
    as HashRef[ApproveBlueprintRequest()];

declare 'ProposeBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ProposeBlueprintRequest'];

coerce 'ProposeBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ProposeBlueprintRequest'->new($_) };

declare 'RepeatedProposeBlueprintRequest',
    as ArrayRef[ProposeBlueprintRequest()];

coerce 'RepeatedProposeBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ProposeBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringProposeBlueprintRequest',
    as HashRef[ProposeBlueprintRequest()];

declare 'RejectBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::RejectBlueprintRequest'];

coerce 'RejectBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::RejectBlueprintRequest'->new($_) };

declare 'RepeatedRejectBlueprintRequest',
    as ArrayRef[RejectBlueprintRequest()];

coerce 'RepeatedRejectBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::RejectBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringRejectBlueprintRequest',
    as HashRef[RejectBlueprintRequest()];

declare 'ListBlueprintRevisionsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintRevisionsRequest'];

coerce 'ListBlueprintRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintRevisionsRequest'->new($_) };

declare 'RepeatedListBlueprintRevisionsRequest',
    as ArrayRef[ListBlueprintRevisionsRequest()];

coerce 'RepeatedListBlueprintRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListBlueprintRevisionsRequest',
    as HashRef[ListBlueprintRevisionsRequest()];

declare 'ListBlueprintRevisionsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintRevisionsResponse'];

coerce 'ListBlueprintRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintRevisionsResponse'->new($_) };

declare 'RepeatedListBlueprintRevisionsResponse',
    as ArrayRef[ListBlueprintRevisionsResponse()];

coerce 'RepeatedListBlueprintRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListBlueprintRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListBlueprintRevisionsResponse',
    as HashRef[ListBlueprintRevisionsResponse()];

declare 'SearchBlueprintRevisionsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchBlueprintRevisionsRequest'];

coerce 'SearchBlueprintRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchBlueprintRevisionsRequest'->new($_) };

declare 'RepeatedSearchBlueprintRevisionsRequest',
    as ArrayRef[SearchBlueprintRevisionsRequest()];

coerce 'RepeatedSearchBlueprintRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchBlueprintRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchBlueprintRevisionsRequest',
    as HashRef[SearchBlueprintRevisionsRequest()];

declare 'SearchBlueprintRevisionsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchBlueprintRevisionsResponse'];

coerce 'SearchBlueprintRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchBlueprintRevisionsResponse'->new($_) };

declare 'RepeatedSearchBlueprintRevisionsResponse',
    as ArrayRef[SearchBlueprintRevisionsResponse()];

coerce 'RepeatedSearchBlueprintRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchBlueprintRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchBlueprintRevisionsResponse',
    as HashRef[SearchBlueprintRevisionsResponse()];

declare 'DiscardBlueprintChangesRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardBlueprintChangesRequest'];

coerce 'DiscardBlueprintChangesRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardBlueprintChangesRequest'->new($_) };

declare 'RepeatedDiscardBlueprintChangesRequest',
    as ArrayRef[DiscardBlueprintChangesRequest()];

coerce 'RepeatedDiscardBlueprintChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardBlueprintChangesRequest'->new($_) } @$_ ] };

declare 'MapStringDiscardBlueprintChangesRequest',
    as HashRef[DiscardBlueprintChangesRequest()];

declare 'DiscardBlueprintChangesResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardBlueprintChangesResponse'];

coerce 'DiscardBlueprintChangesResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardBlueprintChangesResponse'->new($_) };

declare 'RepeatedDiscardBlueprintChangesResponse',
    as ArrayRef[DiscardBlueprintChangesResponse()];

coerce 'RepeatedDiscardBlueprintChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardBlueprintChangesResponse'->new($_) } @$_ ] };

declare 'MapStringDiscardBlueprintChangesResponse',
    as HashRef[DiscardBlueprintChangesResponse()];

declare 'ListPublicBlueprintsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListPublicBlueprintsRequest'];

coerce 'ListPublicBlueprintsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListPublicBlueprintsRequest'->new($_) };

declare 'RepeatedListPublicBlueprintsRequest',
    as ArrayRef[ListPublicBlueprintsRequest()];

coerce 'RepeatedListPublicBlueprintsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListPublicBlueprintsRequest'->new($_) } @$_ ] };

declare 'MapStringListPublicBlueprintsRequest',
    as HashRef[ListPublicBlueprintsRequest()];

declare 'ListPublicBlueprintsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListPublicBlueprintsResponse'];

coerce 'ListPublicBlueprintsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListPublicBlueprintsResponse'->new($_) };

declare 'RepeatedListPublicBlueprintsResponse',
    as ArrayRef[ListPublicBlueprintsResponse()];

coerce 'RepeatedListPublicBlueprintsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListPublicBlueprintsResponse'->new($_) } @$_ ] };

declare 'MapStringListPublicBlueprintsResponse',
    as HashRef[ListPublicBlueprintsResponse()];

declare 'GetPublicBlueprintRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::GetPublicBlueprintRequest'];

coerce 'GetPublicBlueprintRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetPublicBlueprintRequest'->new($_) };

declare 'RepeatedGetPublicBlueprintRequest',
    as ArrayRef[GetPublicBlueprintRequest()];

coerce 'RepeatedGetPublicBlueprintRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetPublicBlueprintRequest'->new($_) } @$_ ] };

declare 'MapStringGetPublicBlueprintRequest',
    as HashRef[GetPublicBlueprintRequest()];

declare 'CreateDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateDeploymentRequest'];

coerce 'CreateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateDeploymentRequest'->new($_) };

declare 'RepeatedCreateDeploymentRequest',
    as ArrayRef[CreateDeploymentRequest()];

coerce 'RepeatedCreateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::CreateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeploymentRequest',
    as HashRef[CreateDeploymentRequest()];

declare 'UpdateDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateDeploymentRequest'];

coerce 'UpdateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateDeploymentRequest'->new($_) };

declare 'RepeatedUpdateDeploymentRequest',
    as ArrayRef[UpdateDeploymentRequest()];

coerce 'RepeatedUpdateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeploymentRequest',
    as HashRef[UpdateDeploymentRequest()];

declare 'GetDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::GetDeploymentRequest'];

coerce 'GetDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetDeploymentRequest'->new($_) };

declare 'RepeatedGetDeploymentRequest',
    as ArrayRef[GetDeploymentRequest()];

coerce 'RepeatedGetDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentRequest',
    as HashRef[GetDeploymentRequest()];

declare 'RemoveDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::RemoveDeploymentRequest'];

coerce 'RemoveDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::RemoveDeploymentRequest'->new($_) };

declare 'RepeatedRemoveDeploymentRequest',
    as ArrayRef[RemoveDeploymentRequest()];

coerce 'RepeatedRemoveDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::RemoveDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveDeploymentRequest',
    as HashRef[RemoveDeploymentRequest()];

declare 'ListDeploymentsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentsRequest'];

coerce 'ListDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentsRequest'->new($_) };

declare 'RepeatedListDeploymentsRequest',
    as ArrayRef[ListDeploymentsRequest()];

coerce 'RepeatedListDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsRequest',
    as HashRef[ListDeploymentsRequest()];

declare 'ListDeploymentsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentsResponse'];

coerce 'ListDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentsResponse'->new($_) };

declare 'RepeatedListDeploymentsResponse',
    as ArrayRef[ListDeploymentsResponse()];

coerce 'RepeatedListDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsResponse',
    as HashRef[ListDeploymentsResponse()];

declare 'ListDeploymentRevisionsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentRevisionsRequest'];

coerce 'ListDeploymentRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentRevisionsRequest'->new($_) };

declare 'RepeatedListDeploymentRevisionsRequest',
    as ArrayRef[ListDeploymentRevisionsRequest()];

coerce 'RepeatedListDeploymentRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentRevisionsRequest',
    as HashRef[ListDeploymentRevisionsRequest()];

declare 'ListDeploymentRevisionsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentRevisionsResponse'];

coerce 'ListDeploymentRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentRevisionsResponse'->new($_) };

declare 'RepeatedListDeploymentRevisionsResponse',
    as ArrayRef[ListDeploymentRevisionsResponse()];

coerce 'RepeatedListDeploymentRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListDeploymentRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentRevisionsResponse',
    as HashRef[ListDeploymentRevisionsResponse()];

declare 'SearchDeploymentRevisionsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchDeploymentRevisionsRequest'];

coerce 'SearchDeploymentRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchDeploymentRevisionsRequest'->new($_) };

declare 'RepeatedSearchDeploymentRevisionsRequest',
    as ArrayRef[SearchDeploymentRevisionsRequest()];

coerce 'RepeatedSearchDeploymentRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchDeploymentRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchDeploymentRevisionsRequest',
    as HashRef[SearchDeploymentRevisionsRequest()];

declare 'SearchDeploymentRevisionsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchDeploymentRevisionsResponse'];

coerce 'SearchDeploymentRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchDeploymentRevisionsResponse'->new($_) };

declare 'RepeatedSearchDeploymentRevisionsResponse',
    as ArrayRef[SearchDeploymentRevisionsResponse()];

coerce 'RepeatedSearchDeploymentRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SearchDeploymentRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchDeploymentRevisionsResponse',
    as HashRef[SearchDeploymentRevisionsResponse()];

declare 'DiscardDeploymentChangesRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardDeploymentChangesRequest'];

coerce 'DiscardDeploymentChangesRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardDeploymentChangesRequest'->new($_) };

declare 'RepeatedDiscardDeploymentChangesRequest',
    as ArrayRef[DiscardDeploymentChangesRequest()];

coerce 'RepeatedDiscardDeploymentChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardDeploymentChangesRequest'->new($_) } @$_ ] };

declare 'MapStringDiscardDeploymentChangesRequest',
    as HashRef[DiscardDeploymentChangesRequest()];

declare 'DiscardDeploymentChangesResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardDeploymentChangesResponse'];

coerce 'DiscardDeploymentChangesResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardDeploymentChangesResponse'->new($_) };

declare 'RepeatedDiscardDeploymentChangesResponse',
    as ArrayRef[DiscardDeploymentChangesResponse()];

coerce 'RepeatedDiscardDeploymentChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::DiscardDeploymentChangesResponse'->new($_) } @$_ ] };

declare 'MapStringDiscardDeploymentChangesResponse',
    as HashRef[DiscardDeploymentChangesResponse()];

declare 'ApplyDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ApplyDeploymentRequest'];

coerce 'ApplyDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ApplyDeploymentRequest'->new($_) };

declare 'RepeatedApplyDeploymentRequest',
    as ArrayRef[ApplyDeploymentRequest()];

coerce 'RepeatedApplyDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ApplyDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringApplyDeploymentRequest',
    as HashRef[ApplyDeploymentRequest()];

declare 'ComputeDeploymentStatusRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ComputeDeploymentStatusRequest'];

coerce 'ComputeDeploymentStatusRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ComputeDeploymentStatusRequest'->new($_) };

declare 'RepeatedComputeDeploymentStatusRequest',
    as ArrayRef[ComputeDeploymentStatusRequest()];

coerce 'RepeatedComputeDeploymentStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ComputeDeploymentStatusRequest'->new($_) } @$_ ] };

declare 'MapStringComputeDeploymentStatusRequest',
    as HashRef[ComputeDeploymentStatusRequest()];

declare 'ComputeDeploymentStatusResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ComputeDeploymentStatusResponse'];

coerce 'ComputeDeploymentStatusResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ComputeDeploymentStatusResponse'->new($_) };

declare 'RepeatedComputeDeploymentStatusResponse',
    as ArrayRef[ComputeDeploymentStatusResponse()];

coerce 'RepeatedComputeDeploymentStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ComputeDeploymentStatusResponse'->new($_) } @$_ ] };

declare 'MapStringComputeDeploymentStatusResponse',
    as HashRef[ComputeDeploymentStatusResponse()];

declare 'RollbackDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::RollbackDeploymentRequest'];

coerce 'RollbackDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::RollbackDeploymentRequest'->new($_) };

declare 'RepeatedRollbackDeploymentRequest',
    as ArrayRef[RollbackDeploymentRequest()];

coerce 'RepeatedRollbackDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::RollbackDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackDeploymentRequest',
    as HashRef[RollbackDeploymentRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'GetHydratedDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::GetHydratedDeploymentRequest'];

coerce 'GetHydratedDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetHydratedDeploymentRequest'->new($_) };

declare 'RepeatedGetHydratedDeploymentRequest',
    as ArrayRef[GetHydratedDeploymentRequest()];

coerce 'RepeatedGetHydratedDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::GetHydratedDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetHydratedDeploymentRequest',
    as HashRef[GetHydratedDeploymentRequest()];

declare 'ListHydratedDeploymentsRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListHydratedDeploymentsRequest'];

coerce 'ListHydratedDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListHydratedDeploymentsRequest'->new($_) };

declare 'RepeatedListHydratedDeploymentsRequest',
    as ArrayRef[ListHydratedDeploymentsRequest()];

coerce 'RepeatedListHydratedDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListHydratedDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListHydratedDeploymentsRequest',
    as HashRef[ListHydratedDeploymentsRequest()];

declare 'ListHydratedDeploymentsResponse',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ListHydratedDeploymentsResponse'];

coerce 'ListHydratedDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListHydratedDeploymentsResponse'->new($_) };

declare 'RepeatedListHydratedDeploymentsResponse',
    as ArrayRef[ListHydratedDeploymentsResponse()];

coerce 'RepeatedListHydratedDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ListHydratedDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListHydratedDeploymentsResponse',
    as HashRef[ListHydratedDeploymentsResponse()];

declare 'UpdateHydratedDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateHydratedDeploymentRequest'];

coerce 'UpdateHydratedDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateHydratedDeploymentRequest'->new($_) };

declare 'RepeatedUpdateHydratedDeploymentRequest',
    as ArrayRef[UpdateHydratedDeploymentRequest()];

coerce 'RepeatedUpdateHydratedDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::UpdateHydratedDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHydratedDeploymentRequest',
    as HashRef[UpdateHydratedDeploymentRequest()];

declare 'ApplyHydratedDeploymentRequest',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ApplyHydratedDeploymentRequest'];

coerce 'ApplyHydratedDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ApplyHydratedDeploymentRequest'->new($_) };

declare 'RepeatedApplyHydratedDeploymentRequest',
    as ArrayRef[ApplyHydratedDeploymentRequest()];

coerce 'RepeatedApplyHydratedDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ApplyHydratedDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringApplyHydratedDeploymentRequest',
    as HashRef[ApplyHydratedDeploymentRequest()];

declare 'ManagementConfig',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ManagementConfig'];

coerce 'ManagementConfig',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ManagementConfig'->new($_) };

declare 'RepeatedManagementConfig',
    as ArrayRef[ManagementConfig()];

coerce 'RepeatedManagementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ManagementConfig'->new($_) } @$_ ] };

declare 'MapStringManagementConfig',
    as HashRef[ManagementConfig()];

declare 'StandardManagementConfig',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::StandardManagementConfig'];

coerce 'StandardManagementConfig',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::StandardManagementConfig'->new($_) };

declare 'RepeatedStandardManagementConfig',
    as ArrayRef[StandardManagementConfig()];

coerce 'RepeatedStandardManagementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::StandardManagementConfig'->new($_) } @$_ ] };

declare 'MapStringStandardManagementConfig',
    as HashRef[StandardManagementConfig()];

declare 'FullManagementConfig',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::FullManagementConfig'];

coerce 'FullManagementConfig',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::FullManagementConfig'->new($_) };

declare 'RepeatedFullManagementConfig',
    as ArrayRef[FullManagementConfig()];

coerce 'RepeatedFullManagementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::FullManagementConfig'->new($_) } @$_ ] };

declare 'MapStringFullManagementConfig',
    as HashRef[FullManagementConfig()];

declare 'MasterAuthorizedNetworksConfig',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::MasterAuthorizedNetworksConfig'];

coerce 'MasterAuthorizedNetworksConfig',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::MasterAuthorizedNetworksConfig'->new($_) };

declare 'RepeatedMasterAuthorizedNetworksConfig',
    as ArrayRef[MasterAuthorizedNetworksConfig()];

coerce 'RepeatedMasterAuthorizedNetworksConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::MasterAuthorizedNetworksConfig'->new($_) } @$_ ] };

declare 'MapStringMasterAuthorizedNetworksConfig',
    as HashRef[MasterAuthorizedNetworksConfig()];

declare 'CidrBlock',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::MasterAuthorizedNetworksConfig::CidrBlock'];

coerce 'CidrBlock',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) };

declare 'RepeatedCidrBlock',
    as ArrayRef[CidrBlock()];

coerce 'RepeatedCidrBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::MasterAuthorizedNetworksConfig::CidrBlock'->new($_) } @$_ ] };

declare 'MapStringCidrBlock',
    as HashRef[CidrBlock()];

declare 'File',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::File'];

coerce 'File',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'ResourceStatus',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::ResourceStatus'];

coerce 'ResourceStatus',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ResourceStatus'->new($_) };

declare 'RepeatedResourceStatus',
    as ArrayRef[ResourceStatus()];

coerce 'RepeatedResourceStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::ResourceStatus'->new($_) } @$_ ] };

declare 'MapStringResourceStatus',
    as HashRef[ResourceStatus()];

declare 'NFDeployStatus',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::NFDeployStatus'];

coerce 'NFDeployStatus',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::NFDeployStatus'->new($_) };

declare 'RepeatedNFDeployStatus',
    as ArrayRef[NFDeployStatus()];

coerce 'RepeatedNFDeployStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::NFDeployStatus'->new($_) } @$_ ] };

declare 'MapStringNFDeployStatus',
    as HashRef[NFDeployStatus()];

declare 'NFDeploySiteStatus',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::NFDeploySiteStatus'];

coerce 'NFDeploySiteStatus',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::NFDeploySiteStatus'->new($_) };

declare 'RepeatedNFDeploySiteStatus',
    as ArrayRef[NFDeploySiteStatus()];

coerce 'RepeatedNFDeploySiteStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::NFDeploySiteStatus'->new($_) } @$_ ] };

declare 'MapStringNFDeploySiteStatus',
    as HashRef[NFDeploySiteStatus()];

declare 'HydrationStatus',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::HydrationStatus'];

coerce 'HydrationStatus',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::HydrationStatus'->new($_) };

declare 'RepeatedHydrationStatus',
    as ArrayRef[HydrationStatus()];

coerce 'RepeatedHydrationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::HydrationStatus'->new($_) } @$_ ] };

declare 'MapStringHydrationStatus',
    as HashRef[HydrationStatus()];

declare 'SiteVersion',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::SiteVersion'];

coerce 'SiteVersion',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SiteVersion'->new($_) };

declare 'RepeatedSiteVersion',
    as ArrayRef[SiteVersion()];

coerce 'RepeatedSiteVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::SiteVersion'->new($_) } @$_ ] };

declare 'MapStringSiteVersion',
    as HashRef[SiteVersion()];

declare 'WorkloadStatus',
    as InstanceOf['Google::Cloud::Telcoautomation::V1::Telcoautomation::WorkloadStatus'];

coerce 'WorkloadStatus',
    from HashRef, via { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::WorkloadStatus'->new($_) };

declare 'RepeatedWorkloadStatus',
    as ArrayRef[WorkloadStatus()];

coerce 'RepeatedWorkloadStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Telcoautomation::V1::Telcoautomation::WorkloadStatus'->new($_) } @$_ ] };

declare 'MapStringWorkloadStatus',
    as HashRef[WorkloadStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Telcoautomation::V1::Telcoautomation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
