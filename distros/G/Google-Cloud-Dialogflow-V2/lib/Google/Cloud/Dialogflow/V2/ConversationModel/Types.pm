package Google::Cloud::Dialogflow::V2::ConversationModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConversationModel',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ConversationModel'];

coerce 'ConversationModel',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ConversationModel'->new($_) };

declare 'RepeatedConversationModel',
    as ArrayRef[ConversationModel()];

coerce 'RepeatedConversationModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ConversationModel'->new($_) } @$_ ] };

declare 'MapStringConversationModel',
    as HashRef[ConversationModel()];

declare 'State',
    as (Int | Str);

declare 'ModelType',
    as (Int | Str);

declare 'ConversationModelEvaluation',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ConversationModelEvaluation'];

coerce 'ConversationModelEvaluation',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ConversationModelEvaluation'->new($_) };

declare 'RepeatedConversationModelEvaluation',
    as ArrayRef[ConversationModelEvaluation()];

coerce 'RepeatedConversationModelEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ConversationModelEvaluation'->new($_) } @$_ ] };

declare 'MapStringConversationModelEvaluation',
    as HashRef[ConversationModelEvaluation()];

declare 'EvaluationConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig'];

coerce 'EvaluationConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig'->new($_) };

declare 'RepeatedEvaluationConfig',
    as ArrayRef[EvaluationConfig()];

coerce 'RepeatedEvaluationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig'->new($_) } @$_ ] };

declare 'MapStringEvaluationConfig',
    as HashRef[EvaluationConfig()];

declare 'SmartReplyConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig::SmartReplyConfig'];

coerce 'SmartReplyConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig::SmartReplyConfig'->new($_) };

declare 'RepeatedSmartReplyConfig',
    as ArrayRef[SmartReplyConfig()];

coerce 'RepeatedSmartReplyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig::SmartReplyConfig'->new($_) } @$_ ] };

declare 'MapStringSmartReplyConfig',
    as HashRef[SmartReplyConfig()];

declare 'SmartComposeConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig::SmartComposeConfig'];

coerce 'SmartComposeConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig::SmartComposeConfig'->new($_) };

declare 'RepeatedSmartComposeConfig',
    as ArrayRef[SmartComposeConfig()];

coerce 'RepeatedSmartComposeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::EvaluationConfig::SmartComposeConfig'->new($_) } @$_ ] };

declare 'MapStringSmartComposeConfig',
    as HashRef[SmartComposeConfig()];

declare 'InputDataset',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::InputDataset'];

coerce 'InputDataset',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::InputDataset'->new($_) };

declare 'RepeatedInputDataset',
    as ArrayRef[InputDataset()];

coerce 'RepeatedInputDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::InputDataset'->new($_) } @$_ ] };

declare 'MapStringInputDataset',
    as HashRef[InputDataset()];

declare 'ArticleSuggestionModelMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ArticleSuggestionModelMetadata'];

coerce 'ArticleSuggestionModelMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ArticleSuggestionModelMetadata'->new($_) };

declare 'RepeatedArticleSuggestionModelMetadata',
    as ArrayRef[ArticleSuggestionModelMetadata()];

coerce 'RepeatedArticleSuggestionModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ArticleSuggestionModelMetadata'->new($_) } @$_ ] };

declare 'MapStringArticleSuggestionModelMetadata',
    as HashRef[ArticleSuggestionModelMetadata()];

declare 'SmartReplyModelMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyModelMetadata'];

coerce 'SmartReplyModelMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyModelMetadata'->new($_) };

declare 'RepeatedSmartReplyModelMetadata',
    as ArrayRef[SmartReplyModelMetadata()];

coerce 'RepeatedSmartReplyModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyModelMetadata'->new($_) } @$_ ] };

declare 'MapStringSmartReplyModelMetadata',
    as HashRef[SmartReplyModelMetadata()];

declare 'SmartReplyMetrics',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyMetrics'];

coerce 'SmartReplyMetrics',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyMetrics'->new($_) };

declare 'RepeatedSmartReplyMetrics',
    as ArrayRef[SmartReplyMetrics()];

coerce 'RepeatedSmartReplyMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyMetrics'->new($_) } @$_ ] };

declare 'MapStringSmartReplyMetrics',
    as HashRef[SmartReplyMetrics()];

declare 'TopNMetrics',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyMetrics::TopNMetrics'];

coerce 'TopNMetrics',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyMetrics::TopNMetrics'->new($_) };

declare 'RepeatedTopNMetrics',
    as ArrayRef[TopNMetrics()];

coerce 'RepeatedTopNMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::SmartReplyMetrics::TopNMetrics'->new($_) } @$_ ] };

declare 'MapStringTopNMetrics',
    as HashRef[TopNMetrics()];

declare 'CreateConversationModelRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelRequest'];

coerce 'CreateConversationModelRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelRequest'->new($_) };

declare 'RepeatedCreateConversationModelRequest',
    as ArrayRef[CreateConversationModelRequest()];

coerce 'RepeatedCreateConversationModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationModelRequest',
    as HashRef[CreateConversationModelRequest()];

declare 'GetConversationModelRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::GetConversationModelRequest'];

coerce 'GetConversationModelRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::GetConversationModelRequest'->new($_) };

declare 'RepeatedGetConversationModelRequest',
    as ArrayRef[GetConversationModelRequest()];

coerce 'RepeatedGetConversationModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::GetConversationModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationModelRequest',
    as HashRef[GetConversationModelRequest()];

declare 'ListConversationModelsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelsRequest'];

coerce 'ListConversationModelsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelsRequest'->new($_) };

declare 'RepeatedListConversationModelsRequest',
    as ArrayRef[ListConversationModelsRequest()];

coerce 'RepeatedListConversationModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationModelsRequest',
    as HashRef[ListConversationModelsRequest()];

declare 'ListConversationModelsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelsResponse'];

coerce 'ListConversationModelsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelsResponse'->new($_) };

declare 'RepeatedListConversationModelsResponse',
    as ArrayRef[ListConversationModelsResponse()];

coerce 'RepeatedListConversationModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationModelsResponse',
    as HashRef[ListConversationModelsResponse()];

declare 'DeleteConversationModelRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::DeleteConversationModelRequest'];

coerce 'DeleteConversationModelRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeleteConversationModelRequest'->new($_) };

declare 'RepeatedDeleteConversationModelRequest',
    as ArrayRef[DeleteConversationModelRequest()];

coerce 'RepeatedDeleteConversationModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeleteConversationModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationModelRequest',
    as HashRef[DeleteConversationModelRequest()];

declare 'DeployConversationModelRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::DeployConversationModelRequest'];

coerce 'DeployConversationModelRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeployConversationModelRequest'->new($_) };

declare 'RepeatedDeployConversationModelRequest',
    as ArrayRef[DeployConversationModelRequest()];

coerce 'RepeatedDeployConversationModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeployConversationModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeployConversationModelRequest',
    as HashRef[DeployConversationModelRequest()];

declare 'UndeployConversationModelRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::UndeployConversationModelRequest'];

coerce 'UndeployConversationModelRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::UndeployConversationModelRequest'->new($_) };

declare 'RepeatedUndeployConversationModelRequest',
    as ArrayRef[UndeployConversationModelRequest()];

coerce 'RepeatedUndeployConversationModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::UndeployConversationModelRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployConversationModelRequest',
    as HashRef[UndeployConversationModelRequest()];

declare 'GetConversationModelEvaluationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::GetConversationModelEvaluationRequest'];

coerce 'GetConversationModelEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::GetConversationModelEvaluationRequest'->new($_) };

declare 'RepeatedGetConversationModelEvaluationRequest',
    as ArrayRef[GetConversationModelEvaluationRequest()];

coerce 'RepeatedGetConversationModelEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::GetConversationModelEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationModelEvaluationRequest',
    as HashRef[GetConversationModelEvaluationRequest()];

declare 'ListConversationModelEvaluationsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelEvaluationsRequest'];

coerce 'ListConversationModelEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelEvaluationsRequest'->new($_) };

declare 'RepeatedListConversationModelEvaluationsRequest',
    as ArrayRef[ListConversationModelEvaluationsRequest()];

coerce 'RepeatedListConversationModelEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationModelEvaluationsRequest',
    as HashRef[ListConversationModelEvaluationsRequest()];

declare 'ListConversationModelEvaluationsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelEvaluationsResponse'];

coerce 'ListConversationModelEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelEvaluationsResponse'->new($_) };

declare 'RepeatedListConversationModelEvaluationsResponse',
    as ArrayRef[ListConversationModelEvaluationsResponse()];

coerce 'RepeatedListConversationModelEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::ListConversationModelEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationModelEvaluationsResponse',
    as HashRef[ListConversationModelEvaluationsResponse()];

declare 'CreateConversationModelEvaluationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelEvaluationRequest'];

coerce 'CreateConversationModelEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelEvaluationRequest'->new($_) };

declare 'RepeatedCreateConversationModelEvaluationRequest',
    as ArrayRef[CreateConversationModelEvaluationRequest()];

coerce 'RepeatedCreateConversationModelEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationModelEvaluationRequest',
    as HashRef[CreateConversationModelEvaluationRequest()];

declare 'CreateConversationModelOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelOperationMetadata'];

coerce 'CreateConversationModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelOperationMetadata'->new($_) };

declare 'RepeatedCreateConversationModelOperationMetadata',
    as ArrayRef[CreateConversationModelOperationMetadata()];

coerce 'RepeatedCreateConversationModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateConversationModelOperationMetadata',
    as HashRef[CreateConversationModelOperationMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeployConversationModelOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::DeployConversationModelOperationMetadata'];

coerce 'DeployConversationModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeployConversationModelOperationMetadata'->new($_) };

declare 'RepeatedDeployConversationModelOperationMetadata',
    as ArrayRef[DeployConversationModelOperationMetadata()];

coerce 'RepeatedDeployConversationModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeployConversationModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployConversationModelOperationMetadata',
    as HashRef[DeployConversationModelOperationMetadata()];

declare 'UndeployConversationModelOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::UndeployConversationModelOperationMetadata'];

coerce 'UndeployConversationModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::UndeployConversationModelOperationMetadata'->new($_) };

declare 'RepeatedUndeployConversationModelOperationMetadata',
    as ArrayRef[UndeployConversationModelOperationMetadata()];

coerce 'RepeatedUndeployConversationModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::UndeployConversationModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeployConversationModelOperationMetadata',
    as HashRef[UndeployConversationModelOperationMetadata()];

declare 'DeleteConversationModelOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::DeleteConversationModelOperationMetadata'];

coerce 'DeleteConversationModelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeleteConversationModelOperationMetadata'->new($_) };

declare 'RepeatedDeleteConversationModelOperationMetadata',
    as ArrayRef[DeleteConversationModelOperationMetadata()];

coerce 'RepeatedDeleteConversationModelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::DeleteConversationModelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationModelOperationMetadata',
    as HashRef[DeleteConversationModelOperationMetadata()];

declare 'CreateConversationModelEvaluationOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelEvaluationOperationMetadata'];

coerce 'CreateConversationModelEvaluationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelEvaluationOperationMetadata'->new($_) };

declare 'RepeatedCreateConversationModelEvaluationOperationMetadata',
    as ArrayRef[CreateConversationModelEvaluationOperationMetadata()];

coerce 'RepeatedCreateConversationModelEvaluationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::ConversationModel::CreateConversationModelEvaluationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateConversationModelEvaluationOperationMetadata',
    as HashRef[CreateConversationModelEvaluationOperationMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::ConversationModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
