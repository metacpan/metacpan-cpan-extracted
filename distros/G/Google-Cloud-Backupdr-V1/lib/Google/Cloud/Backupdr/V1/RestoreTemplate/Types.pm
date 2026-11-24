package Google::Cloud::Backupdr::V1::RestoreTemplate::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreTemplate',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate'];

coerce 'RestoreTemplate',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate'->new($_) };

declare 'RepeatedRestoreTemplate',
    as ArrayRef[RestoreTemplate()];

coerce 'RepeatedRestoreTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate'->new($_) } @$_ ] };

declare 'MapStringRestoreTemplate',
    as HashRef[RestoreTemplate()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RestoreTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ExecutionSummary',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::ExecutionSummary'];

coerce 'ExecutionSummary',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::ExecutionSummary'->new($_) };

declare 'RepeatedExecutionSummary',
    as ArrayRef[ExecutionSummary()];

coerce 'RepeatedExecutionSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::ExecutionSummary'->new($_) } @$_ ] };

declare 'MapStringExecutionSummary',
    as HashRef[ExecutionSummary()];

declare 'CreateRestoreTemplateRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::CreateRestoreTemplateRequest'];

coerce 'CreateRestoreTemplateRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::CreateRestoreTemplateRequest'->new($_) };

declare 'RepeatedCreateRestoreTemplateRequest',
    as ArrayRef[CreateRestoreTemplateRequest()];

coerce 'RepeatedCreateRestoreTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::CreateRestoreTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRestoreTemplateRequest',
    as HashRef[CreateRestoreTemplateRequest()];

declare 'GetRestoreTemplateRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::GetRestoreTemplateRequest'];

coerce 'GetRestoreTemplateRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::GetRestoreTemplateRequest'->new($_) };

declare 'RepeatedGetRestoreTemplateRequest',
    as ArrayRef[GetRestoreTemplateRequest()];

coerce 'RepeatedGetRestoreTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::GetRestoreTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetRestoreTemplateRequest',
    as HashRef[GetRestoreTemplateRequest()];

declare 'UpdateRestoreTemplateRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::UpdateRestoreTemplateRequest'];

coerce 'UpdateRestoreTemplateRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::UpdateRestoreTemplateRequest'->new($_) };

declare 'RepeatedUpdateRestoreTemplateRequest',
    as ArrayRef[UpdateRestoreTemplateRequest()];

coerce 'RepeatedUpdateRestoreTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::UpdateRestoreTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRestoreTemplateRequest',
    as HashRef[UpdateRestoreTemplateRequest()];

declare 'DeleteRestoreTemplateRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::DeleteRestoreTemplateRequest'];

coerce 'DeleteRestoreTemplateRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::DeleteRestoreTemplateRequest'->new($_) };

declare 'RepeatedDeleteRestoreTemplateRequest',
    as ArrayRef[DeleteRestoreTemplateRequest()];

coerce 'RepeatedDeleteRestoreTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::DeleteRestoreTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRestoreTemplateRequest',
    as HashRef[DeleteRestoreTemplateRequest()];

declare 'RunRestoreTemplateRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateRequest'];

coerce 'RunRestoreTemplateRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateRequest'->new($_) };

declare 'RepeatedRunRestoreTemplateRequest',
    as ArrayRef[RunRestoreTemplateRequest()];

coerce 'RepeatedRunRestoreTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringRunRestoreTemplateRequest',
    as HashRef[RunRestoreTemplateRequest()];

declare 'RunRestoreTemplateResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateResponse'];

coerce 'RunRestoreTemplateResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateResponse'->new($_) };

declare 'RepeatedRunRestoreTemplateResponse',
    as ArrayRef[RunRestoreTemplateResponse()];

coerce 'RepeatedRunRestoreTemplateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::RunRestoreTemplateResponse'->new($_) } @$_ ] };

declare 'MapStringRunRestoreTemplateResponse',
    as HashRef[RunRestoreTemplateResponse()];

declare 'ListRestoreTemplatesRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesRequest'];

coerce 'ListRestoreTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesRequest'->new($_) };

declare 'RepeatedListRestoreTemplatesRequest',
    as ArrayRef[ListRestoreTemplatesRequest()];

coerce 'RepeatedListRestoreTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListRestoreTemplatesRequest',
    as HashRef[ListRestoreTemplatesRequest()];

declare 'ListRestoreTemplatesResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesResponse'];

coerce 'ListRestoreTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesResponse'->new($_) };

declare 'RepeatedListRestoreTemplatesResponse',
    as ArrayRef[ListRestoreTemplatesResponse()];

coerce 'RepeatedListRestoreTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::RestoreTemplate::ListRestoreTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListRestoreTemplatesResponse',
    as HashRef[ListRestoreTemplatesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::RestoreTemplate::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
