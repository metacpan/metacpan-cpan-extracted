package Google::Cloud::Deploy::V1::CloudDeploy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SkaffoldSupportState',
    as (Int | Str);

declare 'BackoffMode',
    as (Int | Str);

declare 'RepairState',
    as (Int | Str);

declare 'DeliveryPipeline',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline'];

coerce 'DeliveryPipeline',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline'->new($_) };

declare 'RepeatedDeliveryPipeline',
    as ArrayRef[DeliveryPipeline()];

coerce 'RepeatedDeliveryPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline'->new($_) } @$_ ] };

declare 'MapStringDeliveryPipeline',
    as HashRef[DeliveryPipeline()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipeline::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SerialPipeline',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::SerialPipeline'];

coerce 'SerialPipeline',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::SerialPipeline'->new($_) };

declare 'RepeatedSerialPipeline',
    as ArrayRef[SerialPipeline()];

coerce 'RepeatedSerialPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::SerialPipeline'->new($_) } @$_ ] };

declare 'MapStringSerialPipeline',
    as HashRef[SerialPipeline()];

declare 'Stage',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Stage'];

coerce 'Stage',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Stage'->new($_) };

declare 'RepeatedStage',
    as ArrayRef[Stage()];

coerce 'RepeatedStage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Stage'->new($_) } @$_ ] };

declare 'MapStringStage',
    as HashRef[Stage()];

declare 'DeployParameters',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters'];

coerce 'DeployParameters',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters'->new($_) };

declare 'RepeatedDeployParameters',
    as ArrayRef[DeployParameters()];

coerce 'RepeatedDeployParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters'->new($_) } @$_ ] };

declare 'MapStringDeployParameters',
    as HashRef[DeployParameters()];

declare 'ValuesEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters::ValuesEntry'];

coerce 'ValuesEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters::ValuesEntry'->new($_) };

declare 'RepeatedValuesEntry',
    as ArrayRef[ValuesEntry()];

coerce 'RepeatedValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters::ValuesEntry'->new($_) } @$_ ] };

declare 'MapStringValuesEntry',
    as HashRef[ValuesEntry()];

declare 'MatchTargetLabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters::MatchTargetLabelsEntry'];

coerce 'MatchTargetLabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters::MatchTargetLabelsEntry'->new($_) };

declare 'RepeatedMatchTargetLabelsEntry',
    as ArrayRef[MatchTargetLabelsEntry()];

coerce 'RepeatedMatchTargetLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployParameters::MatchTargetLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringMatchTargetLabelsEntry',
    as HashRef[MatchTargetLabelsEntry()];

declare 'Strategy',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Strategy'];

coerce 'Strategy',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Strategy'->new($_) };

declare 'RepeatedStrategy',
    as ArrayRef[Strategy()];

coerce 'RepeatedStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Strategy'->new($_) } @$_ ] };

declare 'MapStringStrategy',
    as HashRef[Strategy()];

declare 'Predeploy',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Predeploy'];

coerce 'Predeploy',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Predeploy'->new($_) };

declare 'RepeatedPredeploy',
    as ArrayRef[Predeploy()];

coerce 'RepeatedPredeploy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Predeploy'->new($_) } @$_ ] };

declare 'MapStringPredeploy',
    as HashRef[Predeploy()];

declare 'Postdeploy',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Postdeploy'];

coerce 'Postdeploy',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Postdeploy'->new($_) };

declare 'RepeatedPostdeploy',
    as ArrayRef[Postdeploy()];

coerce 'RepeatedPostdeploy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Postdeploy'->new($_) } @$_ ] };

declare 'MapStringPostdeploy',
    as HashRef[Postdeploy()];

declare 'Standard',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Standard'];

coerce 'Standard',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Standard'->new($_) };

declare 'RepeatedStandard',
    as ArrayRef[Standard()];

coerce 'RepeatedStandard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Standard'->new($_) } @$_ ] };

declare 'MapStringStandard',
    as HashRef[Standard()];

declare 'Canary',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Canary'];

coerce 'Canary',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Canary'->new($_) };

declare 'RepeatedCanary',
    as ArrayRef[Canary()];

coerce 'RepeatedCanary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Canary'->new($_) } @$_ ] };

declare 'MapStringCanary',
    as HashRef[Canary()];

declare 'CanaryDeployment',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CanaryDeployment'];

coerce 'CanaryDeployment',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CanaryDeployment'->new($_) };

declare 'RepeatedCanaryDeployment',
    as ArrayRef[CanaryDeployment()];

coerce 'RepeatedCanaryDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CanaryDeployment'->new($_) } @$_ ] };

declare 'MapStringCanaryDeployment',
    as HashRef[CanaryDeployment()];

declare 'CustomCanaryDeployment',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomCanaryDeployment'];

coerce 'CustomCanaryDeployment',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomCanaryDeployment'->new($_) };

declare 'RepeatedCustomCanaryDeployment',
    as ArrayRef[CustomCanaryDeployment()];

coerce 'RepeatedCustomCanaryDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomCanaryDeployment'->new($_) } @$_ ] };

declare 'MapStringCustomCanaryDeployment',
    as HashRef[CustomCanaryDeployment()];

declare 'PhaseConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomCanaryDeployment::PhaseConfig'];

coerce 'PhaseConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomCanaryDeployment::PhaseConfig'->new($_) };

declare 'RepeatedPhaseConfig',
    as ArrayRef[PhaseConfig()];

coerce 'RepeatedPhaseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomCanaryDeployment::PhaseConfig'->new($_) } @$_ ] };

declare 'MapStringPhaseConfig',
    as HashRef[PhaseConfig()];

declare 'KubernetesConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig'];

coerce 'KubernetesConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig'->new($_) };

declare 'RepeatedKubernetesConfig',
    as ArrayRef[KubernetesConfig()];

coerce 'RepeatedKubernetesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig'->new($_) } @$_ ] };

declare 'MapStringKubernetesConfig',
    as HashRef[KubernetesConfig()];

declare 'GatewayServiceMesh',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::GatewayServiceMesh'];

coerce 'GatewayServiceMesh',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::GatewayServiceMesh'->new($_) };

declare 'RepeatedGatewayServiceMesh',
    as ArrayRef[GatewayServiceMesh()];

coerce 'RepeatedGatewayServiceMesh',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::GatewayServiceMesh'->new($_) } @$_ ] };

declare 'MapStringGatewayServiceMesh',
    as HashRef[GatewayServiceMesh()];

declare 'RouteDestinations',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::GatewayServiceMesh::RouteDestinations'];

coerce 'RouteDestinations',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::GatewayServiceMesh::RouteDestinations'->new($_) };

declare 'RepeatedRouteDestinations',
    as ArrayRef[RouteDestinations()];

coerce 'RepeatedRouteDestinations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::GatewayServiceMesh::RouteDestinations'->new($_) } @$_ ] };

declare 'MapStringRouteDestinations',
    as HashRef[RouteDestinations()];

declare 'ServiceNetworking',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::ServiceNetworking'];

coerce 'ServiceNetworking',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::ServiceNetworking'->new($_) };

declare 'RepeatedServiceNetworking',
    as ArrayRef[ServiceNetworking()];

coerce 'RepeatedServiceNetworking',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::KubernetesConfig::ServiceNetworking'->new($_) } @$_ ] };

declare 'MapStringServiceNetworking',
    as HashRef[ServiceNetworking()];

declare 'CloudRunConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CloudRunConfig'];

coerce 'CloudRunConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunConfig'->new($_) };

declare 'RepeatedCloudRunConfig',
    as ArrayRef[CloudRunConfig()];

coerce 'RepeatedCloudRunConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunConfig'->new($_) } @$_ ] };

declare 'MapStringCloudRunConfig',
    as HashRef[CloudRunConfig()];

declare 'RuntimeConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RuntimeConfig'];

coerce 'RuntimeConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RuntimeConfig'->new($_) };

declare 'RepeatedRuntimeConfig',
    as ArrayRef[RuntimeConfig()];

coerce 'RepeatedRuntimeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RuntimeConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeConfig',
    as HashRef[RuntimeConfig()];

declare 'PipelineReadyCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PipelineReadyCondition'];

coerce 'PipelineReadyCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PipelineReadyCondition'->new($_) };

declare 'RepeatedPipelineReadyCondition',
    as ArrayRef[PipelineReadyCondition()];

coerce 'RepeatedPipelineReadyCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PipelineReadyCondition'->new($_) } @$_ ] };

declare 'MapStringPipelineReadyCondition',
    as HashRef[PipelineReadyCondition()];

declare 'TargetsPresentCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetsPresentCondition'];

coerce 'TargetsPresentCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetsPresentCondition'->new($_) };

declare 'RepeatedTargetsPresentCondition',
    as ArrayRef[TargetsPresentCondition()];

coerce 'RepeatedTargetsPresentCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetsPresentCondition'->new($_) } @$_ ] };

declare 'MapStringTargetsPresentCondition',
    as HashRef[TargetsPresentCondition()];

declare 'TargetsTypeCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetsTypeCondition'];

coerce 'TargetsTypeCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetsTypeCondition'->new($_) };

declare 'RepeatedTargetsTypeCondition',
    as ArrayRef[TargetsTypeCondition()];

coerce 'RepeatedTargetsTypeCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetsTypeCondition'->new($_) } @$_ ] };

declare 'MapStringTargetsTypeCondition',
    as HashRef[TargetsTypeCondition()];

declare 'PipelineCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PipelineCondition'];

coerce 'PipelineCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PipelineCondition'->new($_) };

declare 'RepeatedPipelineCondition',
    as ArrayRef[PipelineCondition()];

coerce 'RepeatedPipelineCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PipelineCondition'->new($_) } @$_ ] };

declare 'MapStringPipelineCondition',
    as HashRef[PipelineCondition()];

declare 'ListDeliveryPipelinesRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListDeliveryPipelinesRequest'];

coerce 'ListDeliveryPipelinesRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeliveryPipelinesRequest'->new($_) };

declare 'RepeatedListDeliveryPipelinesRequest',
    as ArrayRef[ListDeliveryPipelinesRequest()];

coerce 'RepeatedListDeliveryPipelinesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeliveryPipelinesRequest'->new($_) } @$_ ] };

declare 'MapStringListDeliveryPipelinesRequest',
    as HashRef[ListDeliveryPipelinesRequest()];

declare 'ListDeliveryPipelinesResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListDeliveryPipelinesResponse'];

coerce 'ListDeliveryPipelinesResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeliveryPipelinesResponse'->new($_) };

declare 'RepeatedListDeliveryPipelinesResponse',
    as ArrayRef[ListDeliveryPipelinesResponse()];

coerce 'RepeatedListDeliveryPipelinesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeliveryPipelinesResponse'->new($_) } @$_ ] };

declare 'MapStringListDeliveryPipelinesResponse',
    as HashRef[ListDeliveryPipelinesResponse()];

declare 'GetDeliveryPipelineRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetDeliveryPipelineRequest'];

coerce 'GetDeliveryPipelineRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetDeliveryPipelineRequest'->new($_) };

declare 'RepeatedGetDeliveryPipelineRequest',
    as ArrayRef[GetDeliveryPipelineRequest()];

coerce 'RepeatedGetDeliveryPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetDeliveryPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeliveryPipelineRequest',
    as HashRef[GetDeliveryPipelineRequest()];

declare 'CreateDeliveryPipelineRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateDeliveryPipelineRequest'];

coerce 'CreateDeliveryPipelineRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateDeliveryPipelineRequest'->new($_) };

declare 'RepeatedCreateDeliveryPipelineRequest',
    as ArrayRef[CreateDeliveryPipelineRequest()];

coerce 'RepeatedCreateDeliveryPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateDeliveryPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeliveryPipelineRequest',
    as HashRef[CreateDeliveryPipelineRequest()];

declare 'UpdateDeliveryPipelineRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::UpdateDeliveryPipelineRequest'];

coerce 'UpdateDeliveryPipelineRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateDeliveryPipelineRequest'->new($_) };

declare 'RepeatedUpdateDeliveryPipelineRequest',
    as ArrayRef[UpdateDeliveryPipelineRequest()];

coerce 'RepeatedUpdateDeliveryPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateDeliveryPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeliveryPipelineRequest',
    as HashRef[UpdateDeliveryPipelineRequest()];

declare 'DeleteDeliveryPipelineRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeleteDeliveryPipelineRequest'];

coerce 'DeleteDeliveryPipelineRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteDeliveryPipelineRequest'->new($_) };

declare 'RepeatedDeleteDeliveryPipelineRequest',
    as ArrayRef[DeleteDeliveryPipelineRequest()];

coerce 'RepeatedDeleteDeliveryPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteDeliveryPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeliveryPipelineRequest',
    as HashRef[DeleteDeliveryPipelineRequest()];

declare 'RollbackTargetConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetConfig'];

coerce 'RollbackTargetConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetConfig'->new($_) };

declare 'RepeatedRollbackTargetConfig',
    as ArrayRef[RollbackTargetConfig()];

coerce 'RepeatedRollbackTargetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetConfig'->new($_) } @$_ ] };

declare 'MapStringRollbackTargetConfig',
    as HashRef[RollbackTargetConfig()];

declare 'RollbackTargetRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetRequest'];

coerce 'RollbackTargetRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetRequest'->new($_) };

declare 'RepeatedRollbackTargetRequest',
    as ArrayRef[RollbackTargetRequest()];

coerce 'RepeatedRollbackTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackTargetRequest',
    as HashRef[RollbackTargetRequest()];

declare 'RollbackTargetResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetResponse'];

coerce 'RollbackTargetResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetResponse'->new($_) };

declare 'RepeatedRollbackTargetResponse',
    as ArrayRef[RollbackTargetResponse()];

coerce 'RepeatedRollbackTargetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackTargetResponse'->new($_) } @$_ ] };

declare 'MapStringRollbackTargetResponse',
    as HashRef[RollbackTargetResponse()];

declare 'Target',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Target::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Target::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AssociatedEntitiesEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Target::AssociatedEntitiesEntry'];

coerce 'AssociatedEntitiesEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::AssociatedEntitiesEntry'->new($_) };

declare 'RepeatedAssociatedEntitiesEntry',
    as ArrayRef[AssociatedEntitiesEntry()];

coerce 'RepeatedAssociatedEntitiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::AssociatedEntitiesEntry'->new($_) } @$_ ] };

declare 'MapStringAssociatedEntitiesEntry',
    as HashRef[AssociatedEntitiesEntry()];

declare 'DeployParametersEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Target::DeployParametersEntry'];

coerce 'DeployParametersEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::DeployParametersEntry'->new($_) };

declare 'RepeatedDeployParametersEntry',
    as ArrayRef[DeployParametersEntry()];

coerce 'RepeatedDeployParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Target::DeployParametersEntry'->new($_) } @$_ ] };

declare 'MapStringDeployParametersEntry',
    as HashRef[DeployParametersEntry()];

declare 'ExecutionConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ExecutionConfig'];

coerce 'ExecutionConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ExecutionConfig'->new($_) };

declare 'RepeatedExecutionConfig',
    as ArrayRef[ExecutionConfig()];

coerce 'RepeatedExecutionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ExecutionConfig'->new($_) } @$_ ] };

declare 'MapStringExecutionConfig',
    as HashRef[ExecutionConfig()];

declare 'ExecutionEnvironmentUsage',
    as (Int | Str);

declare 'DefaultPool',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DefaultPool'];

coerce 'DefaultPool',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DefaultPool'->new($_) };

declare 'RepeatedDefaultPool',
    as ArrayRef[DefaultPool()];

coerce 'RepeatedDefaultPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DefaultPool'->new($_) } @$_ ] };

declare 'MapStringDefaultPool',
    as HashRef[DefaultPool()];

declare 'PrivatePool',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PrivatePool'];

coerce 'PrivatePool',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PrivatePool'->new($_) };

declare 'RepeatedPrivatePool',
    as ArrayRef[PrivatePool()];

coerce 'RepeatedPrivatePool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PrivatePool'->new($_) } @$_ ] };

declare 'MapStringPrivatePool',
    as HashRef[PrivatePool()];

declare 'GkeCluster',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GkeCluster'];

coerce 'GkeCluster',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GkeCluster'->new($_) };

declare 'RepeatedGkeCluster',
    as ArrayRef[GkeCluster()];

coerce 'RepeatedGkeCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GkeCluster'->new($_) } @$_ ] };

declare 'MapStringGkeCluster',
    as HashRef[GkeCluster()];

declare 'AnthosCluster',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AnthosCluster'];

coerce 'AnthosCluster',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AnthosCluster'->new($_) };

declare 'RepeatedAnthosCluster',
    as ArrayRef[AnthosCluster()];

coerce 'RepeatedAnthosCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AnthosCluster'->new($_) } @$_ ] };

declare 'MapStringAnthosCluster',
    as HashRef[AnthosCluster()];

declare 'CloudRunLocation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CloudRunLocation'];

coerce 'CloudRunLocation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunLocation'->new($_) };

declare 'RepeatedCloudRunLocation',
    as ArrayRef[CloudRunLocation()];

coerce 'RepeatedCloudRunLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunLocation'->new($_) } @$_ ] };

declare 'MapStringCloudRunLocation',
    as HashRef[CloudRunLocation()];

declare 'MultiTarget',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::MultiTarget'];

coerce 'MultiTarget',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::MultiTarget'->new($_) };

declare 'RepeatedMultiTarget',
    as ArrayRef[MultiTarget()];

coerce 'RepeatedMultiTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::MultiTarget'->new($_) } @$_ ] };

declare 'MapStringMultiTarget',
    as HashRef[MultiTarget()];

declare 'CustomTarget',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomTarget'];

coerce 'CustomTarget',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTarget'->new($_) };

declare 'RepeatedCustomTarget',
    as ArrayRef[CustomTarget()];

coerce 'RepeatedCustomTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTarget'->new($_) } @$_ ] };

declare 'MapStringCustomTarget',
    as HashRef[CustomTarget()];

declare 'AssociatedEntities',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AssociatedEntities'];

coerce 'AssociatedEntities',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AssociatedEntities'->new($_) };

declare 'RepeatedAssociatedEntities',
    as ArrayRef[AssociatedEntities()];

coerce 'RepeatedAssociatedEntities',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AssociatedEntities'->new($_) } @$_ ] };

declare 'MapStringAssociatedEntities',
    as HashRef[AssociatedEntities()];

declare 'ListTargetsRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListTargetsRequest'];

coerce 'ListTargetsRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListTargetsRequest'->new($_) };

declare 'RepeatedListTargetsRequest',
    as ArrayRef[ListTargetsRequest()];

coerce 'RepeatedListTargetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListTargetsRequest'->new($_) } @$_ ] };

declare 'MapStringListTargetsRequest',
    as HashRef[ListTargetsRequest()];

declare 'ListTargetsResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListTargetsResponse'];

coerce 'ListTargetsResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListTargetsResponse'->new($_) };

declare 'RepeatedListTargetsResponse',
    as ArrayRef[ListTargetsResponse()];

coerce 'RepeatedListTargetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListTargetsResponse'->new($_) } @$_ ] };

declare 'MapStringListTargetsResponse',
    as HashRef[ListTargetsResponse()];

declare 'GetTargetRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetTargetRequest'];

coerce 'GetTargetRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetTargetRequest'->new($_) };

declare 'RepeatedGetTargetRequest',
    as ArrayRef[GetTargetRequest()];

coerce 'RepeatedGetTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetTargetRequest'->new($_) } @$_ ] };

declare 'MapStringGetTargetRequest',
    as HashRef[GetTargetRequest()];

declare 'CreateTargetRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateTargetRequest'];

coerce 'CreateTargetRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateTargetRequest'->new($_) };

declare 'RepeatedCreateTargetRequest',
    as ArrayRef[CreateTargetRequest()];

coerce 'RepeatedCreateTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateTargetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTargetRequest',
    as HashRef[CreateTargetRequest()];

declare 'UpdateTargetRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::UpdateTargetRequest'];

coerce 'UpdateTargetRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateTargetRequest'->new($_) };

declare 'RepeatedUpdateTargetRequest',
    as ArrayRef[UpdateTargetRequest()];

coerce 'RepeatedUpdateTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateTargetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTargetRequest',
    as HashRef[UpdateTargetRequest()];

declare 'DeleteTargetRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeleteTargetRequest'];

coerce 'DeleteTargetRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteTargetRequest'->new($_) };

declare 'RepeatedDeleteTargetRequest',
    as ArrayRef[DeleteTargetRequest()];

coerce 'RepeatedDeleteTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteTargetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTargetRequest',
    as HashRef[DeleteTargetRequest()];

declare 'CustomTargetType',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType'];

coerce 'CustomTargetType',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType'->new($_) };

declare 'RepeatedCustomTargetType',
    as ArrayRef[CustomTargetType()];

coerce 'RepeatedCustomTargetType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType'->new($_) } @$_ ] };

declare 'MapStringCustomTargetType',
    as HashRef[CustomTargetType()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetType::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CustomTargetSkaffoldActions',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetSkaffoldActions'];

coerce 'CustomTargetSkaffoldActions',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetSkaffoldActions'->new($_) };

declare 'RepeatedCustomTargetSkaffoldActions',
    as ArrayRef[CustomTargetSkaffoldActions()];

coerce 'RepeatedCustomTargetSkaffoldActions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetSkaffoldActions'->new($_) } @$_ ] };

declare 'MapStringCustomTargetSkaffoldActions',
    as HashRef[CustomTargetSkaffoldActions()];

declare 'SkaffoldModules',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules'];

coerce 'SkaffoldModules',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules'->new($_) };

declare 'RepeatedSkaffoldModules',
    as ArrayRef[SkaffoldModules()];

coerce 'RepeatedSkaffoldModules',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules'->new($_) } @$_ ] };

declare 'MapStringSkaffoldModules',
    as HashRef[SkaffoldModules()];

declare 'SkaffoldGitSource',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGitSource'];

coerce 'SkaffoldGitSource',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGitSource'->new($_) };

declare 'RepeatedSkaffoldGitSource',
    as ArrayRef[SkaffoldGitSource()];

coerce 'RepeatedSkaffoldGitSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGitSource'->new($_) } @$_ ] };

declare 'MapStringSkaffoldGitSource',
    as HashRef[SkaffoldGitSource()];

declare 'SkaffoldGCSSource',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGCSSource'];

coerce 'SkaffoldGCSSource',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGCSSource'->new($_) };

declare 'RepeatedSkaffoldGCSSource',
    as ArrayRef[SkaffoldGCSSource()];

coerce 'RepeatedSkaffoldGCSSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGCSSource'->new($_) } @$_ ] };

declare 'MapStringSkaffoldGCSSource',
    as HashRef[SkaffoldGCSSource()];

declare 'SkaffoldGCBRepoSource',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGCBRepoSource'];

coerce 'SkaffoldGCBRepoSource',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGCBRepoSource'->new($_) };

declare 'RepeatedSkaffoldGCBRepoSource',
    as ArrayRef[SkaffoldGCBRepoSource()];

coerce 'RepeatedSkaffoldGCBRepoSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldModules::SkaffoldGCBRepoSource'->new($_) } @$_ ] };

declare 'MapStringSkaffoldGCBRepoSource',
    as HashRef[SkaffoldGCBRepoSource()];

declare 'ListCustomTargetTypesRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListCustomTargetTypesRequest'];

coerce 'ListCustomTargetTypesRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListCustomTargetTypesRequest'->new($_) };

declare 'RepeatedListCustomTargetTypesRequest',
    as ArrayRef[ListCustomTargetTypesRequest()];

coerce 'RepeatedListCustomTargetTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListCustomTargetTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomTargetTypesRequest',
    as HashRef[ListCustomTargetTypesRequest()];

declare 'ListCustomTargetTypesResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListCustomTargetTypesResponse'];

coerce 'ListCustomTargetTypesResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListCustomTargetTypesResponse'->new($_) };

declare 'RepeatedListCustomTargetTypesResponse',
    as ArrayRef[ListCustomTargetTypesResponse()];

coerce 'RepeatedListCustomTargetTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListCustomTargetTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomTargetTypesResponse',
    as HashRef[ListCustomTargetTypesResponse()];

declare 'GetCustomTargetTypeRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetCustomTargetTypeRequest'];

coerce 'GetCustomTargetTypeRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetCustomTargetTypeRequest'->new($_) };

declare 'RepeatedGetCustomTargetTypeRequest',
    as ArrayRef[GetCustomTargetTypeRequest()];

coerce 'RepeatedGetCustomTargetTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetCustomTargetTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomTargetTypeRequest',
    as HashRef[GetCustomTargetTypeRequest()];

declare 'CreateCustomTargetTypeRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateCustomTargetTypeRequest'];

coerce 'CreateCustomTargetTypeRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateCustomTargetTypeRequest'->new($_) };

declare 'RepeatedCreateCustomTargetTypeRequest',
    as ArrayRef[CreateCustomTargetTypeRequest()];

coerce 'RepeatedCreateCustomTargetTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateCustomTargetTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomTargetTypeRequest',
    as HashRef[CreateCustomTargetTypeRequest()];

declare 'UpdateCustomTargetTypeRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::UpdateCustomTargetTypeRequest'];

coerce 'UpdateCustomTargetTypeRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateCustomTargetTypeRequest'->new($_) };

declare 'RepeatedUpdateCustomTargetTypeRequest',
    as ArrayRef[UpdateCustomTargetTypeRequest()];

coerce 'RepeatedUpdateCustomTargetTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateCustomTargetTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomTargetTypeRequest',
    as HashRef[UpdateCustomTargetTypeRequest()];

declare 'DeleteCustomTargetTypeRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeleteCustomTargetTypeRequest'];

coerce 'DeleteCustomTargetTypeRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteCustomTargetTypeRequest'->new($_) };

declare 'RepeatedDeleteCustomTargetTypeRequest',
    as ArrayRef[DeleteCustomTargetTypeRequest()];

coerce 'RepeatedDeleteCustomTargetTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteCustomTargetTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomTargetTypeRequest',
    as HashRef[DeleteCustomTargetTypeRequest()];

declare 'DeployPolicy',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy'];

coerce 'DeployPolicy',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy'->new($_) };

declare 'RepeatedDeployPolicy',
    as ArrayRef[DeployPolicy()];

coerce 'RepeatedDeployPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy'->new($_) } @$_ ] };

declare 'MapStringDeployPolicy',
    as HashRef[DeployPolicy()];

declare 'Invoker',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DeployPolicyResourceSelector',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicyResourceSelector'];

coerce 'DeployPolicyResourceSelector',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicyResourceSelector'->new($_) };

declare 'RepeatedDeployPolicyResourceSelector',
    as ArrayRef[DeployPolicyResourceSelector()];

coerce 'RepeatedDeployPolicyResourceSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployPolicyResourceSelector'->new($_) } @$_ ] };

declare 'MapStringDeployPolicyResourceSelector',
    as HashRef[DeployPolicyResourceSelector()];

declare 'DeliveryPipelineAttribute',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipelineAttribute'];

coerce 'DeliveryPipelineAttribute',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipelineAttribute'->new($_) };

declare 'RepeatedDeliveryPipelineAttribute',
    as ArrayRef[DeliveryPipelineAttribute()];

coerce 'RepeatedDeliveryPipelineAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipelineAttribute'->new($_) } @$_ ] };

declare 'MapStringDeliveryPipelineAttribute',
    as HashRef[DeliveryPipelineAttribute()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipelineAttribute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipelineAttribute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeliveryPipelineAttribute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TargetAttribute',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetAttribute'];

coerce 'TargetAttribute',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetAttribute'->new($_) };

declare 'RepeatedTargetAttribute',
    as ArrayRef[TargetAttribute()];

coerce 'RepeatedTargetAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetAttribute'->new($_) } @$_ ] };

declare 'MapStringTargetAttribute',
    as HashRef[TargetAttribute()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetAttribute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetAttribute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetAttribute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PolicyRule',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PolicyRule'];

coerce 'PolicyRule',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PolicyRule'->new($_) };

declare 'RepeatedPolicyRule',
    as ArrayRef[PolicyRule()];

coerce 'RepeatedPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PolicyRule'->new($_) } @$_ ] };

declare 'MapStringPolicyRule',
    as HashRef[PolicyRule()];

declare 'RolloutRestriction',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RolloutRestriction'];

coerce 'RolloutRestriction',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RolloutRestriction'->new($_) };

declare 'RepeatedRolloutRestriction',
    as ArrayRef[RolloutRestriction()];

coerce 'RepeatedRolloutRestriction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RolloutRestriction'->new($_) } @$_ ] };

declare 'MapStringRolloutRestriction',
    as HashRef[RolloutRestriction()];

declare 'RolloutActions',
    as (Int | Str);

declare 'TimeWindows',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TimeWindows'];

coerce 'TimeWindows',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TimeWindows'->new($_) };

declare 'RepeatedTimeWindows',
    as ArrayRef[TimeWindows()];

coerce 'RepeatedTimeWindows',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TimeWindows'->new($_) } @$_ ] };

declare 'MapStringTimeWindows',
    as HashRef[TimeWindows()];

declare 'OneTimeWindow',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::OneTimeWindow'];

coerce 'OneTimeWindow',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::OneTimeWindow'->new($_) };

declare 'RepeatedOneTimeWindow',
    as ArrayRef[OneTimeWindow()];

coerce 'RepeatedOneTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::OneTimeWindow'->new($_) } @$_ ] };

declare 'MapStringOneTimeWindow',
    as HashRef[OneTimeWindow()];

declare 'WeeklyWindow',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::WeeklyWindow'];

coerce 'WeeklyWindow',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::WeeklyWindow'->new($_) };

declare 'RepeatedWeeklyWindow',
    as ArrayRef[WeeklyWindow()];

coerce 'RepeatedWeeklyWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::WeeklyWindow'->new($_) } @$_ ] };

declare 'MapStringWeeklyWindow',
    as HashRef[WeeklyWindow()];

declare 'PolicyViolation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PolicyViolation'];

coerce 'PolicyViolation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PolicyViolation'->new($_) };

declare 'RepeatedPolicyViolation',
    as ArrayRef[PolicyViolation()];

coerce 'RepeatedPolicyViolation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PolicyViolation'->new($_) } @$_ ] };

declare 'MapStringPolicyViolation',
    as HashRef[PolicyViolation()];

declare 'PolicyViolationDetails',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PolicyViolationDetails'];

coerce 'PolicyViolationDetails',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PolicyViolationDetails'->new($_) };

declare 'RepeatedPolicyViolationDetails',
    as ArrayRef[PolicyViolationDetails()];

coerce 'RepeatedPolicyViolationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PolicyViolationDetails'->new($_) } @$_ ] };

declare 'MapStringPolicyViolationDetails',
    as HashRef[PolicyViolationDetails()];

declare 'Release',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release'];

coerce 'Release',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release'->new($_) };

declare 'RepeatedRelease',
    as ArrayRef[Release()];

coerce 'RepeatedRelease',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release'->new($_) } @$_ ] };

declare 'MapStringRelease',
    as HashRef[Release()];

declare 'RenderState',
    as (Int | Str);

declare 'TargetRender',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetRender'];

coerce 'TargetRender',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetRender'->new($_) };

declare 'RepeatedTargetRender',
    as ArrayRef[TargetRender()];

coerce 'RepeatedTargetRender',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetRender'->new($_) } @$_ ] };

declare 'MapStringTargetRender',
    as HashRef[TargetRender()];

declare 'TargetRenderState',
    as (Int | Str);

declare 'FailureCause',
    as (Int | Str);

declare 'ReleaseReadyCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::ReleaseReadyCondition'];

coerce 'ReleaseReadyCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::ReleaseReadyCondition'->new($_) };

declare 'RepeatedReleaseReadyCondition',
    as ArrayRef[ReleaseReadyCondition()];

coerce 'RepeatedReleaseReadyCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::ReleaseReadyCondition'->new($_) } @$_ ] };

declare 'MapStringReleaseReadyCondition',
    as HashRef[ReleaseReadyCondition()];

declare 'SkaffoldSupportedCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::SkaffoldSupportedCondition'];

coerce 'SkaffoldSupportedCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::SkaffoldSupportedCondition'->new($_) };

declare 'RepeatedSkaffoldSupportedCondition',
    as ArrayRef[SkaffoldSupportedCondition()];

coerce 'RepeatedSkaffoldSupportedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::SkaffoldSupportedCondition'->new($_) } @$_ ] };

declare 'MapStringSkaffoldSupportedCondition',
    as HashRef[SkaffoldSupportedCondition()];

declare 'ReleaseCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::ReleaseCondition'];

coerce 'ReleaseCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::ReleaseCondition'->new($_) };

declare 'RepeatedReleaseCondition',
    as ArrayRef[ReleaseCondition()];

coerce 'RepeatedReleaseCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::ReleaseCondition'->new($_) } @$_ ] };

declare 'MapStringReleaseCondition',
    as HashRef[ReleaseCondition()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TargetArtifactsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetArtifactsEntry'];

coerce 'TargetArtifactsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetArtifactsEntry'->new($_) };

declare 'RepeatedTargetArtifactsEntry',
    as ArrayRef[TargetArtifactsEntry()];

coerce 'RepeatedTargetArtifactsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetArtifactsEntry'->new($_) } @$_ ] };

declare 'MapStringTargetArtifactsEntry',
    as HashRef[TargetArtifactsEntry()];

declare 'TargetRendersEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetRendersEntry'];

coerce 'TargetRendersEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetRendersEntry'->new($_) };

declare 'RepeatedTargetRendersEntry',
    as ArrayRef[TargetRendersEntry()];

coerce 'RepeatedTargetRendersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::TargetRendersEntry'->new($_) } @$_ ] };

declare 'MapStringTargetRendersEntry',
    as HashRef[TargetRendersEntry()];

declare 'DeployParametersEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Release::DeployParametersEntry'];

coerce 'DeployParametersEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::DeployParametersEntry'->new($_) };

declare 'RepeatedDeployParametersEntry',
    as ArrayRef[DeployParametersEntry()];

coerce 'RepeatedDeployParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Release::DeployParametersEntry'->new($_) } @$_ ] };

declare 'MapStringDeployParametersEntry',
    as HashRef[DeployParametersEntry()];

declare 'CreateDeployPolicyRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateDeployPolicyRequest'];

coerce 'CreateDeployPolicyRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateDeployPolicyRequest'->new($_) };

declare 'RepeatedCreateDeployPolicyRequest',
    as ArrayRef[CreateDeployPolicyRequest()];

coerce 'RepeatedCreateDeployPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateDeployPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeployPolicyRequest',
    as HashRef[CreateDeployPolicyRequest()];

declare 'UpdateDeployPolicyRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::UpdateDeployPolicyRequest'];

coerce 'UpdateDeployPolicyRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateDeployPolicyRequest'->new($_) };

declare 'RepeatedUpdateDeployPolicyRequest',
    as ArrayRef[UpdateDeployPolicyRequest()];

coerce 'RepeatedUpdateDeployPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateDeployPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeployPolicyRequest',
    as HashRef[UpdateDeployPolicyRequest()];

declare 'DeleteDeployPolicyRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeleteDeployPolicyRequest'];

coerce 'DeleteDeployPolicyRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteDeployPolicyRequest'->new($_) };

declare 'RepeatedDeleteDeployPolicyRequest',
    as ArrayRef[DeleteDeployPolicyRequest()];

coerce 'RepeatedDeleteDeployPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteDeployPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeployPolicyRequest',
    as HashRef[DeleteDeployPolicyRequest()];

declare 'ListDeployPoliciesRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListDeployPoliciesRequest'];

coerce 'ListDeployPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeployPoliciesRequest'->new($_) };

declare 'RepeatedListDeployPoliciesRequest',
    as ArrayRef[ListDeployPoliciesRequest()];

coerce 'RepeatedListDeployPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeployPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListDeployPoliciesRequest',
    as HashRef[ListDeployPoliciesRequest()];

declare 'ListDeployPoliciesResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListDeployPoliciesResponse'];

coerce 'ListDeployPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeployPoliciesResponse'->new($_) };

declare 'RepeatedListDeployPoliciesResponse',
    as ArrayRef[ListDeployPoliciesResponse()];

coerce 'RepeatedListDeployPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListDeployPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListDeployPoliciesResponse',
    as HashRef[ListDeployPoliciesResponse()];

declare 'GetDeployPolicyRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetDeployPolicyRequest'];

coerce 'GetDeployPolicyRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetDeployPolicyRequest'->new($_) };

declare 'RepeatedGetDeployPolicyRequest',
    as ArrayRef[GetDeployPolicyRequest()];

coerce 'RepeatedGetDeployPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetDeployPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeployPolicyRequest',
    as HashRef[GetDeployPolicyRequest()];

declare 'BuildArtifact',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::BuildArtifact'];

coerce 'BuildArtifact',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::BuildArtifact'->new($_) };

declare 'RepeatedBuildArtifact',
    as ArrayRef[BuildArtifact()];

coerce 'RepeatedBuildArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::BuildArtifact'->new($_) } @$_ ] };

declare 'MapStringBuildArtifact',
    as HashRef[BuildArtifact()];

declare 'TargetArtifact',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact'];

coerce 'TargetArtifact',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact'->new($_) };

declare 'RepeatedTargetArtifact',
    as ArrayRef[TargetArtifact()];

coerce 'RepeatedTargetArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact'->new($_) } @$_ ] };

declare 'MapStringTargetArtifact',
    as HashRef[TargetArtifact()];

declare 'PhaseArtifact',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact::PhaseArtifact'];

coerce 'PhaseArtifact',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact::PhaseArtifact'->new($_) };

declare 'RepeatedPhaseArtifact',
    as ArrayRef[PhaseArtifact()];

coerce 'RepeatedPhaseArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact::PhaseArtifact'->new($_) } @$_ ] };

declare 'MapStringPhaseArtifact',
    as HashRef[PhaseArtifact()];

declare 'PhaseArtifactsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact::PhaseArtifactsEntry'];

coerce 'PhaseArtifactsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact::PhaseArtifactsEntry'->new($_) };

declare 'RepeatedPhaseArtifactsEntry',
    as ArrayRef[PhaseArtifactsEntry()];

coerce 'RepeatedPhaseArtifactsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TargetArtifact::PhaseArtifactsEntry'->new($_) } @$_ ] };

declare 'MapStringPhaseArtifactsEntry',
    as HashRef[PhaseArtifactsEntry()];

declare 'DeployArtifact',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployArtifact'];

coerce 'DeployArtifact',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployArtifact'->new($_) };

declare 'RepeatedDeployArtifact',
    as ArrayRef[DeployArtifact()];

coerce 'RepeatedDeployArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployArtifact'->new($_) } @$_ ] };

declare 'MapStringDeployArtifact',
    as HashRef[DeployArtifact()];

declare 'CloudRunRenderMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CloudRunRenderMetadata'];

coerce 'CloudRunRenderMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunRenderMetadata'->new($_) };

declare 'RepeatedCloudRunRenderMetadata',
    as ArrayRef[CloudRunRenderMetadata()];

coerce 'RepeatedCloudRunRenderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunRenderMetadata'->new($_) } @$_ ] };

declare 'MapStringCloudRunRenderMetadata',
    as HashRef[CloudRunRenderMetadata()];

declare 'RenderMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RenderMetadata'];

coerce 'RenderMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RenderMetadata'->new($_) };

declare 'RepeatedRenderMetadata',
    as ArrayRef[RenderMetadata()];

coerce 'RepeatedRenderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RenderMetadata'->new($_) } @$_ ] };

declare 'MapStringRenderMetadata',
    as HashRef[RenderMetadata()];

declare 'ListReleasesRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListReleasesRequest'];

coerce 'ListReleasesRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListReleasesRequest'->new($_) };

declare 'RepeatedListReleasesRequest',
    as ArrayRef[ListReleasesRequest()];

coerce 'RepeatedListReleasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListReleasesRequest'->new($_) } @$_ ] };

declare 'MapStringListReleasesRequest',
    as HashRef[ListReleasesRequest()];

declare 'ListReleasesResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListReleasesResponse'];

coerce 'ListReleasesResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListReleasesResponse'->new($_) };

declare 'RepeatedListReleasesResponse',
    as ArrayRef[ListReleasesResponse()];

coerce 'RepeatedListReleasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListReleasesResponse'->new($_) } @$_ ] };

declare 'MapStringListReleasesResponse',
    as HashRef[ListReleasesResponse()];

declare 'GetReleaseRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetReleaseRequest'];

coerce 'GetReleaseRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetReleaseRequest'->new($_) };

declare 'RepeatedGetReleaseRequest',
    as ArrayRef[GetReleaseRequest()];

coerce 'RepeatedGetReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetReleaseRequest',
    as HashRef[GetReleaseRequest()];

declare 'CreateReleaseRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateReleaseRequest'];

coerce 'CreateReleaseRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateReleaseRequest'->new($_) };

declare 'RepeatedCreateReleaseRequest',
    as ArrayRef[CreateReleaseRequest()];

coerce 'RepeatedCreateReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReleaseRequest',
    as HashRef[CreateReleaseRequest()];

declare 'Rollout',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Rollout'];

coerce 'Rollout',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollout'->new($_) };

declare 'RepeatedRollout',
    as ArrayRef[Rollout()];

coerce 'RepeatedRollout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollout'->new($_) } @$_ ] };

declare 'MapStringRollout',
    as HashRef[Rollout()];

declare 'ApprovalState',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'FailureCause',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Rollout::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollout::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollout::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Rollout::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollout::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollout::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Metadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'DeployJobRunMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployJobRunMetadata'];

coerce 'DeployJobRunMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployJobRunMetadata'->new($_) };

declare 'RepeatedDeployJobRunMetadata',
    as ArrayRef[DeployJobRunMetadata()];

coerce 'RepeatedDeployJobRunMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployJobRunMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployJobRunMetadata',
    as HashRef[DeployJobRunMetadata()];

declare 'CloudRunMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CloudRunMetadata'];

coerce 'CloudRunMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunMetadata'->new($_) };

declare 'RepeatedCloudRunMetadata',
    as ArrayRef[CloudRunMetadata()];

coerce 'RepeatedCloudRunMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CloudRunMetadata'->new($_) } @$_ ] };

declare 'MapStringCloudRunMetadata',
    as HashRef[CloudRunMetadata()];

declare 'CustomTargetDeployMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetDeployMetadata'];

coerce 'CustomTargetDeployMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetDeployMetadata'->new($_) };

declare 'RepeatedCustomTargetDeployMetadata',
    as ArrayRef[CustomTargetDeployMetadata()];

coerce 'RepeatedCustomTargetDeployMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomTargetDeployMetadata'->new($_) } @$_ ] };

declare 'MapStringCustomTargetDeployMetadata',
    as HashRef[CustomTargetDeployMetadata()];

declare 'AutomationRolloutMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AutomationRolloutMetadata'];

coerce 'AutomationRolloutMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRolloutMetadata'->new($_) };

declare 'RepeatedAutomationRolloutMetadata',
    as ArrayRef[AutomationRolloutMetadata()];

coerce 'RepeatedAutomationRolloutMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRolloutMetadata'->new($_) } @$_ ] };

declare 'MapStringAutomationRolloutMetadata',
    as HashRef[AutomationRolloutMetadata()];

declare 'CustomMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomMetadata'];

coerce 'CustomMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomMetadata'->new($_) };

declare 'RepeatedCustomMetadata',
    as ArrayRef[CustomMetadata()];

coerce 'RepeatedCustomMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomMetadata'->new($_) } @$_ ] };

declare 'MapStringCustomMetadata',
    as HashRef[CustomMetadata()];

declare 'ValuesEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CustomMetadata::ValuesEntry'];

coerce 'ValuesEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomMetadata::ValuesEntry'->new($_) };

declare 'RepeatedValuesEntry',
    as ArrayRef[ValuesEntry()];

coerce 'RepeatedValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CustomMetadata::ValuesEntry'->new($_) } @$_ ] };

declare 'MapStringValuesEntry',
    as HashRef[ValuesEntry()];

declare 'Phase',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Phase'];

coerce 'Phase',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Phase'->new($_) };

declare 'RepeatedPhase',
    as ArrayRef[Phase()];

coerce 'RepeatedPhase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Phase'->new($_) } @$_ ] };

declare 'MapStringPhase',
    as HashRef[Phase()];

declare 'State',
    as (Int | Str);

declare 'DeploymentJobs',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeploymentJobs'];

coerce 'DeploymentJobs',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeploymentJobs'->new($_) };

declare 'RepeatedDeploymentJobs',
    as ArrayRef[DeploymentJobs()];

coerce 'RepeatedDeploymentJobs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeploymentJobs'->new($_) } @$_ ] };

declare 'MapStringDeploymentJobs',
    as HashRef[DeploymentJobs()];

declare 'ChildRolloutJobs',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ChildRolloutJobs'];

coerce 'ChildRolloutJobs',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ChildRolloutJobs'->new($_) };

declare 'RepeatedChildRolloutJobs',
    as ArrayRef[ChildRolloutJobs()];

coerce 'RepeatedChildRolloutJobs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ChildRolloutJobs'->new($_) } @$_ ] };

declare 'MapStringChildRolloutJobs',
    as HashRef[ChildRolloutJobs()];

declare 'Job',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'State',
    as (Int | Str);

declare 'DeployJob',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployJob'];

coerce 'DeployJob',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployJob'->new($_) };

declare 'RepeatedDeployJob',
    as ArrayRef[DeployJob()];

coerce 'RepeatedDeployJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployJob'->new($_) } @$_ ] };

declare 'MapStringDeployJob',
    as HashRef[DeployJob()];

declare 'VerifyJob',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::VerifyJob'];

coerce 'VerifyJob',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::VerifyJob'->new($_) };

declare 'RepeatedVerifyJob',
    as ArrayRef[VerifyJob()];

coerce 'RepeatedVerifyJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::VerifyJob'->new($_) } @$_ ] };

declare 'MapStringVerifyJob',
    as HashRef[VerifyJob()];

declare 'PredeployJob',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PredeployJob'];

coerce 'PredeployJob',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PredeployJob'->new($_) };

declare 'RepeatedPredeployJob',
    as ArrayRef[PredeployJob()];

coerce 'RepeatedPredeployJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PredeployJob'->new($_) } @$_ ] };

declare 'MapStringPredeployJob',
    as HashRef[PredeployJob()];

declare 'PostdeployJob',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PostdeployJob'];

coerce 'PostdeployJob',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PostdeployJob'->new($_) };

declare 'RepeatedPostdeployJob',
    as ArrayRef[PostdeployJob()];

coerce 'RepeatedPostdeployJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PostdeployJob'->new($_) } @$_ ] };

declare 'MapStringPostdeployJob',
    as HashRef[PostdeployJob()];

declare 'CreateChildRolloutJob',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateChildRolloutJob'];

coerce 'CreateChildRolloutJob',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateChildRolloutJob'->new($_) };

declare 'RepeatedCreateChildRolloutJob',
    as ArrayRef[CreateChildRolloutJob()];

coerce 'RepeatedCreateChildRolloutJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateChildRolloutJob'->new($_) } @$_ ] };

declare 'MapStringCreateChildRolloutJob',
    as HashRef[CreateChildRolloutJob()];

declare 'AdvanceChildRolloutJob',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AdvanceChildRolloutJob'];

coerce 'AdvanceChildRolloutJob',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceChildRolloutJob'->new($_) };

declare 'RepeatedAdvanceChildRolloutJob',
    as ArrayRef[AdvanceChildRolloutJob()];

coerce 'RepeatedAdvanceChildRolloutJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceChildRolloutJob'->new($_) } @$_ ] };

declare 'MapStringAdvanceChildRolloutJob',
    as HashRef[AdvanceChildRolloutJob()];

declare 'ListRolloutsRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListRolloutsRequest'];

coerce 'ListRolloutsRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListRolloutsRequest'->new($_) };

declare 'RepeatedListRolloutsRequest',
    as ArrayRef[ListRolloutsRequest()];

coerce 'RepeatedListRolloutsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListRolloutsRequest'->new($_) } @$_ ] };

declare 'MapStringListRolloutsRequest',
    as HashRef[ListRolloutsRequest()];

declare 'ListRolloutsResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListRolloutsResponse'];

coerce 'ListRolloutsResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListRolloutsResponse'->new($_) };

declare 'RepeatedListRolloutsResponse',
    as ArrayRef[ListRolloutsResponse()];

coerce 'RepeatedListRolloutsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListRolloutsResponse'->new($_) } @$_ ] };

declare 'MapStringListRolloutsResponse',
    as HashRef[ListRolloutsResponse()];

declare 'GetRolloutRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetRolloutRequest'];

coerce 'GetRolloutRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetRolloutRequest'->new($_) };

declare 'RepeatedGetRolloutRequest',
    as ArrayRef[GetRolloutRequest()];

coerce 'RepeatedGetRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringGetRolloutRequest',
    as HashRef[GetRolloutRequest()];

declare 'CreateRolloutRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateRolloutRequest'];

coerce 'CreateRolloutRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateRolloutRequest'->new($_) };

declare 'RepeatedCreateRolloutRequest',
    as ArrayRef[CreateRolloutRequest()];

coerce 'RepeatedCreateRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRolloutRequest',
    as HashRef[CreateRolloutRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ApproveRolloutRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ApproveRolloutRequest'];

coerce 'ApproveRolloutRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ApproveRolloutRequest'->new($_) };

declare 'RepeatedApproveRolloutRequest',
    as ArrayRef[ApproveRolloutRequest()];

coerce 'RepeatedApproveRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ApproveRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringApproveRolloutRequest',
    as HashRef[ApproveRolloutRequest()];

declare 'ApproveRolloutResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ApproveRolloutResponse'];

coerce 'ApproveRolloutResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ApproveRolloutResponse'->new($_) };

declare 'RepeatedApproveRolloutResponse',
    as ArrayRef[ApproveRolloutResponse()];

coerce 'RepeatedApproveRolloutResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ApproveRolloutResponse'->new($_) } @$_ ] };

declare 'MapStringApproveRolloutResponse',
    as HashRef[ApproveRolloutResponse()];

declare 'AdvanceRolloutRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutRequest'];

coerce 'AdvanceRolloutRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutRequest'->new($_) };

declare 'RepeatedAdvanceRolloutRequest',
    as ArrayRef[AdvanceRolloutRequest()];

coerce 'RepeatedAdvanceRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringAdvanceRolloutRequest',
    as HashRef[AdvanceRolloutRequest()];

declare 'AdvanceRolloutResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutResponse'];

coerce 'AdvanceRolloutResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutResponse'->new($_) };

declare 'RepeatedAdvanceRolloutResponse',
    as ArrayRef[AdvanceRolloutResponse()];

coerce 'RepeatedAdvanceRolloutResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutResponse'->new($_) } @$_ ] };

declare 'MapStringAdvanceRolloutResponse',
    as HashRef[AdvanceRolloutResponse()];

declare 'CancelRolloutRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CancelRolloutRequest'];

coerce 'CancelRolloutRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelRolloutRequest'->new($_) };

declare 'RepeatedCancelRolloutRequest',
    as ArrayRef[CancelRolloutRequest()];

coerce 'RepeatedCancelRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringCancelRolloutRequest',
    as HashRef[CancelRolloutRequest()];

declare 'CancelRolloutResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CancelRolloutResponse'];

coerce 'CancelRolloutResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelRolloutResponse'->new($_) };

declare 'RepeatedCancelRolloutResponse',
    as ArrayRef[CancelRolloutResponse()];

coerce 'RepeatedCancelRolloutResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelRolloutResponse'->new($_) } @$_ ] };

declare 'MapStringCancelRolloutResponse',
    as HashRef[CancelRolloutResponse()];

declare 'IgnoreJobRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::IgnoreJobRequest'];

coerce 'IgnoreJobRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::IgnoreJobRequest'->new($_) };

declare 'RepeatedIgnoreJobRequest',
    as ArrayRef[IgnoreJobRequest()];

coerce 'RepeatedIgnoreJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::IgnoreJobRequest'->new($_) } @$_ ] };

declare 'MapStringIgnoreJobRequest',
    as HashRef[IgnoreJobRequest()];

declare 'IgnoreJobResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::IgnoreJobResponse'];

coerce 'IgnoreJobResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::IgnoreJobResponse'->new($_) };

declare 'RepeatedIgnoreJobResponse',
    as ArrayRef[IgnoreJobResponse()];

coerce 'RepeatedIgnoreJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::IgnoreJobResponse'->new($_) } @$_ ] };

declare 'MapStringIgnoreJobResponse',
    as HashRef[IgnoreJobResponse()];

declare 'RetryJobRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RetryJobRequest'];

coerce 'RetryJobRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryJobRequest'->new($_) };

declare 'RepeatedRetryJobRequest',
    as ArrayRef[RetryJobRequest()];

coerce 'RepeatedRetryJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryJobRequest'->new($_) } @$_ ] };

declare 'MapStringRetryJobRequest',
    as HashRef[RetryJobRequest()];

declare 'RetryJobResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RetryJobResponse'];

coerce 'RetryJobResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryJobResponse'->new($_) };

declare 'RepeatedRetryJobResponse',
    as ArrayRef[RetryJobResponse()];

coerce 'RepeatedRetryJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryJobResponse'->new($_) } @$_ ] };

declare 'MapStringRetryJobResponse',
    as HashRef[RetryJobResponse()];

declare 'AbandonReleaseRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AbandonReleaseRequest'];

coerce 'AbandonReleaseRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AbandonReleaseRequest'->new($_) };

declare 'RepeatedAbandonReleaseRequest',
    as ArrayRef[AbandonReleaseRequest()];

coerce 'RepeatedAbandonReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AbandonReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringAbandonReleaseRequest',
    as HashRef[AbandonReleaseRequest()];

declare 'AbandonReleaseResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AbandonReleaseResponse'];

coerce 'AbandonReleaseResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AbandonReleaseResponse'->new($_) };

declare 'RepeatedAbandonReleaseResponse',
    as ArrayRef[AbandonReleaseResponse()];

coerce 'RepeatedAbandonReleaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AbandonReleaseResponse'->new($_) } @$_ ] };

declare 'MapStringAbandonReleaseResponse',
    as HashRef[AbandonReleaseResponse()];

declare 'JobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::JobRun'];

coerce 'JobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::JobRun'->new($_) };

declare 'RepeatedJobRun',
    as ArrayRef[JobRun()];

coerce 'RepeatedJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::JobRun'->new($_) } @$_ ] };

declare 'MapStringJobRun',
    as HashRef[JobRun()];

declare 'State',
    as (Int | Str);

declare 'DeployJobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeployJobRun'];

coerce 'DeployJobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployJobRun'->new($_) };

declare 'RepeatedDeployJobRun',
    as ArrayRef[DeployJobRun()];

coerce 'RepeatedDeployJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeployJobRun'->new($_) } @$_ ] };

declare 'MapStringDeployJobRun',
    as HashRef[DeployJobRun()];

declare 'FailureCause',
    as (Int | Str);

declare 'VerifyJobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::VerifyJobRun'];

coerce 'VerifyJobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::VerifyJobRun'->new($_) };

declare 'RepeatedVerifyJobRun',
    as ArrayRef[VerifyJobRun()];

coerce 'RepeatedVerifyJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::VerifyJobRun'->new($_) } @$_ ] };

declare 'MapStringVerifyJobRun',
    as HashRef[VerifyJobRun()];

declare 'FailureCause',
    as (Int | Str);

declare 'PredeployJobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PredeployJobRun'];

coerce 'PredeployJobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PredeployJobRun'->new($_) };

declare 'RepeatedPredeployJobRun',
    as ArrayRef[PredeployJobRun()];

coerce 'RepeatedPredeployJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PredeployJobRun'->new($_) } @$_ ] };

declare 'MapStringPredeployJobRun',
    as HashRef[PredeployJobRun()];

declare 'FailureCause',
    as (Int | Str);

declare 'PostdeployJobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PostdeployJobRun'];

coerce 'PostdeployJobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PostdeployJobRun'->new($_) };

declare 'RepeatedPostdeployJobRun',
    as ArrayRef[PostdeployJobRun()];

coerce 'RepeatedPostdeployJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PostdeployJobRun'->new($_) } @$_ ] };

declare 'MapStringPostdeployJobRun',
    as HashRef[PostdeployJobRun()];

declare 'FailureCause',
    as (Int | Str);

declare 'CreateChildRolloutJobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateChildRolloutJobRun'];

coerce 'CreateChildRolloutJobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateChildRolloutJobRun'->new($_) };

declare 'RepeatedCreateChildRolloutJobRun',
    as ArrayRef[CreateChildRolloutJobRun()];

coerce 'RepeatedCreateChildRolloutJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateChildRolloutJobRun'->new($_) } @$_ ] };

declare 'MapStringCreateChildRolloutJobRun',
    as HashRef[CreateChildRolloutJobRun()];

declare 'AdvanceChildRolloutJobRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AdvanceChildRolloutJobRun'];

coerce 'AdvanceChildRolloutJobRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceChildRolloutJobRun'->new($_) };

declare 'RepeatedAdvanceChildRolloutJobRun',
    as ArrayRef[AdvanceChildRolloutJobRun()];

coerce 'RepeatedAdvanceChildRolloutJobRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceChildRolloutJobRun'->new($_) } @$_ ] };

declare 'MapStringAdvanceChildRolloutJobRun',
    as HashRef[AdvanceChildRolloutJobRun()];

declare 'ListJobRunsRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListJobRunsRequest'];

coerce 'ListJobRunsRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListJobRunsRequest'->new($_) };

declare 'RepeatedListJobRunsRequest',
    as ArrayRef[ListJobRunsRequest()];

coerce 'RepeatedListJobRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListJobRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobRunsRequest',
    as HashRef[ListJobRunsRequest()];

declare 'ListJobRunsResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListJobRunsResponse'];

coerce 'ListJobRunsResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListJobRunsResponse'->new($_) };

declare 'RepeatedListJobRunsResponse',
    as ArrayRef[ListJobRunsResponse()];

coerce 'RepeatedListJobRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListJobRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobRunsResponse',
    as HashRef[ListJobRunsResponse()];

declare 'GetJobRunRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetJobRunRequest'];

coerce 'GetJobRunRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetJobRunRequest'->new($_) };

declare 'RepeatedGetJobRunRequest',
    as ArrayRef[GetJobRunRequest()];

coerce 'RepeatedGetJobRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetJobRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRunRequest',
    as HashRef[GetJobRunRequest()];

declare 'TerminateJobRunRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TerminateJobRunRequest'];

coerce 'TerminateJobRunRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TerminateJobRunRequest'->new($_) };

declare 'RepeatedTerminateJobRunRequest',
    as ArrayRef[TerminateJobRunRequest()];

coerce 'RepeatedTerminateJobRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TerminateJobRunRequest'->new($_) } @$_ ] };

declare 'MapStringTerminateJobRunRequest',
    as HashRef[TerminateJobRunRequest()];

declare 'TerminateJobRunResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TerminateJobRunResponse'];

coerce 'TerminateJobRunResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TerminateJobRunResponse'->new($_) };

declare 'RepeatedTerminateJobRunResponse',
    as ArrayRef[TerminateJobRunResponse()];

coerce 'RepeatedTerminateJobRunResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TerminateJobRunResponse'->new($_) } @$_ ] };

declare 'MapStringTerminateJobRunResponse',
    as HashRef[TerminateJobRunResponse()];

declare 'Config',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'SkaffoldVersion',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldVersion'];

coerce 'SkaffoldVersion',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldVersion'->new($_) };

declare 'RepeatedSkaffoldVersion',
    as ArrayRef[SkaffoldVersion()];

coerce 'RepeatedSkaffoldVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::SkaffoldVersion'->new($_) } @$_ ] };

declare 'MapStringSkaffoldVersion',
    as HashRef[SkaffoldVersion()];

declare 'GetConfigRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetConfigRequest'];

coerce 'GetConfigRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetConfigRequest'->new($_) };

declare 'RepeatedGetConfigRequest',
    as ArrayRef[GetConfigRequest()];

coerce 'RepeatedGetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfigRequest',
    as HashRef[GetConfigRequest()];

declare 'Automation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Automation'];

coerce 'Automation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Automation'->new($_) };

declare 'RepeatedAutomation',
    as ArrayRef[Automation()];

coerce 'RepeatedAutomation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Automation'->new($_) } @$_ ] };

declare 'MapStringAutomation',
    as HashRef[Automation()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Automation::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Automation::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Automation::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Automation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Automation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Automation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AutomationResourceSelector',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AutomationResourceSelector'];

coerce 'AutomationResourceSelector',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationResourceSelector'->new($_) };

declare 'RepeatedAutomationResourceSelector',
    as ArrayRef[AutomationResourceSelector()];

coerce 'RepeatedAutomationResourceSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationResourceSelector'->new($_) } @$_ ] };

declare 'MapStringAutomationResourceSelector',
    as HashRef[AutomationResourceSelector()];

declare 'AutomationRule',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AutomationRule'];

coerce 'AutomationRule',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRule'->new($_) };

declare 'RepeatedAutomationRule',
    as ArrayRef[AutomationRule()];

coerce 'RepeatedAutomationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRule'->new($_) } @$_ ] };

declare 'MapStringAutomationRule',
    as HashRef[AutomationRule()];

declare 'TimedPromoteReleaseRule',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseRule'];

coerce 'TimedPromoteReleaseRule',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseRule'->new($_) };

declare 'RepeatedTimedPromoteReleaseRule',
    as ArrayRef[TimedPromoteReleaseRule()];

coerce 'RepeatedTimedPromoteReleaseRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseRule'->new($_) } @$_ ] };

declare 'MapStringTimedPromoteReleaseRule',
    as HashRef[TimedPromoteReleaseRule()];

declare 'PromoteReleaseRule',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PromoteReleaseRule'];

coerce 'PromoteReleaseRule',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PromoteReleaseRule'->new($_) };

declare 'RepeatedPromoteReleaseRule',
    as ArrayRef[PromoteReleaseRule()];

coerce 'RepeatedPromoteReleaseRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PromoteReleaseRule'->new($_) } @$_ ] };

declare 'MapStringPromoteReleaseRule',
    as HashRef[PromoteReleaseRule()];

declare 'AdvanceRolloutRule',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutRule'];

coerce 'AdvanceRolloutRule',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutRule'->new($_) };

declare 'RepeatedAdvanceRolloutRule',
    as ArrayRef[AdvanceRolloutRule()];

coerce 'RepeatedAdvanceRolloutRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutRule'->new($_) } @$_ ] };

declare 'MapStringAdvanceRolloutRule',
    as HashRef[AdvanceRolloutRule()];

declare 'RepairRolloutRule',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RepairRolloutRule'];

coerce 'RepairRolloutRule',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairRolloutRule'->new($_) };

declare 'RepeatedRepairRolloutRule',
    as ArrayRef[RepairRolloutRule()];

coerce 'RepeatedRepairRolloutRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairRolloutRule'->new($_) } @$_ ] };

declare 'MapStringRepairRolloutRule',
    as HashRef[RepairRolloutRule()];

declare 'RepairPhaseConfig',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RepairPhaseConfig'];

coerce 'RepairPhaseConfig',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairPhaseConfig'->new($_) };

declare 'RepeatedRepairPhaseConfig',
    as ArrayRef[RepairPhaseConfig()];

coerce 'RepeatedRepairPhaseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairPhaseConfig'->new($_) } @$_ ] };

declare 'MapStringRepairPhaseConfig',
    as HashRef[RepairPhaseConfig()];

declare 'Retry',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Retry'];

coerce 'Retry',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Retry'->new($_) };

declare 'RepeatedRetry',
    as ArrayRef[Retry()];

coerce 'RepeatedRetry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Retry'->new($_) } @$_ ] };

declare 'MapStringRetry',
    as HashRef[Retry()];

declare 'Rollback',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::Rollback'];

coerce 'Rollback',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollback'->new($_) };

declare 'RepeatedRollback',
    as ArrayRef[Rollback()];

coerce 'RepeatedRollback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::Rollback'->new($_) } @$_ ] };

declare 'MapStringRollback',
    as HashRef[Rollback()];

declare 'AutomationRuleCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AutomationRuleCondition'];

coerce 'AutomationRuleCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRuleCondition'->new($_) };

declare 'RepeatedAutomationRuleCondition',
    as ArrayRef[AutomationRuleCondition()];

coerce 'RepeatedAutomationRuleCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRuleCondition'->new($_) } @$_ ] };

declare 'MapStringAutomationRuleCondition',
    as HashRef[AutomationRuleCondition()];

declare 'TimedPromoteReleaseCondition',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseCondition'];

coerce 'TimedPromoteReleaseCondition',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseCondition'->new($_) };

declare 'RepeatedTimedPromoteReleaseCondition',
    as ArrayRef[TimedPromoteReleaseCondition()];

coerce 'RepeatedTimedPromoteReleaseCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseCondition'->new($_) } @$_ ] };

declare 'MapStringTimedPromoteReleaseCondition',
    as HashRef[TimedPromoteReleaseCondition()];

declare 'Targets',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseCondition::Targets'];

coerce 'Targets',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseCondition::Targets'->new($_) };

declare 'RepeatedTargets',
    as ArrayRef[Targets()];

coerce 'RepeatedTargets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseCondition::Targets'->new($_) } @$_ ] };

declare 'MapStringTargets',
    as HashRef[Targets()];

declare 'CreateAutomationRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CreateAutomationRequest'];

coerce 'CreateAutomationRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateAutomationRequest'->new($_) };

declare 'RepeatedCreateAutomationRequest',
    as ArrayRef[CreateAutomationRequest()];

coerce 'RepeatedCreateAutomationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CreateAutomationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAutomationRequest',
    as HashRef[CreateAutomationRequest()];

declare 'UpdateAutomationRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::UpdateAutomationRequest'];

coerce 'UpdateAutomationRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateAutomationRequest'->new($_) };

declare 'RepeatedUpdateAutomationRequest',
    as ArrayRef[UpdateAutomationRequest()];

coerce 'RepeatedUpdateAutomationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::UpdateAutomationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAutomationRequest',
    as HashRef[UpdateAutomationRequest()];

declare 'DeleteAutomationRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::DeleteAutomationRequest'];

coerce 'DeleteAutomationRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteAutomationRequest'->new($_) };

declare 'RepeatedDeleteAutomationRequest',
    as ArrayRef[DeleteAutomationRequest()];

coerce 'RepeatedDeleteAutomationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::DeleteAutomationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAutomationRequest',
    as HashRef[DeleteAutomationRequest()];

declare 'ListAutomationsRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationsRequest'];

coerce 'ListAutomationsRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationsRequest'->new($_) };

declare 'RepeatedListAutomationsRequest',
    as ArrayRef[ListAutomationsRequest()];

coerce 'RepeatedListAutomationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationsRequest'->new($_) } @$_ ] };

declare 'MapStringListAutomationsRequest',
    as HashRef[ListAutomationsRequest()];

declare 'ListAutomationsResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationsResponse'];

coerce 'ListAutomationsResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationsResponse'->new($_) };

declare 'RepeatedListAutomationsResponse',
    as ArrayRef[ListAutomationsResponse()];

coerce 'RepeatedListAutomationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationsResponse'->new($_) } @$_ ] };

declare 'MapStringListAutomationsResponse',
    as HashRef[ListAutomationsResponse()];

declare 'GetAutomationRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetAutomationRequest'];

coerce 'GetAutomationRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetAutomationRequest'->new($_) };

declare 'RepeatedGetAutomationRequest',
    as ArrayRef[GetAutomationRequest()];

coerce 'RepeatedGetAutomationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetAutomationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutomationRequest',
    as HashRef[GetAutomationRequest()];

declare 'AutomationRun',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AutomationRun'];

coerce 'AutomationRun',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRun'->new($_) };

declare 'RepeatedAutomationRun',
    as ArrayRef[AutomationRun()];

coerce 'RepeatedAutomationRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AutomationRun'->new($_) } @$_ ] };

declare 'MapStringAutomationRun',
    as HashRef[AutomationRun()];

declare 'State',
    as (Int | Str);

declare 'PromoteReleaseOperation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::PromoteReleaseOperation'];

coerce 'PromoteReleaseOperation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::PromoteReleaseOperation'->new($_) };

declare 'RepeatedPromoteReleaseOperation',
    as ArrayRef[PromoteReleaseOperation()];

coerce 'RepeatedPromoteReleaseOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::PromoteReleaseOperation'->new($_) } @$_ ] };

declare 'MapStringPromoteReleaseOperation',
    as HashRef[PromoteReleaseOperation()];

declare 'AdvanceRolloutOperation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutOperation'];

coerce 'AdvanceRolloutOperation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutOperation'->new($_) };

declare 'RepeatedAdvanceRolloutOperation',
    as ArrayRef[AdvanceRolloutOperation()];

coerce 'RepeatedAdvanceRolloutOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::AdvanceRolloutOperation'->new($_) } @$_ ] };

declare 'MapStringAdvanceRolloutOperation',
    as HashRef[AdvanceRolloutOperation()];

declare 'RepairRolloutOperation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RepairRolloutOperation'];

coerce 'RepairRolloutOperation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairRolloutOperation'->new($_) };

declare 'RepeatedRepairRolloutOperation',
    as ArrayRef[RepairRolloutOperation()];

coerce 'RepeatedRepairRolloutOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairRolloutOperation'->new($_) } @$_ ] };

declare 'MapStringRepairRolloutOperation',
    as HashRef[RepairRolloutOperation()];

declare 'TimedPromoteReleaseOperation',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseOperation'];

coerce 'TimedPromoteReleaseOperation',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseOperation'->new($_) };

declare 'RepeatedTimedPromoteReleaseOperation',
    as ArrayRef[TimedPromoteReleaseOperation()];

coerce 'RepeatedTimedPromoteReleaseOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::TimedPromoteReleaseOperation'->new($_) } @$_ ] };

declare 'MapStringTimedPromoteReleaseOperation',
    as HashRef[TimedPromoteReleaseOperation()];

declare 'RepairPhase',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RepairPhase'];

coerce 'RepairPhase',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairPhase'->new($_) };

declare 'RepeatedRepairPhase',
    as ArrayRef[RepairPhase()];

coerce 'RepeatedRepairPhase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RepairPhase'->new($_) } @$_ ] };

declare 'MapStringRepairPhase',
    as HashRef[RepairPhase()];

declare 'RetryPhase',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RetryPhase'];

coerce 'RetryPhase',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryPhase'->new($_) };

declare 'RepeatedRetryPhase',
    as ArrayRef[RetryPhase()];

coerce 'RepeatedRetryPhase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryPhase'->new($_) } @$_ ] };

declare 'MapStringRetryPhase',
    as HashRef[RetryPhase()];

declare 'RetryAttempt',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RetryAttempt'];

coerce 'RetryAttempt',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryAttempt'->new($_) };

declare 'RepeatedRetryAttempt',
    as ArrayRef[RetryAttempt()];

coerce 'RepeatedRetryAttempt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RetryAttempt'->new($_) } @$_ ] };

declare 'MapStringRetryAttempt',
    as HashRef[RetryAttempt()];

declare 'RollbackAttempt',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::RollbackAttempt'];

coerce 'RollbackAttempt',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackAttempt'->new($_) };

declare 'RepeatedRollbackAttempt',
    as ArrayRef[RollbackAttempt()];

coerce 'RepeatedRollbackAttempt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::RollbackAttempt'->new($_) } @$_ ] };

declare 'MapStringRollbackAttempt',
    as HashRef[RollbackAttempt()];

declare 'ListAutomationRunsRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationRunsRequest'];

coerce 'ListAutomationRunsRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationRunsRequest'->new($_) };

declare 'RepeatedListAutomationRunsRequest',
    as ArrayRef[ListAutomationRunsRequest()];

coerce 'RepeatedListAutomationRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListAutomationRunsRequest',
    as HashRef[ListAutomationRunsRequest()];

declare 'ListAutomationRunsResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationRunsResponse'];

coerce 'ListAutomationRunsResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationRunsResponse'->new($_) };

declare 'RepeatedListAutomationRunsResponse',
    as ArrayRef[ListAutomationRunsResponse()];

coerce 'RepeatedListAutomationRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::ListAutomationRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListAutomationRunsResponse',
    as HashRef[ListAutomationRunsResponse()];

declare 'GetAutomationRunRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::GetAutomationRunRequest'];

coerce 'GetAutomationRunRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::GetAutomationRunRequest'->new($_) };

declare 'RepeatedGetAutomationRunRequest',
    as ArrayRef[GetAutomationRunRequest()];

coerce 'RepeatedGetAutomationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::GetAutomationRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutomationRunRequest',
    as HashRef[GetAutomationRunRequest()];

declare 'CancelAutomationRunRequest',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CancelAutomationRunRequest'];

coerce 'CancelAutomationRunRequest',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelAutomationRunRequest'->new($_) };

declare 'RepeatedCancelAutomationRunRequest',
    as ArrayRef[CancelAutomationRunRequest()];

coerce 'RepeatedCancelAutomationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelAutomationRunRequest'->new($_) } @$_ ] };

declare 'MapStringCancelAutomationRunRequest',
    as HashRef[CancelAutomationRunRequest()];

declare 'CancelAutomationRunResponse',
    as InstanceOf['Google::Cloud::Deploy::V1::CloudDeploy::CancelAutomationRunResponse'];

coerce 'CancelAutomationRunResponse',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelAutomationRunResponse'->new($_) };

declare 'RepeatedCancelAutomationRunResponse',
    as ArrayRef[CancelAutomationRunResponse()];

coerce 'RepeatedCancelAutomationRunResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CloudDeploy::CancelAutomationRunResponse'->new($_) } @$_ ] };

declare 'MapStringCancelAutomationRunResponse',
    as HashRef[CancelAutomationRunResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::CloudDeploy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
