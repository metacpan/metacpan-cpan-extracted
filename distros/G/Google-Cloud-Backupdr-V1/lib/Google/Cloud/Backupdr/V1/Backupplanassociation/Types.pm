package Google::Cloud::Backupdr::V1::Backupplanassociation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupPlanAssociation',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::BackupPlanAssociation'];

coerce 'BackupPlanAssociation',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::BackupPlanAssociation'->new($_) };

declare 'RepeatedBackupPlanAssociation',
    as ArrayRef[BackupPlanAssociation()];

coerce 'RepeatedBackupPlanAssociation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::BackupPlanAssociation'->new($_) } @$_ ] };

declare 'MapStringBackupPlanAssociation',
    as HashRef[BackupPlanAssociation()];

declare 'State',
    as (Int | Str);

declare 'RuleConfigInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::RuleConfigInfo'];

coerce 'RuleConfigInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::RuleConfigInfo'->new($_) };

declare 'RepeatedRuleConfigInfo',
    as ArrayRef[RuleConfigInfo()];

coerce 'RepeatedRuleConfigInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::RuleConfigInfo'->new($_) } @$_ ] };

declare 'MapStringRuleConfigInfo',
    as HashRef[RuleConfigInfo()];

declare 'LastBackupState',
    as (Int | Str);

declare 'CreateBackupPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::CreateBackupPlanAssociationRequest'];

coerce 'CreateBackupPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::CreateBackupPlanAssociationRequest'->new($_) };

declare 'RepeatedCreateBackupPlanAssociationRequest',
    as ArrayRef[CreateBackupPlanAssociationRequest()];

coerce 'RepeatedCreateBackupPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::CreateBackupPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupPlanAssociationRequest',
    as HashRef[CreateBackupPlanAssociationRequest()];

declare 'ListBackupPlanAssociationsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::ListBackupPlanAssociationsRequest'];

coerce 'ListBackupPlanAssociationsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::ListBackupPlanAssociationsRequest'->new($_) };

declare 'RepeatedListBackupPlanAssociationsRequest',
    as ArrayRef[ListBackupPlanAssociationsRequest()];

coerce 'RepeatedListBackupPlanAssociationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::ListBackupPlanAssociationsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupPlanAssociationsRequest',
    as HashRef[ListBackupPlanAssociationsRequest()];

declare 'ListBackupPlanAssociationsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::ListBackupPlanAssociationsResponse'];

coerce 'ListBackupPlanAssociationsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::ListBackupPlanAssociationsResponse'->new($_) };

declare 'RepeatedListBackupPlanAssociationsResponse',
    as ArrayRef[ListBackupPlanAssociationsResponse()];

coerce 'RepeatedListBackupPlanAssociationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::ListBackupPlanAssociationsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupPlanAssociationsResponse',
    as HashRef[ListBackupPlanAssociationsResponse()];

declare 'FetchBackupPlanAssociationsForResourceTypeRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::FetchBackupPlanAssociationsForResourceTypeRequest'];

coerce 'FetchBackupPlanAssociationsForResourceTypeRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::FetchBackupPlanAssociationsForResourceTypeRequest'->new($_) };

declare 'RepeatedFetchBackupPlanAssociationsForResourceTypeRequest',
    as ArrayRef[FetchBackupPlanAssociationsForResourceTypeRequest()];

coerce 'RepeatedFetchBackupPlanAssociationsForResourceTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::FetchBackupPlanAssociationsForResourceTypeRequest'->new($_) } @$_ ] };

declare 'MapStringFetchBackupPlanAssociationsForResourceTypeRequest',
    as HashRef[FetchBackupPlanAssociationsForResourceTypeRequest()];

declare 'FetchBackupPlanAssociationsForResourceTypeResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::FetchBackupPlanAssociationsForResourceTypeResponse'];

coerce 'FetchBackupPlanAssociationsForResourceTypeResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::FetchBackupPlanAssociationsForResourceTypeResponse'->new($_) };

declare 'RepeatedFetchBackupPlanAssociationsForResourceTypeResponse',
    as ArrayRef[FetchBackupPlanAssociationsForResourceTypeResponse()];

coerce 'RepeatedFetchBackupPlanAssociationsForResourceTypeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::FetchBackupPlanAssociationsForResourceTypeResponse'->new($_) } @$_ ] };

declare 'MapStringFetchBackupPlanAssociationsForResourceTypeResponse',
    as HashRef[FetchBackupPlanAssociationsForResourceTypeResponse()];

declare 'GetBackupPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::GetBackupPlanAssociationRequest'];

coerce 'GetBackupPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::GetBackupPlanAssociationRequest'->new($_) };

declare 'RepeatedGetBackupPlanAssociationRequest',
    as ArrayRef[GetBackupPlanAssociationRequest()];

coerce 'RepeatedGetBackupPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::GetBackupPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupPlanAssociationRequest',
    as HashRef[GetBackupPlanAssociationRequest()];

declare 'DeleteBackupPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::DeleteBackupPlanAssociationRequest'];

coerce 'DeleteBackupPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::DeleteBackupPlanAssociationRequest'->new($_) };

declare 'RepeatedDeleteBackupPlanAssociationRequest',
    as ArrayRef[DeleteBackupPlanAssociationRequest()];

coerce 'RepeatedDeleteBackupPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::DeleteBackupPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupPlanAssociationRequest',
    as HashRef[DeleteBackupPlanAssociationRequest()];

declare 'UpdateBackupPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::UpdateBackupPlanAssociationRequest'];

coerce 'UpdateBackupPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::UpdateBackupPlanAssociationRequest'->new($_) };

declare 'RepeatedUpdateBackupPlanAssociationRequest',
    as ArrayRef[UpdateBackupPlanAssociationRequest()];

coerce 'RepeatedUpdateBackupPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::UpdateBackupPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupPlanAssociationRequest',
    as HashRef[UpdateBackupPlanAssociationRequest()];

declare 'TriggerBackupRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupplanassociation::TriggerBackupRequest'];

coerce 'TriggerBackupRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupplanassociation::TriggerBackupRequest'->new($_) };

declare 'RepeatedTriggerBackupRequest',
    as ArrayRef[TriggerBackupRequest()];

coerce 'RepeatedTriggerBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupplanassociation::TriggerBackupRequest'->new($_) } @$_ ] };

declare 'MapStringTriggerBackupRequest',
    as HashRef[TriggerBackupRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::Backupplanassociation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
