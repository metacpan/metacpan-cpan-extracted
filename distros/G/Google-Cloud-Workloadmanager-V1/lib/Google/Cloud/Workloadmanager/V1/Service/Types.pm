package Google::Cloud::Workloadmanager::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Evaluation',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Evaluation'];

coerce 'Evaluation',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Evaluation'->new($_) };

declare 'RepeatedEvaluation',
    as ArrayRef[Evaluation()];

coerce 'RepeatedEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Evaluation'->new($_) } @$_ ] };

declare 'MapStringEvaluation',
    as HashRef[Evaluation()];

declare 'EvaluationType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Evaluation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Evaluation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Evaluation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourceFilter',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ResourceFilter'];

coerce 'ResourceFilter',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ResourceFilter'->new($_) };

declare 'RepeatedResourceFilter',
    as ArrayRef[ResourceFilter()];

coerce 'RepeatedResourceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ResourceFilter'->new($_) } @$_ ] };

declare 'MapStringResourceFilter',
    as HashRef[ResourceFilter()];

declare 'InclusionLabelsEntry',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ResourceFilter::InclusionLabelsEntry'];

coerce 'InclusionLabelsEntry',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ResourceFilter::InclusionLabelsEntry'->new($_) };

declare 'RepeatedInclusionLabelsEntry',
    as ArrayRef[InclusionLabelsEntry()];

coerce 'RepeatedInclusionLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ResourceFilter::InclusionLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringInclusionLabelsEntry',
    as HashRef[InclusionLabelsEntry()];

declare 'GceInstanceFilter',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::GceInstanceFilter'];

coerce 'GceInstanceFilter',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::GceInstanceFilter'->new($_) };

declare 'RepeatedGceInstanceFilter',
    as ArrayRef[GceInstanceFilter()];

coerce 'RepeatedGceInstanceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::GceInstanceFilter'->new($_) } @$_ ] };

declare 'MapStringGceInstanceFilter',
    as HashRef[GceInstanceFilter()];

declare 'ResourceStatus',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ResourceStatus'];

coerce 'ResourceStatus',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ResourceStatus'->new($_) };

declare 'RepeatedResourceStatus',
    as ArrayRef[ResourceStatus()];

coerce 'RepeatedResourceStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ResourceStatus'->new($_) } @$_ ] };

declare 'MapStringResourceStatus',
    as HashRef[ResourceStatus()];

declare 'State',
    as (Int | Str);

declare 'BigQueryDestination',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::BigQueryDestination'];

coerce 'BigQueryDestination',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::BigQueryDestination'->new($_) };

declare 'RepeatedBigQueryDestination',
    as ArrayRef[BigQueryDestination()];

coerce 'RepeatedBigQueryDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::BigQueryDestination'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestination',
    as HashRef[BigQueryDestination()];

declare 'ListEvaluationsRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListEvaluationsRequest'];

coerce 'ListEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListEvaluationsRequest'->new($_) };

declare 'RepeatedListEvaluationsRequest',
    as ArrayRef[ListEvaluationsRequest()];

coerce 'RepeatedListEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsRequest',
    as HashRef[ListEvaluationsRequest()];

declare 'ListEvaluationsResponse',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListEvaluationsResponse'];

coerce 'ListEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListEvaluationsResponse'->new($_) };

declare 'RepeatedListEvaluationsResponse',
    as ArrayRef[ListEvaluationsResponse()];

coerce 'RepeatedListEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsResponse',
    as HashRef[ListEvaluationsResponse()];

declare 'GetEvaluationRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::GetEvaluationRequest'];

coerce 'GetEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::GetEvaluationRequest'->new($_) };

declare 'RepeatedGetEvaluationRequest',
    as ArrayRef[GetEvaluationRequest()];

coerce 'RepeatedGetEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::GetEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationRequest',
    as HashRef[GetEvaluationRequest()];

declare 'CreateEvaluationRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::CreateEvaluationRequest'];

coerce 'CreateEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::CreateEvaluationRequest'->new($_) };

declare 'RepeatedCreateEvaluationRequest',
    as ArrayRef[CreateEvaluationRequest()];

coerce 'RepeatedCreateEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::CreateEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationRequest',
    as HashRef[CreateEvaluationRequest()];

declare 'UpdateEvaluationRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::UpdateEvaluationRequest'];

coerce 'UpdateEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::UpdateEvaluationRequest'->new($_) };

declare 'RepeatedUpdateEvaluationRequest',
    as ArrayRef[UpdateEvaluationRequest()];

coerce 'RepeatedUpdateEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::UpdateEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEvaluationRequest',
    as HashRef[UpdateEvaluationRequest()];

declare 'DeleteEvaluationRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::DeleteEvaluationRequest'];

coerce 'DeleteEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::DeleteEvaluationRequest'->new($_) };

declare 'RepeatedDeleteEvaluationRequest',
    as ArrayRef[DeleteEvaluationRequest()];

coerce 'RepeatedDeleteEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::DeleteEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationRequest',
    as HashRef[DeleteEvaluationRequest()];

declare 'Execution',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Execution'];

coerce 'Execution',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Execution'->new($_) };

declare 'RepeatedExecution',
    as ArrayRef[Execution()];

coerce 'RepeatedExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Execution'->new($_) } @$_ ] };

declare 'MapStringExecution',
    as HashRef[Execution()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'Engine',
    as (Int | Str);

declare 'ExternalDataSources',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Execution::ExternalDataSources'];

coerce 'ExternalDataSources',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Execution::ExternalDataSources'->new($_) };

declare 'RepeatedExternalDataSources',
    as ArrayRef[ExternalDataSources()];

coerce 'RepeatedExternalDataSources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Execution::ExternalDataSources'->new($_) } @$_ ] };

declare 'MapStringExternalDataSources',
    as HashRef[ExternalDataSources()];

declare 'Type',
    as (Int | Str);

declare 'Notice',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Execution::Notice'];

coerce 'Notice',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Execution::Notice'->new($_) };

declare 'RepeatedNotice',
    as ArrayRef[Notice()];

coerce 'RepeatedNotice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Execution::Notice'->new($_) } @$_ ] };

declare 'MapStringNotice',
    as HashRef[Notice()];

declare 'Summary',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Execution::Summary'];

coerce 'Summary',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Execution::Summary'->new($_) };

declare 'RepeatedSummary',
    as ArrayRef[Summary()];

coerce 'RepeatedSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Execution::Summary'->new($_) } @$_ ] };

declare 'MapStringSummary',
    as HashRef[Summary()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Execution::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Execution::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Execution::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RuleExecutionResult',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::RuleExecutionResult'];

coerce 'RuleExecutionResult',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::RuleExecutionResult'->new($_) };

declare 'RepeatedRuleExecutionResult',
    as ArrayRef[RuleExecutionResult()];

coerce 'RepeatedRuleExecutionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::RuleExecutionResult'->new($_) } @$_ ] };

declare 'MapStringRuleExecutionResult',
    as HashRef[RuleExecutionResult()];

declare 'State',
    as (Int | Str);

declare 'ListExecutionsRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListExecutionsRequest'];

coerce 'ListExecutionsRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionsRequest'->new($_) };

declare 'RepeatedListExecutionsRequest',
    as ArrayRef[ListExecutionsRequest()];

coerce 'RepeatedListExecutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListExecutionsRequest',
    as HashRef[ListExecutionsRequest()];

declare 'ListExecutionsResponse',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListExecutionsResponse'];

coerce 'ListExecutionsResponse',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionsResponse'->new($_) };

declare 'RepeatedListExecutionsResponse',
    as ArrayRef[ListExecutionsResponse()];

coerce 'RepeatedListExecutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListExecutionsResponse',
    as HashRef[ListExecutionsResponse()];

declare 'GetExecutionRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::GetExecutionRequest'];

coerce 'GetExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::GetExecutionRequest'->new($_) };

declare 'RepeatedGetExecutionRequest',
    as ArrayRef[GetExecutionRequest()];

coerce 'RepeatedGetExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::GetExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringGetExecutionRequest',
    as HashRef[GetExecutionRequest()];

declare 'RunEvaluationRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::RunEvaluationRequest'];

coerce 'RunEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::RunEvaluationRequest'->new($_) };

declare 'RepeatedRunEvaluationRequest',
    as ArrayRef[RunEvaluationRequest()];

coerce 'RepeatedRunEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::RunEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationRequest',
    as HashRef[RunEvaluationRequest()];

declare 'DeleteExecutionRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::DeleteExecutionRequest'];

coerce 'DeleteExecutionRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::DeleteExecutionRequest'->new($_) };

declare 'RepeatedDeleteExecutionRequest',
    as ArrayRef[DeleteExecutionRequest()];

coerce 'RepeatedDeleteExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::DeleteExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExecutionRequest',
    as HashRef[DeleteExecutionRequest()];

declare 'ListExecutionResultsRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListExecutionResultsRequest'];

coerce 'ListExecutionResultsRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionResultsRequest'->new($_) };

declare 'RepeatedListExecutionResultsRequest',
    as ArrayRef[ListExecutionResultsRequest()];

coerce 'RepeatedListExecutionResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListExecutionResultsRequest',
    as HashRef[ListExecutionResultsRequest()];

declare 'ListExecutionResultsResponse',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListExecutionResultsResponse'];

coerce 'ListExecutionResultsResponse',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionResultsResponse'->new($_) };

declare 'RepeatedListExecutionResultsResponse',
    as ArrayRef[ListExecutionResultsResponse()];

coerce 'RepeatedListExecutionResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListExecutionResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListExecutionResultsResponse',
    as HashRef[ListExecutionResultsResponse()];

declare 'ExecutionResult',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ExecutionResult'];

coerce 'ExecutionResult',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ExecutionResult'->new($_) };

declare 'RepeatedExecutionResult',
    as ArrayRef[ExecutionResult()];

coerce 'RepeatedExecutionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ExecutionResult'->new($_) } @$_ ] };

declare 'MapStringExecutionResult',
    as HashRef[ExecutionResult()];

declare 'Type',
    as (Int | Str);

declare 'Command',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Command'];

coerce 'Command',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Command'->new($_) };

declare 'RepeatedCommand',
    as ArrayRef[Command()];

coerce 'RepeatedCommand',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Command'->new($_) } @$_ ] };

declare 'MapStringCommand',
    as HashRef[Command()];

declare 'AgentCommand',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::AgentCommand'];

coerce 'AgentCommand',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::AgentCommand'->new($_) };

declare 'RepeatedAgentCommand',
    as ArrayRef[AgentCommand()];

coerce 'RepeatedAgentCommand',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::AgentCommand'->new($_) } @$_ ] };

declare 'MapStringAgentCommand',
    as HashRef[AgentCommand()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::AgentCommand::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::AgentCommand::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::AgentCommand::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'ShellCommand',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ShellCommand'];

coerce 'ShellCommand',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ShellCommand'->new($_) };

declare 'RepeatedShellCommand',
    as ArrayRef[ShellCommand()];

coerce 'RepeatedShellCommand',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ShellCommand'->new($_) } @$_ ] };

declare 'MapStringShellCommand',
    as HashRef[ShellCommand()];

declare 'RuleOutput',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::RuleOutput'];

coerce 'RuleOutput',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::RuleOutput'->new($_) };

declare 'RepeatedRuleOutput',
    as ArrayRef[RuleOutput()];

coerce 'RepeatedRuleOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::RuleOutput'->new($_) } @$_ ] };

declare 'MapStringRuleOutput',
    as HashRef[RuleOutput()];

declare 'DetailsEntry',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::RuleOutput::DetailsEntry'];

coerce 'DetailsEntry',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::RuleOutput::DetailsEntry'->new($_) };

declare 'RepeatedDetailsEntry',
    as ArrayRef[DetailsEntry()];

coerce 'RepeatedDetailsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::RuleOutput::DetailsEntry'->new($_) } @$_ ] };

declare 'MapStringDetailsEntry',
    as HashRef[DetailsEntry()];

declare 'ViolationDetails',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ViolationDetails'];

coerce 'ViolationDetails',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ViolationDetails'->new($_) };

declare 'RepeatedViolationDetails',
    as ArrayRef[ViolationDetails()];

coerce 'RepeatedViolationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ViolationDetails'->new($_) } @$_ ] };

declare 'MapStringViolationDetails',
    as HashRef[ViolationDetails()];

declare 'ObservedEntry',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ViolationDetails::ObservedEntry'];

coerce 'ObservedEntry',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ViolationDetails::ObservedEntry'->new($_) };

declare 'RepeatedObservedEntry',
    as ArrayRef[ObservedEntry()];

coerce 'RepeatedObservedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ViolationDetails::ObservedEntry'->new($_) } @$_ ] };

declare 'MapStringObservedEntry',
    as HashRef[ObservedEntry()];

declare 'Resource',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Resource'];

coerce 'Resource',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Resource'->new($_) };

declare 'RepeatedResource',
    as ArrayRef[Resource()];

coerce 'RepeatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Resource'->new($_) } @$_ ] };

declare 'MapStringResource',
    as HashRef[Resource()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Rule',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'RuleType',
    as (Int | Str);

declare 'ListRulesRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListRulesRequest'];

coerce 'ListRulesRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListRulesRequest'->new($_) };

declare 'RepeatedListRulesRequest',
    as ArrayRef[ListRulesRequest()];

coerce 'RepeatedListRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListRulesRequest',
    as HashRef[ListRulesRequest()];

declare 'ListRulesResponse',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListRulesResponse'];

coerce 'ListRulesResponse',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListRulesResponse'->new($_) };

declare 'RepeatedListRulesResponse',
    as ArrayRef[ListRulesResponse()];

coerce 'RepeatedListRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListRulesResponse',
    as HashRef[ListRulesResponse()];

declare 'ListScannedResourcesRequest',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListScannedResourcesRequest'];

coerce 'ListScannedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListScannedResourcesRequest'->new($_) };

declare 'RepeatedListScannedResourcesRequest',
    as ArrayRef[ListScannedResourcesRequest()];

coerce 'RepeatedListScannedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListScannedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListScannedResourcesRequest',
    as HashRef[ListScannedResourcesRequest()];

declare 'ListScannedResourcesResponse',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ListScannedResourcesResponse'];

coerce 'ListScannedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ListScannedResourcesResponse'->new($_) };

declare 'RepeatedListScannedResourcesResponse',
    as ArrayRef[ListScannedResourcesResponse()];

coerce 'RepeatedListScannedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ListScannedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListScannedResourcesResponse',
    as HashRef[ListScannedResourcesResponse()];

declare 'ScannedResource',
    as InstanceOf['Google::Cloud::Workloadmanager::V1::Service::ScannedResource'];

coerce 'ScannedResource',
    from HashRef, via { 'Google::Cloud::Workloadmanager::V1::Service::ScannedResource'->new($_) };

declare 'RepeatedScannedResource',
    as ArrayRef[ScannedResource()];

coerce 'RepeatedScannedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadmanager::V1::Service::ScannedResource'->new($_) } @$_ ] };

declare 'MapStringScannedResource',
    as HashRef[ScannedResource()];

1;

__END__

=head1 NAME

Google::Cloud::Workloadmanager::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
