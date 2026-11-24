package Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Environment',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'VersionConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::VersionConfig'];

coerce 'VersionConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::VersionConfig'->new($_) };

declare 'RepeatedVersionConfig',
    as ArrayRef[VersionConfig()];

coerce 'RepeatedVersionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::VersionConfig'->new($_) } @$_ ] };

declare 'MapStringVersionConfig',
    as HashRef[VersionConfig()];

declare 'TestCasesConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::TestCasesConfig'];

coerce 'TestCasesConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::TestCasesConfig'->new($_) };

declare 'RepeatedTestCasesConfig',
    as ArrayRef[TestCasesConfig()];

coerce 'RepeatedTestCasesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::TestCasesConfig'->new($_) } @$_ ] };

declare 'MapStringTestCasesConfig',
    as HashRef[TestCasesConfig()];

declare 'WebhookConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::WebhookConfig'];

coerce 'WebhookConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::WebhookConfig'->new($_) };

declare 'RepeatedWebhookConfig',
    as ArrayRef[WebhookConfig()];

coerce 'RepeatedWebhookConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Environment::WebhookConfig'->new($_) } @$_ ] };

declare 'MapStringWebhookConfig',
    as HashRef[WebhookConfig()];

declare 'ListEnvironmentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsRequest'];

coerce 'ListEnvironmentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsRequest'->new($_) };

declare 'RepeatedListEnvironmentsRequest',
    as ArrayRef[ListEnvironmentsRequest()];

coerce 'RepeatedListEnvironmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsRequest',
    as HashRef[ListEnvironmentsRequest()];

declare 'ListEnvironmentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsResponse'];

coerce 'ListEnvironmentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsResponse'->new($_) };

declare 'RepeatedListEnvironmentsResponse',
    as ArrayRef[ListEnvironmentsResponse()];

coerce 'RepeatedListEnvironmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListEnvironmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsResponse',
    as HashRef[ListEnvironmentsResponse()];

declare 'GetEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::GetEnvironmentRequest'];

coerce 'GetEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::GetEnvironmentRequest'->new($_) };

declare 'RepeatedGetEnvironmentRequest',
    as ArrayRef[GetEnvironmentRequest()];

coerce 'RepeatedGetEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::GetEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentRequest',
    as HashRef[GetEnvironmentRequest()];

declare 'CreateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::CreateEnvironmentRequest'];

coerce 'CreateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::CreateEnvironmentRequest'->new($_) };

declare 'RepeatedCreateEnvironmentRequest',
    as ArrayRef[CreateEnvironmentRequest()];

coerce 'RepeatedCreateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::CreateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEnvironmentRequest',
    as HashRef[CreateEnvironmentRequest()];

declare 'UpdateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::UpdateEnvironmentRequest'];

coerce 'UpdateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::UpdateEnvironmentRequest'->new($_) };

declare 'RepeatedUpdateEnvironmentRequest',
    as ArrayRef[UpdateEnvironmentRequest()];

coerce 'RepeatedUpdateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::UpdateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEnvironmentRequest',
    as HashRef[UpdateEnvironmentRequest()];

declare 'DeleteEnvironmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeleteEnvironmentRequest'];

coerce 'DeleteEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeleteEnvironmentRequest'->new($_) };

declare 'RepeatedDeleteEnvironmentRequest',
    as ArrayRef[DeleteEnvironmentRequest()];

coerce 'RepeatedDeleteEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeleteEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEnvironmentRequest',
    as HashRef[DeleteEnvironmentRequest()];

declare 'LookupEnvironmentHistoryRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::LookupEnvironmentHistoryRequest'];

coerce 'LookupEnvironmentHistoryRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::LookupEnvironmentHistoryRequest'->new($_) };

declare 'RepeatedLookupEnvironmentHistoryRequest',
    as ArrayRef[LookupEnvironmentHistoryRequest()];

coerce 'RepeatedLookupEnvironmentHistoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::LookupEnvironmentHistoryRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEnvironmentHistoryRequest',
    as HashRef[LookupEnvironmentHistoryRequest()];

declare 'LookupEnvironmentHistoryResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::LookupEnvironmentHistoryResponse'];

coerce 'LookupEnvironmentHistoryResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::LookupEnvironmentHistoryResponse'->new($_) };

declare 'RepeatedLookupEnvironmentHistoryResponse',
    as ArrayRef[LookupEnvironmentHistoryResponse()];

coerce 'RepeatedLookupEnvironmentHistoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::LookupEnvironmentHistoryResponse'->new($_) } @$_ ] };

declare 'MapStringLookupEnvironmentHistoryResponse',
    as HashRef[LookupEnvironmentHistoryResponse()];

declare 'ContinuousTestResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ContinuousTestResult'];

coerce 'ContinuousTestResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ContinuousTestResult'->new($_) };

declare 'RepeatedContinuousTestResult',
    as ArrayRef[ContinuousTestResult()];

coerce 'RepeatedContinuousTestResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ContinuousTestResult'->new($_) } @$_ ] };

declare 'MapStringContinuousTestResult',
    as HashRef[ContinuousTestResult()];

declare 'AggregatedTestResult',
    as (Int | Str);

declare 'RunContinuousTestRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestRequest'];

coerce 'RunContinuousTestRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestRequest'->new($_) };

declare 'RepeatedRunContinuousTestRequest',
    as ArrayRef[RunContinuousTestRequest()];

coerce 'RepeatedRunContinuousTestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestRequest'->new($_) } @$_ ] };

declare 'MapStringRunContinuousTestRequest',
    as HashRef[RunContinuousTestRequest()];

declare 'RunContinuousTestResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestResponse'];

coerce 'RunContinuousTestResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestResponse'->new($_) };

declare 'RepeatedRunContinuousTestResponse',
    as ArrayRef[RunContinuousTestResponse()];

coerce 'RepeatedRunContinuousTestResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestResponse'->new($_) } @$_ ] };

declare 'MapStringRunContinuousTestResponse',
    as HashRef[RunContinuousTestResponse()];

declare 'RunContinuousTestMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestMetadata'];

coerce 'RunContinuousTestMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestMetadata'->new($_) };

declare 'RepeatedRunContinuousTestMetadata',
    as ArrayRef[RunContinuousTestMetadata()];

coerce 'RepeatedRunContinuousTestMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::RunContinuousTestMetadata'->new($_) } @$_ ] };

declare 'MapStringRunContinuousTestMetadata',
    as HashRef[RunContinuousTestMetadata()];

declare 'ListContinuousTestResultsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListContinuousTestResultsRequest'];

coerce 'ListContinuousTestResultsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListContinuousTestResultsRequest'->new($_) };

declare 'RepeatedListContinuousTestResultsRequest',
    as ArrayRef[ListContinuousTestResultsRequest()];

coerce 'RepeatedListContinuousTestResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListContinuousTestResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListContinuousTestResultsRequest',
    as HashRef[ListContinuousTestResultsRequest()];

declare 'ListContinuousTestResultsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListContinuousTestResultsResponse'];

coerce 'ListContinuousTestResultsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListContinuousTestResultsResponse'->new($_) };

declare 'RepeatedListContinuousTestResultsResponse',
    as ArrayRef[ListContinuousTestResultsResponse()];

coerce 'RepeatedListContinuousTestResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::ListContinuousTestResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListContinuousTestResultsResponse',
    as HashRef[ListContinuousTestResultsResponse()];

declare 'DeployFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowRequest'];

coerce 'DeployFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowRequest'->new($_) };

declare 'RepeatedDeployFlowRequest',
    as ArrayRef[DeployFlowRequest()];

coerce 'RepeatedDeployFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowRequest'->new($_) } @$_ ] };

declare 'MapStringDeployFlowRequest',
    as HashRef[DeployFlowRequest()];

declare 'DeployFlowResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowResponse'];

coerce 'DeployFlowResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowResponse'->new($_) };

declare 'RepeatedDeployFlowResponse',
    as ArrayRef[DeployFlowResponse()];

coerce 'RepeatedDeployFlowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowResponse'->new($_) } @$_ ] };

declare 'MapStringDeployFlowResponse',
    as HashRef[DeployFlowResponse()];

declare 'DeployFlowMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowMetadata'];

coerce 'DeployFlowMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowMetadata'->new($_) };

declare 'RepeatedDeployFlowMetadata',
    as ArrayRef[DeployFlowMetadata()];

coerce 'RepeatedDeployFlowMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Environment::DeployFlowMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployFlowMetadata',
    as HashRef[DeployFlowMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Environment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
