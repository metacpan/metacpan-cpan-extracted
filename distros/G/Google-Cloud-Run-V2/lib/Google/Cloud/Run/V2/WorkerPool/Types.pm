package Google::Cloud::Run::V2::WorkerPool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateWorkerPoolRequest',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::CreateWorkerPoolRequest'];

coerce 'CreateWorkerPoolRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::CreateWorkerPoolRequest'->new($_) };

declare 'RepeatedCreateWorkerPoolRequest',
    as ArrayRef[CreateWorkerPoolRequest()];

coerce 'RepeatedCreateWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::CreateWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkerPoolRequest',
    as HashRef[CreateWorkerPoolRequest()];

declare 'UpdateWorkerPoolRequest',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::UpdateWorkerPoolRequest'];

coerce 'UpdateWorkerPoolRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::UpdateWorkerPoolRequest'->new($_) };

declare 'RepeatedUpdateWorkerPoolRequest',
    as ArrayRef[UpdateWorkerPoolRequest()];

coerce 'RepeatedUpdateWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::UpdateWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkerPoolRequest',
    as HashRef[UpdateWorkerPoolRequest()];

declare 'ListWorkerPoolsRequest',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::ListWorkerPoolsRequest'];

coerce 'ListWorkerPoolsRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::ListWorkerPoolsRequest'->new($_) };

declare 'RepeatedListWorkerPoolsRequest',
    as ArrayRef[ListWorkerPoolsRequest()];

coerce 'RepeatedListWorkerPoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::ListWorkerPoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkerPoolsRequest',
    as HashRef[ListWorkerPoolsRequest()];

declare 'ListWorkerPoolsResponse',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::ListWorkerPoolsResponse'];

coerce 'ListWorkerPoolsResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::ListWorkerPoolsResponse'->new($_) };

declare 'RepeatedListWorkerPoolsResponse',
    as ArrayRef[ListWorkerPoolsResponse()];

coerce 'RepeatedListWorkerPoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::ListWorkerPoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkerPoolsResponse',
    as HashRef[ListWorkerPoolsResponse()];

declare 'GetWorkerPoolRequest',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::GetWorkerPoolRequest'];

coerce 'GetWorkerPoolRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::GetWorkerPoolRequest'->new($_) };

declare 'RepeatedGetWorkerPoolRequest',
    as ArrayRef[GetWorkerPoolRequest()];

coerce 'RepeatedGetWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::GetWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkerPoolRequest',
    as HashRef[GetWorkerPoolRequest()];

declare 'DeleteWorkerPoolRequest',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::DeleteWorkerPoolRequest'];

coerce 'DeleteWorkerPoolRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::DeleteWorkerPoolRequest'->new($_) };

declare 'RepeatedDeleteWorkerPoolRequest',
    as ArrayRef[DeleteWorkerPoolRequest()];

coerce 'RepeatedDeleteWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::DeleteWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkerPoolRequest',
    as HashRef[DeleteWorkerPoolRequest()];

declare 'WorkerPool',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::WorkerPool'];

coerce 'WorkerPool',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::WorkerPool'->new($_) };

declare 'RepeatedWorkerPool',
    as ArrayRef[WorkerPool()];

coerce 'RepeatedWorkerPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::WorkerPool'->new($_) } @$_ ] };

declare 'MapStringWorkerPool',
    as HashRef[WorkerPool()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::WorkerPool::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::WorkerPool::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::WorkerPool::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::WorkerPool::WorkerPool::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::WorkerPool::WorkerPool::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::WorkerPool::WorkerPool::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::WorkerPool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
