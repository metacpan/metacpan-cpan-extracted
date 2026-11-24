package Google::Cloud::Dialogflow::Cx::V3::Intent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IntentView',
    as (Int | Str);

declare 'Intent',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::Intent'];

coerce 'Intent',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent'->new($_) };

declare 'RepeatedIntent',
    as ArrayRef[Intent()];

coerce 'RepeatedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent'->new($_) } @$_ ] };

declare 'MapStringIntent',
    as HashRef[Intent()];

declare 'TrainingPhrase',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::TrainingPhrase'];

coerce 'TrainingPhrase',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::TrainingPhrase'->new($_) };

declare 'RepeatedTrainingPhrase',
    as ArrayRef[TrainingPhrase()];

coerce 'RepeatedTrainingPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::TrainingPhrase'->new($_) } @$_ ] };

declare 'MapStringTrainingPhrase',
    as HashRef[TrainingPhrase()];

declare 'Part',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::TrainingPhrase::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::TrainingPhrase::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::TrainingPhrase::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'Parameter',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::Intent::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListIntentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest'];

coerce 'ListIntentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest'->new($_) };

declare 'RepeatedListIntentsRequest',
    as ArrayRef[ListIntentsRequest()];

coerce 'RepeatedListIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringListIntentsRequest',
    as HashRef[ListIntentsRequest()];

declare 'ListIntentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse'];

coerce 'ListIntentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse'->new($_) };

declare 'RepeatedListIntentsResponse',
    as ArrayRef[ListIntentsResponse()];

coerce 'RepeatedListIntentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ListIntentsResponse'->new($_) } @$_ ] };

declare 'MapStringListIntentsResponse',
    as HashRef[ListIntentsResponse()];

declare 'GetIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::GetIntentRequest'];

coerce 'GetIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::GetIntentRequest'->new($_) };

declare 'RepeatedGetIntentRequest',
    as ArrayRef[GetIntentRequest()];

coerce 'RepeatedGetIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::GetIntentRequest'->new($_) } @$_ ] };

declare 'MapStringGetIntentRequest',
    as HashRef[GetIntentRequest()];

declare 'CreateIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::CreateIntentRequest'];

coerce 'CreateIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::CreateIntentRequest'->new($_) };

declare 'RepeatedCreateIntentRequest',
    as ArrayRef[CreateIntentRequest()];

coerce 'RepeatedCreateIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::CreateIntentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIntentRequest',
    as HashRef[CreateIntentRequest()];

declare 'UpdateIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::UpdateIntentRequest'];

coerce 'UpdateIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::UpdateIntentRequest'->new($_) };

declare 'RepeatedUpdateIntentRequest',
    as ArrayRef[UpdateIntentRequest()];

coerce 'RepeatedUpdateIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::UpdateIntentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIntentRequest',
    as HashRef[UpdateIntentRequest()];

declare 'DeleteIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::DeleteIntentRequest'];

coerce 'DeleteIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::DeleteIntentRequest'->new($_) };

declare 'RepeatedDeleteIntentRequest',
    as ArrayRef[DeleteIntentRequest()];

coerce 'RepeatedDeleteIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::DeleteIntentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIntentRequest',
    as HashRef[DeleteIntentRequest()];

declare 'ImportIntentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsRequest'];

coerce 'ImportIntentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsRequest'->new($_) };

declare 'RepeatedImportIntentsRequest',
    as ArrayRef[ImportIntentsRequest()];

coerce 'RepeatedImportIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportIntentsRequest',
    as HashRef[ImportIntentsRequest()];

declare 'MergeOption',
    as (Int | Str);

declare 'ImportIntentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsResponse'];

coerce 'ImportIntentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsResponse'->new($_) };

declare 'RepeatedImportIntentsResponse',
    as ArrayRef[ImportIntentsResponse()];

coerce 'RepeatedImportIntentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsResponse'->new($_) } @$_ ] };

declare 'MapStringImportIntentsResponse',
    as HashRef[ImportIntentsResponse()];

declare 'ConflictingResources',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsResponse::ConflictingResources'];

coerce 'ConflictingResources',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsResponse::ConflictingResources'->new($_) };

declare 'RepeatedConflictingResources',
    as ArrayRef[ConflictingResources()];

coerce 'RepeatedConflictingResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsResponse::ConflictingResources'->new($_) } @$_ ] };

declare 'MapStringConflictingResources',
    as HashRef[ConflictingResources()];

declare 'ImportIntentsMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsMetadata'];

coerce 'ImportIntentsMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsMetadata'->new($_) };

declare 'RepeatedImportIntentsMetadata',
    as ArrayRef[ImportIntentsMetadata()];

coerce 'RepeatedImportIntentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ImportIntentsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportIntentsMetadata',
    as HashRef[ImportIntentsMetadata()];

declare 'ExportIntentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsRequest'];

coerce 'ExportIntentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsRequest'->new($_) };

declare 'RepeatedExportIntentsRequest',
    as ArrayRef[ExportIntentsRequest()];

coerce 'RepeatedExportIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringExportIntentsRequest',
    as HashRef[ExportIntentsRequest()];

declare 'DataFormat',
    as (Int | Str);

declare 'ExportIntentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsResponse'];

coerce 'ExportIntentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsResponse'->new($_) };

declare 'RepeatedExportIntentsResponse',
    as ArrayRef[ExportIntentsResponse()];

coerce 'RepeatedExportIntentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsResponse'->new($_) } @$_ ] };

declare 'MapStringExportIntentsResponse',
    as HashRef[ExportIntentsResponse()];

declare 'ExportIntentsMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsMetadata'];

coerce 'ExportIntentsMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsMetadata'->new($_) };

declare 'RepeatedExportIntentsMetadata',
    as ArrayRef[ExportIntentsMetadata()];

coerce 'RepeatedExportIntentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Intent::ExportIntentsMetadata'->new($_) } @$_ ] };

declare 'MapStringExportIntentsMetadata',
    as HashRef[ExportIntentsMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Intent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
