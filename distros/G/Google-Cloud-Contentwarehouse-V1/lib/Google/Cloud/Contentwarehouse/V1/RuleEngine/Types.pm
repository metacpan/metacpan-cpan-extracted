package Google::Cloud::Contentwarehouse::V1::RuleEngine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RuleSet',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet'];

coerce 'RuleSet',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet'->new($_) };

declare 'RepeatedRuleSet',
    as ArrayRef[RuleSet()];

coerce 'RepeatedRuleSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet'->new($_) } @$_ ] };

declare 'MapStringRuleSet',
    as HashRef[RuleSet()];

declare 'Rule',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'TriggerType',
    as (Int | Str);

declare 'Action',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'AccessControlAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::AccessControlAction'];

coerce 'AccessControlAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::AccessControlAction'->new($_) };

declare 'RepeatedAccessControlAction',
    as ArrayRef[AccessControlAction()];

coerce 'RepeatedAccessControlAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::AccessControlAction'->new($_) } @$_ ] };

declare 'MapStringAccessControlAction',
    as HashRef[AccessControlAction()];

declare 'OperationType',
    as (Int | Str);

declare 'DataValidationAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction'];

coerce 'DataValidationAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction'->new($_) };

declare 'RepeatedDataValidationAction',
    as ArrayRef[DataValidationAction()];

coerce 'RepeatedDataValidationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction'->new($_) } @$_ ] };

declare 'MapStringDataValidationAction',
    as HashRef[DataValidationAction()];

declare 'ConditionsEntry',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction::ConditionsEntry'];

coerce 'ConditionsEntry',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction::ConditionsEntry'->new($_) };

declare 'RepeatedConditionsEntry',
    as ArrayRef[ConditionsEntry()];

coerce 'RepeatedConditionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataValidationAction::ConditionsEntry'->new($_) } @$_ ] };

declare 'MapStringConditionsEntry',
    as HashRef[ConditionsEntry()];

declare 'DataUpdateAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction'];

coerce 'DataUpdateAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction'->new($_) };

declare 'RepeatedDataUpdateAction',
    as ArrayRef[DataUpdateAction()];

coerce 'RepeatedDataUpdateAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction'->new($_) } @$_ ] };

declare 'MapStringDataUpdateAction',
    as HashRef[DataUpdateAction()];

declare 'EntriesEntry',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction::EntriesEntry'];

coerce 'EntriesEntry',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction::EntriesEntry'->new($_) };

declare 'RepeatedEntriesEntry',
    as ArrayRef[EntriesEntry()];

coerce 'RepeatedEntriesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DataUpdateAction::EntriesEntry'->new($_) } @$_ ] };

declare 'MapStringEntriesEntry',
    as HashRef[EntriesEntry()];

declare 'AddToFolderAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::AddToFolderAction'];

coerce 'AddToFolderAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::AddToFolderAction'->new($_) };

declare 'RepeatedAddToFolderAction',
    as ArrayRef[AddToFolderAction()];

coerce 'RepeatedAddToFolderAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::AddToFolderAction'->new($_) } @$_ ] };

declare 'MapStringAddToFolderAction',
    as HashRef[AddToFolderAction()];

declare 'RemoveFromFolderAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::RemoveFromFolderAction'];

coerce 'RemoveFromFolderAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RemoveFromFolderAction'->new($_) };

declare 'RepeatedRemoveFromFolderAction',
    as ArrayRef[RemoveFromFolderAction()];

coerce 'RepeatedRemoveFromFolderAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RemoveFromFolderAction'->new($_) } @$_ ] };

declare 'MapStringRemoveFromFolderAction',
    as HashRef[RemoveFromFolderAction()];

declare 'PublishAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::PublishAction'];

coerce 'PublishAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::PublishAction'->new($_) };

declare 'RepeatedPublishAction',
    as ArrayRef[PublishAction()];

coerce 'RepeatedPublishAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::PublishAction'->new($_) } @$_ ] };

declare 'MapStringPublishAction',
    as HashRef[PublishAction()];

declare 'DeleteDocumentAction',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::DeleteDocumentAction'];

coerce 'DeleteDocumentAction',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DeleteDocumentAction'->new($_) };

declare 'RepeatedDeleteDocumentAction',
    as ArrayRef[DeleteDocumentAction()];

coerce 'RepeatedDeleteDocumentAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::DeleteDocumentAction'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentAction',
    as HashRef[DeleteDocumentAction()];

declare 'RuleEngineOutput',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput'];

coerce 'RuleEngineOutput',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput'->new($_) };

declare 'RepeatedRuleEngineOutput',
    as ArrayRef[RuleEngineOutput()];

coerce 'RepeatedRuleEngineOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEngineOutput'->new($_) } @$_ ] };

declare 'MapStringRuleEngineOutput',
    as HashRef[RuleEngineOutput()];

declare 'RuleEvaluatorOutput',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEvaluatorOutput'];

coerce 'RuleEvaluatorOutput',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEvaluatorOutput'->new($_) };

declare 'RepeatedRuleEvaluatorOutput',
    as ArrayRef[RuleEvaluatorOutput()];

coerce 'RepeatedRuleEvaluatorOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleEvaluatorOutput'->new($_) } @$_ ] };

declare 'MapStringRuleEvaluatorOutput',
    as HashRef[RuleEvaluatorOutput()];

declare 'InvalidRule',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::InvalidRule'];

coerce 'InvalidRule',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::InvalidRule'->new($_) };

declare 'RepeatedInvalidRule',
    as ArrayRef[InvalidRule()];

coerce 'RepeatedInvalidRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::InvalidRule'->new($_) } @$_ ] };

declare 'MapStringInvalidRule',
    as HashRef[InvalidRule()];

declare 'ActionExecutorOutput',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionExecutorOutput'];

coerce 'ActionExecutorOutput',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionExecutorOutput'->new($_) };

declare 'RepeatedActionExecutorOutput',
    as ArrayRef[ActionExecutorOutput()];

coerce 'RepeatedActionExecutorOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionExecutorOutput'->new($_) } @$_ ] };

declare 'MapStringActionExecutorOutput',
    as HashRef[ActionExecutorOutput()];

declare 'RuleActionsPair',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleActionsPair'];

coerce 'RuleActionsPair',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleActionsPair'->new($_) };

declare 'RepeatedRuleActionsPair',
    as ArrayRef[RuleActionsPair()];

coerce 'RepeatedRuleActionsPair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleActionsPair'->new($_) } @$_ ] };

declare 'MapStringRuleActionsPair',
    as HashRef[RuleActionsPair()];

declare 'ActionOutput',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionOutput'];

coerce 'ActionOutput',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionOutput'->new($_) };

declare 'RepeatedActionOutput',
    as ArrayRef[ActionOutput()];

coerce 'RepeatedActionOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::RuleEngine::ActionOutput'->new($_) } @$_ ] };

declare 'MapStringActionOutput',
    as HashRef[ActionOutput()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::RuleEngine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
