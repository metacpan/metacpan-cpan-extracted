package Google::Cloud::Run::V2::Execution::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetExecutionRequest',
    as InstanceOf['Google::Cloud::Run::V2::Execution::GetExecutionRequest'];

coerce 'GetExecutionRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::GetExecutionRequest'->new($_) };

declare 'RepeatedGetExecutionRequest',
    as ArrayRef[GetExecutionRequest()];

coerce 'RepeatedGetExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::GetExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringGetExecutionRequest',
    as HashRef[GetExecutionRequest()];

declare 'ListExecutionsRequest',
    as InstanceOf['Google::Cloud::Run::V2::Execution::ListExecutionsRequest'];

coerce 'ListExecutionsRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::ListExecutionsRequest'->new($_) };

declare 'RepeatedListExecutionsRequest',
    as ArrayRef[ListExecutionsRequest()];

coerce 'RepeatedListExecutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::ListExecutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListExecutionsRequest',
    as HashRef[ListExecutionsRequest()];

declare 'ListExecutionsResponse',
    as InstanceOf['Google::Cloud::Run::V2::Execution::ListExecutionsResponse'];

coerce 'ListExecutionsResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::ListExecutionsResponse'->new($_) };

declare 'RepeatedListExecutionsResponse',
    as ArrayRef[ListExecutionsResponse()];

coerce 'RepeatedListExecutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::ListExecutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListExecutionsResponse',
    as HashRef[ListExecutionsResponse()];

declare 'DeleteExecutionRequest',
    as InstanceOf['Google::Cloud::Run::V2::Execution::DeleteExecutionRequest'];

coerce 'DeleteExecutionRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::DeleteExecutionRequest'->new($_) };

declare 'RepeatedDeleteExecutionRequest',
    as ArrayRef[DeleteExecutionRequest()];

coerce 'RepeatedDeleteExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::DeleteExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExecutionRequest',
    as HashRef[DeleteExecutionRequest()];

declare 'CancelExecutionRequest',
    as InstanceOf['Google::Cloud::Run::V2::Execution::CancelExecutionRequest'];

coerce 'CancelExecutionRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::CancelExecutionRequest'->new($_) };

declare 'RepeatedCancelExecutionRequest',
    as ArrayRef[CancelExecutionRequest()];

coerce 'RepeatedCancelExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::CancelExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringCancelExecutionRequest',
    as HashRef[CancelExecutionRequest()];

declare 'Execution',
    as InstanceOf['Google::Cloud::Run::V2::Execution::Execution'];

coerce 'Execution',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::Execution'->new($_) };

declare 'RepeatedExecution',
    as ArrayRef[Execution()];

coerce 'RepeatedExecution',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::Execution'->new($_) } @$_ ] };

declare 'MapStringExecution',
    as HashRef[Execution()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Execution::Execution::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::Execution::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::Execution::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Execution::Execution::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Execution::Execution::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Execution::Execution::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Execution::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
