package Google::Cloud::Dialogflow::Cx::V3::Experiment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Experiment',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment'];

coerce 'Experiment',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment'->new($_) };

declare 'RepeatedExperiment',
    as ArrayRef[Experiment()];

coerce 'RepeatedExperiment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment'->new($_) } @$_ ] };

declare 'MapStringExperiment',
    as HashRef[Experiment()];

declare 'State',
    as (Int | Str);

declare 'Definition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Definition'];

coerce 'Definition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Definition'->new($_) };

declare 'RepeatedDefinition',
    as ArrayRef[Definition()];

coerce 'RepeatedDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Definition'->new($_) } @$_ ] };

declare 'MapStringDefinition',
    as HashRef[Definition()];

declare 'Result',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result'];

coerce 'Result',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result'->new($_) };

declare 'RepeatedResult',
    as ArrayRef[Result()];

coerce 'RepeatedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result'->new($_) } @$_ ] };

declare 'MapStringResult',
    as HashRef[Result()];

declare 'MetricType',
    as (Int | Str);

declare 'CountType',
    as (Int | Str);

declare 'ConfidenceInterval',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::ConfidenceInterval'];

coerce 'ConfidenceInterval',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::ConfidenceInterval'->new($_) };

declare 'RepeatedConfidenceInterval',
    as ArrayRef[ConfidenceInterval()];

coerce 'RepeatedConfidenceInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::ConfidenceInterval'->new($_) } @$_ ] };

declare 'MapStringConfidenceInterval',
    as HashRef[ConfidenceInterval()];

declare 'Metric',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::Metric'];

coerce 'Metric',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::Metric'->new($_) };

declare 'RepeatedMetric',
    as ArrayRef[Metric()];

coerce 'RepeatedMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::Metric'->new($_) } @$_ ] };

declare 'MapStringMetric',
    as HashRef[Metric()];

declare 'VersionMetrics',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::VersionMetrics'];

coerce 'VersionMetrics',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::VersionMetrics'->new($_) };

declare 'RepeatedVersionMetrics',
    as ArrayRef[VersionMetrics()];

coerce 'RepeatedVersionMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::Experiment::Result::VersionMetrics'->new($_) } @$_ ] };

declare 'MapStringVersionMetrics',
    as HashRef[VersionMetrics()];

declare 'VersionVariants',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::VersionVariants'];

coerce 'VersionVariants',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::VersionVariants'->new($_) };

declare 'RepeatedVersionVariants',
    as ArrayRef[VersionVariants()];

coerce 'RepeatedVersionVariants',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::VersionVariants'->new($_) } @$_ ] };

declare 'MapStringVersionVariants',
    as HashRef[VersionVariants()];

declare 'Variant',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::VersionVariants::Variant'];

coerce 'Variant',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::VersionVariants::Variant'->new($_) };

declare 'RepeatedVariant',
    as ArrayRef[Variant()];

coerce 'RepeatedVariant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::VersionVariants::Variant'->new($_) } @$_ ] };

declare 'MapStringVariant',
    as HashRef[Variant()];

declare 'VariantsHistory',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::VariantsHistory'];

coerce 'VariantsHistory',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::VariantsHistory'->new($_) };

declare 'RepeatedVariantsHistory',
    as ArrayRef[VariantsHistory()];

coerce 'RepeatedVariantsHistory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::VariantsHistory'->new($_) } @$_ ] };

declare 'MapStringVariantsHistory',
    as HashRef[VariantsHistory()];

declare 'RolloutConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutConfig'];

coerce 'RolloutConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutConfig'->new($_) };

declare 'RepeatedRolloutConfig',
    as ArrayRef[RolloutConfig()];

coerce 'RepeatedRolloutConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutConfig'->new($_) } @$_ ] };

declare 'MapStringRolloutConfig',
    as HashRef[RolloutConfig()];

declare 'RolloutStep',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutConfig::RolloutStep'];

coerce 'RolloutStep',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutConfig::RolloutStep'->new($_) };

declare 'RepeatedRolloutStep',
    as ArrayRef[RolloutStep()];

coerce 'RepeatedRolloutStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutConfig::RolloutStep'->new($_) } @$_ ] };

declare 'MapStringRolloutStep',
    as HashRef[RolloutStep()];

declare 'RolloutState',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutState'];

coerce 'RolloutState',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutState'->new($_) };

declare 'RepeatedRolloutState',
    as ArrayRef[RolloutState()];

coerce 'RepeatedRolloutState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::RolloutState'->new($_) } @$_ ] };

declare 'MapStringRolloutState',
    as HashRef[RolloutState()];

declare 'ListExperimentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsRequest'];

coerce 'ListExperimentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsRequest'->new($_) };

declare 'RepeatedListExperimentsRequest',
    as ArrayRef[ListExperimentsRequest()];

coerce 'RepeatedListExperimentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsRequest'->new($_) } @$_ ] };

declare 'MapStringListExperimentsRequest',
    as HashRef[ListExperimentsRequest()];

declare 'ListExperimentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse'];

coerce 'ListExperimentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse'->new($_) };

declare 'RepeatedListExperimentsResponse',
    as ArrayRef[ListExperimentsResponse()];

coerce 'RepeatedListExperimentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::ListExperimentsResponse'->new($_) } @$_ ] };

declare 'MapStringListExperimentsResponse',
    as HashRef[ListExperimentsResponse()];

declare 'GetExperimentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::GetExperimentRequest'];

coerce 'GetExperimentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::GetExperimentRequest'->new($_) };

declare 'RepeatedGetExperimentRequest',
    as ArrayRef[GetExperimentRequest()];

coerce 'RepeatedGetExperimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::GetExperimentRequest'->new($_) } @$_ ] };

declare 'MapStringGetExperimentRequest',
    as HashRef[GetExperimentRequest()];

declare 'CreateExperimentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::CreateExperimentRequest'];

coerce 'CreateExperimentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::CreateExperimentRequest'->new($_) };

declare 'RepeatedCreateExperimentRequest',
    as ArrayRef[CreateExperimentRequest()];

coerce 'RepeatedCreateExperimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::CreateExperimentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExperimentRequest',
    as HashRef[CreateExperimentRequest()];

declare 'UpdateExperimentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::UpdateExperimentRequest'];

coerce 'UpdateExperimentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::UpdateExperimentRequest'->new($_) };

declare 'RepeatedUpdateExperimentRequest',
    as ArrayRef[UpdateExperimentRequest()];

coerce 'RepeatedUpdateExperimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::UpdateExperimentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExperimentRequest',
    as HashRef[UpdateExperimentRequest()];

declare 'DeleteExperimentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::DeleteExperimentRequest'];

coerce 'DeleteExperimentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::DeleteExperimentRequest'->new($_) };

declare 'RepeatedDeleteExperimentRequest',
    as ArrayRef[DeleteExperimentRequest()];

coerce 'RepeatedDeleteExperimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::DeleteExperimentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExperimentRequest',
    as HashRef[DeleteExperimentRequest()];

declare 'StartExperimentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::StartExperimentRequest'];

coerce 'StartExperimentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::StartExperimentRequest'->new($_) };

declare 'RepeatedStartExperimentRequest',
    as ArrayRef[StartExperimentRequest()];

coerce 'RepeatedStartExperimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::StartExperimentRequest'->new($_) } @$_ ] };

declare 'MapStringStartExperimentRequest',
    as HashRef[StartExperimentRequest()];

declare 'StopExperimentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Experiment::StopExperimentRequest'];

coerce 'StopExperimentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::StopExperimentRequest'->new($_) };

declare 'RepeatedStopExperimentRequest',
    as ArrayRef[StopExperimentRequest()];

coerce 'RepeatedStopExperimentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Experiment::StopExperimentRequest'->new($_) } @$_ ] };

declare 'MapStringStopExperimentRequest',
    as HashRef[StopExperimentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Experiment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
