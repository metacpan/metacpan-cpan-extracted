package Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreVerificationPlanAssociation',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation'];

coerce 'RestoreVerificationPlanAssociation',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation'->new($_) };

declare 'RepeatedRestoreVerificationPlanAssociation',
    as ArrayRef[RestoreVerificationPlanAssociation()];

coerce 'RepeatedRestoreVerificationPlanAssociation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation'->new($_) } @$_ ] };

declare 'MapStringRestoreVerificationPlanAssociation',
    as HashRef[RestoreVerificationPlanAssociation()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::RestoreVerificationPlanAssociation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TriggerSummary',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerSummary'];

coerce 'TriggerSummary',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerSummary'->new($_) };

declare 'RepeatedTriggerSummary',
    as ArrayRef[TriggerSummary()];

coerce 'RepeatedTriggerSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerSummary'->new($_) } @$_ ] };

declare 'MapStringTriggerSummary',
    as HashRef[TriggerSummary()];

declare 'CreateRestoreVerificationPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest'];

coerce 'CreateRestoreVerificationPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest'->new($_) };

declare 'RepeatedCreateRestoreVerificationPlanAssociationRequest',
    as ArrayRef[CreateRestoreVerificationPlanAssociationRequest()];

coerce 'RepeatedCreateRestoreVerificationPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::CreateRestoreVerificationPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRestoreVerificationPlanAssociationRequest',
    as HashRef[CreateRestoreVerificationPlanAssociationRequest()];

declare 'GetRestoreVerificationPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest'];

coerce 'GetRestoreVerificationPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest'->new($_) };

declare 'RepeatedGetRestoreVerificationPlanAssociationRequest',
    as ArrayRef[GetRestoreVerificationPlanAssociationRequest()];

coerce 'RepeatedGetRestoreVerificationPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::GetRestoreVerificationPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestoreVerificationPlanAssociationRequest',
    as HashRef[GetRestoreVerificationPlanAssociationRequest()];

declare 'ListRestoreVerificationPlanAssociationsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest'];

coerce 'ListRestoreVerificationPlanAssociationsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest'->new($_) };

declare 'RepeatedListRestoreVerificationPlanAssociationsRequest',
    as ArrayRef[ListRestoreVerificationPlanAssociationsRequest()];

coerce 'RepeatedListRestoreVerificationPlanAssociationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsRequest'->new($_) } @$_ ] };

declare 'MapStringListRestoreVerificationPlanAssociationsRequest',
    as HashRef[ListRestoreVerificationPlanAssociationsRequest()];

declare 'ListRestoreVerificationPlanAssociationsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse'];

coerce 'ListRestoreVerificationPlanAssociationsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse'->new($_) };

declare 'RepeatedListRestoreVerificationPlanAssociationsResponse',
    as ArrayRef[ListRestoreVerificationPlanAssociationsResponse()];

coerce 'RepeatedListRestoreVerificationPlanAssociationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::ListRestoreVerificationPlanAssociationsResponse'->new($_) } @$_ ] };

declare 'MapStringListRestoreVerificationPlanAssociationsResponse',
    as HashRef[ListRestoreVerificationPlanAssociationsResponse()];

declare 'DeleteRestoreVerificationPlanAssociationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest'];

coerce 'DeleteRestoreVerificationPlanAssociationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest'->new($_) };

declare 'RepeatedDeleteRestoreVerificationPlanAssociationRequest',
    as ArrayRef[DeleteRestoreVerificationPlanAssociationRequest()];

coerce 'RepeatedDeleteRestoreVerificationPlanAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::DeleteRestoreVerificationPlanAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRestoreVerificationPlanAssociationRequest',
    as HashRef[DeleteRestoreVerificationPlanAssociationRequest()];

declare 'TriggerRestoreVerificationRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest'];

coerce 'TriggerRestoreVerificationRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest'->new($_) };

declare 'RepeatedTriggerRestoreVerificationRequest',
    as ArrayRef[TriggerRestoreVerificationRequest()];

coerce 'RepeatedTriggerRestoreVerificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationRequest'->new($_) } @$_ ] };

declare 'MapStringTriggerRestoreVerificationRequest',
    as HashRef[TriggerRestoreVerificationRequest()];

declare 'TriggerRestoreVerificationResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse'];

coerce 'TriggerRestoreVerificationResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse'->new($_) };

declare 'RepeatedTriggerRestoreVerificationResponse',
    as ArrayRef[TriggerRestoreVerificationResponse()];

coerce 'RepeatedTriggerRestoreVerificationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::TriggerRestoreVerificationResponse'->new($_) } @$_ ] };

declare 'MapStringTriggerRestoreVerificationResponse',
    as HashRef[TriggerRestoreVerificationResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::RestoreVerificationPlanAssociation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
