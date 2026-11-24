package Google::Cloud::Dialogflow::Cx::V3::Playbook::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreatePlaybookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookRequest'];

coerce 'CreatePlaybookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookRequest'->new($_) };

declare 'RepeatedCreatePlaybookRequest',
    as ArrayRef[CreatePlaybookRequest()];

coerce 'RepeatedCreatePlaybookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePlaybookRequest',
    as HashRef[CreatePlaybookRequest()];

declare 'DeletePlaybookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::DeletePlaybookRequest'];

coerce 'DeletePlaybookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::DeletePlaybookRequest'->new($_) };

declare 'RepeatedDeletePlaybookRequest',
    as ArrayRef[DeletePlaybookRequest()];

coerce 'RepeatedDeletePlaybookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::DeletePlaybookRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePlaybookRequest',
    as HashRef[DeletePlaybookRequest()];

declare 'ListPlaybooksRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybooksRequest'];

coerce 'ListPlaybooksRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybooksRequest'->new($_) };

declare 'RepeatedListPlaybooksRequest',
    as ArrayRef[ListPlaybooksRequest()];

coerce 'RepeatedListPlaybooksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybooksRequest'->new($_) } @$_ ] };

declare 'MapStringListPlaybooksRequest',
    as HashRef[ListPlaybooksRequest()];

declare 'ListPlaybooksResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybooksResponse'];

coerce 'ListPlaybooksResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybooksResponse'->new($_) };

declare 'RepeatedListPlaybooksResponse',
    as ArrayRef[ListPlaybooksResponse()];

coerce 'RepeatedListPlaybooksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybooksResponse'->new($_) } @$_ ] };

declare 'MapStringListPlaybooksResponse',
    as HashRef[ListPlaybooksResponse()];

declare 'GetPlaybookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::GetPlaybookRequest'];

coerce 'GetPlaybookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::GetPlaybookRequest'->new($_) };

declare 'RepeatedGetPlaybookRequest',
    as ArrayRef[GetPlaybookRequest()];

coerce 'RepeatedGetPlaybookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::GetPlaybookRequest'->new($_) } @$_ ] };

declare 'MapStringGetPlaybookRequest',
    as HashRef[GetPlaybookRequest()];

declare 'UpdatePlaybookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::UpdatePlaybookRequest'];

coerce 'UpdatePlaybookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::UpdatePlaybookRequest'->new($_) };

declare 'RepeatedUpdatePlaybookRequest',
    as ArrayRef[UpdatePlaybookRequest()];

coerce 'RepeatedUpdatePlaybookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::UpdatePlaybookRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePlaybookRequest',
    as HashRef[UpdatePlaybookRequest()];

declare 'Playbook',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook'];

coerce 'Playbook',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook'->new($_) };

declare 'RepeatedPlaybook',
    as ArrayRef[Playbook()];

coerce 'RepeatedPlaybook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook'->new($_) } @$_ ] };

declare 'MapStringPlaybook',
    as HashRef[Playbook()];

declare 'PlaybookType',
    as (Int | Str);

declare 'Step',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'Instruction',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook::Instruction'];

coerce 'Instruction',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook::Instruction'->new($_) };

declare 'RepeatedInstruction',
    as ArrayRef[Instruction()];

coerce 'RepeatedInstruction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Playbook::Instruction'->new($_) } @$_ ] };

declare 'MapStringInstruction',
    as HashRef[Instruction()];

declare 'CreatePlaybookVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookVersionRequest'];

coerce 'CreatePlaybookVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookVersionRequest'->new($_) };

declare 'RepeatedCreatePlaybookVersionRequest',
    as ArrayRef[CreatePlaybookVersionRequest()];

coerce 'RepeatedCreatePlaybookVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::CreatePlaybookVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePlaybookVersionRequest',
    as HashRef[CreatePlaybookVersionRequest()];

declare 'PlaybookVersion',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::PlaybookVersion'];

coerce 'PlaybookVersion',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::PlaybookVersion'->new($_) };

declare 'RepeatedPlaybookVersion',
    as ArrayRef[PlaybookVersion()];

coerce 'RepeatedPlaybookVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::PlaybookVersion'->new($_) } @$_ ] };

declare 'MapStringPlaybookVersion',
    as HashRef[PlaybookVersion()];

declare 'GetPlaybookVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::GetPlaybookVersionRequest'];

coerce 'GetPlaybookVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::GetPlaybookVersionRequest'->new($_) };

declare 'RepeatedGetPlaybookVersionRequest',
    as ArrayRef[GetPlaybookVersionRequest()];

coerce 'RepeatedGetPlaybookVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::GetPlaybookVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetPlaybookVersionRequest',
    as HashRef[GetPlaybookVersionRequest()];

declare 'RestorePlaybookVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::RestorePlaybookVersionRequest'];

coerce 'RestorePlaybookVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::RestorePlaybookVersionRequest'->new($_) };

declare 'RepeatedRestorePlaybookVersionRequest',
    as ArrayRef[RestorePlaybookVersionRequest()];

coerce 'RepeatedRestorePlaybookVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::RestorePlaybookVersionRequest'->new($_) } @$_ ] };

declare 'MapStringRestorePlaybookVersionRequest',
    as HashRef[RestorePlaybookVersionRequest()];

declare 'RestorePlaybookVersionResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::RestorePlaybookVersionResponse'];

coerce 'RestorePlaybookVersionResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::RestorePlaybookVersionResponse'->new($_) };

declare 'RepeatedRestorePlaybookVersionResponse',
    as ArrayRef[RestorePlaybookVersionResponse()];

coerce 'RepeatedRestorePlaybookVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::RestorePlaybookVersionResponse'->new($_) } @$_ ] };

declare 'MapStringRestorePlaybookVersionResponse',
    as HashRef[RestorePlaybookVersionResponse()];

declare 'ListPlaybookVersionsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybookVersionsRequest'];

coerce 'ListPlaybookVersionsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybookVersionsRequest'->new($_) };

declare 'RepeatedListPlaybookVersionsRequest',
    as ArrayRef[ListPlaybookVersionsRequest()];

coerce 'RepeatedListPlaybookVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybookVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPlaybookVersionsRequest',
    as HashRef[ListPlaybookVersionsRequest()];

declare 'ListPlaybookVersionsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybookVersionsResponse'];

coerce 'ListPlaybookVersionsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybookVersionsResponse'->new($_) };

declare 'RepeatedListPlaybookVersionsResponse',
    as ArrayRef[ListPlaybookVersionsResponse()];

coerce 'RepeatedListPlaybookVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ListPlaybookVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPlaybookVersionsResponse',
    as HashRef[ListPlaybookVersionsResponse()];

declare 'DeletePlaybookVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::DeletePlaybookVersionRequest'];

coerce 'DeletePlaybookVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::DeletePlaybookVersionRequest'->new($_) };

declare 'RepeatedDeletePlaybookVersionRequest',
    as ArrayRef[DeletePlaybookVersionRequest()];

coerce 'RepeatedDeletePlaybookVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::DeletePlaybookVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePlaybookVersionRequest',
    as HashRef[DeletePlaybookVersionRequest()];

declare 'ExportPlaybookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ExportPlaybookRequest'];

coerce 'ExportPlaybookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ExportPlaybookRequest'->new($_) };

declare 'RepeatedExportPlaybookRequest',
    as ArrayRef[ExportPlaybookRequest()];

coerce 'RepeatedExportPlaybookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ExportPlaybookRequest'->new($_) } @$_ ] };

declare 'MapStringExportPlaybookRequest',
    as HashRef[ExportPlaybookRequest()];

declare 'DataFormat',
    as (Int | Str);

declare 'ImportPlaybookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookRequest'];

coerce 'ImportPlaybookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookRequest'->new($_) };

declare 'RepeatedImportPlaybookRequest',
    as ArrayRef[ImportPlaybookRequest()];

coerce 'RepeatedImportPlaybookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookRequest'->new($_) } @$_ ] };

declare 'MapStringImportPlaybookRequest',
    as HashRef[ImportPlaybookRequest()];

declare 'PlaybookImportStrategy',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::PlaybookImportStrategy'];

coerce 'PlaybookImportStrategy',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::PlaybookImportStrategy'->new($_) };

declare 'RepeatedPlaybookImportStrategy',
    as ArrayRef[PlaybookImportStrategy()];

coerce 'RepeatedPlaybookImportStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::PlaybookImportStrategy'->new($_) } @$_ ] };

declare 'MapStringPlaybookImportStrategy',
    as HashRef[PlaybookImportStrategy()];

declare 'ImportPlaybookResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookResponse'];

coerce 'ImportPlaybookResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookResponse'->new($_) };

declare 'RepeatedImportPlaybookResponse',
    as ArrayRef[ImportPlaybookResponse()];

coerce 'RepeatedImportPlaybookResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookResponse'->new($_) } @$_ ] };

declare 'MapStringImportPlaybookResponse',
    as HashRef[ImportPlaybookResponse()];

declare 'ConflictingResources',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookResponse::ConflictingResources'];

coerce 'ConflictingResources',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookResponse::ConflictingResources'->new($_) };

declare 'RepeatedConflictingResources',
    as ArrayRef[ConflictingResources()];

coerce 'RepeatedConflictingResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ImportPlaybookResponse::ConflictingResources'->new($_) } @$_ ] };

declare 'MapStringConflictingResources',
    as HashRef[ConflictingResources()];

declare 'ExportPlaybookResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::ExportPlaybookResponse'];

coerce 'ExportPlaybookResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ExportPlaybookResponse'->new($_) };

declare 'RepeatedExportPlaybookResponse',
    as ArrayRef[ExportPlaybookResponse()];

coerce 'RepeatedExportPlaybookResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::ExportPlaybookResponse'->new($_) } @$_ ] };

declare 'MapStringExportPlaybookResponse',
    as HashRef[ExportPlaybookResponse()];

declare 'Handler',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler'];

coerce 'Handler',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler'->new($_) };

declare 'RepeatedHandler',
    as ArrayRef[Handler()];

coerce 'RepeatedHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler'->new($_) } @$_ ] };

declare 'MapStringHandler',
    as HashRef[Handler()];

declare 'EventHandler',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler::EventHandler'];

coerce 'EventHandler',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler::EventHandler'->new($_) };

declare 'RepeatedEventHandler',
    as ArrayRef[EventHandler()];

coerce 'RepeatedEventHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler::EventHandler'->new($_) } @$_ ] };

declare 'MapStringEventHandler',
    as HashRef[EventHandler()];

declare 'LifecycleHandler',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler::LifecycleHandler'];

coerce 'LifecycleHandler',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler::LifecycleHandler'->new($_) };

declare 'RepeatedLifecycleHandler',
    as ArrayRef[LifecycleHandler()];

coerce 'RepeatedLifecycleHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Playbook::Handler::LifecycleHandler'->new($_) } @$_ ] };

declare 'MapStringLifecycleHandler',
    as HashRef[LifecycleHandler()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Playbook::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
