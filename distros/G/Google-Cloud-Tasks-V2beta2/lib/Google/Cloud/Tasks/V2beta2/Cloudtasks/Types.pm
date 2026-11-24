package Google::Cloud::Tasks::V2beta2::Cloudtasks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListQueuesRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::ListQueuesRequest'];

coerce 'ListQueuesRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListQueuesRequest'->new($_) };

declare 'RepeatedListQueuesRequest',
    as ArrayRef[ListQueuesRequest()];

coerce 'RepeatedListQueuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListQueuesRequest'->new($_) } @$_ ] };

declare 'MapStringListQueuesRequest',
    as HashRef[ListQueuesRequest()];

declare 'ListQueuesResponse',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::ListQueuesResponse'];

coerce 'ListQueuesResponse',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListQueuesResponse'->new($_) };

declare 'RepeatedListQueuesResponse',
    as ArrayRef[ListQueuesResponse()];

coerce 'RepeatedListQueuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListQueuesResponse'->new($_) } @$_ ] };

declare 'MapStringListQueuesResponse',
    as HashRef[ListQueuesResponse()];

declare 'GetQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::GetQueueRequest'];

coerce 'GetQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::GetQueueRequest'->new($_) };

declare 'RepeatedGetQueueRequest',
    as ArrayRef[GetQueueRequest()];

coerce 'RepeatedGetQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::GetQueueRequest'->new($_) } @$_ ] };

declare 'MapStringGetQueueRequest',
    as HashRef[GetQueueRequest()];

declare 'CreateQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::CreateQueueRequest'];

coerce 'CreateQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::CreateQueueRequest'->new($_) };

declare 'RepeatedCreateQueueRequest',
    as ArrayRef[CreateQueueRequest()];

coerce 'RepeatedCreateQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::CreateQueueRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQueueRequest',
    as HashRef[CreateQueueRequest()];

declare 'UpdateQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::UpdateQueueRequest'];

coerce 'UpdateQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::UpdateQueueRequest'->new($_) };

declare 'RepeatedUpdateQueueRequest',
    as ArrayRef[UpdateQueueRequest()];

coerce 'RepeatedUpdateQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::UpdateQueueRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateQueueRequest',
    as HashRef[UpdateQueueRequest()];

declare 'DeleteQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::DeleteQueueRequest'];

coerce 'DeleteQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::DeleteQueueRequest'->new($_) };

declare 'RepeatedDeleteQueueRequest',
    as ArrayRef[DeleteQueueRequest()];

coerce 'RepeatedDeleteQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::DeleteQueueRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQueueRequest',
    as HashRef[DeleteQueueRequest()];

declare 'PurgeQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::PurgeQueueRequest'];

coerce 'PurgeQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::PurgeQueueRequest'->new($_) };

declare 'RepeatedPurgeQueueRequest',
    as ArrayRef[PurgeQueueRequest()];

coerce 'RepeatedPurgeQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::PurgeQueueRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeQueueRequest',
    as HashRef[PurgeQueueRequest()];

declare 'PauseQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::PauseQueueRequest'];

coerce 'PauseQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::PauseQueueRequest'->new($_) };

declare 'RepeatedPauseQueueRequest',
    as ArrayRef[PauseQueueRequest()];

coerce 'RepeatedPauseQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::PauseQueueRequest'->new($_) } @$_ ] };

declare 'MapStringPauseQueueRequest',
    as HashRef[PauseQueueRequest()];

declare 'ResumeQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::ResumeQueueRequest'];

coerce 'ResumeQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ResumeQueueRequest'->new($_) };

declare 'RepeatedResumeQueueRequest',
    as ArrayRef[ResumeQueueRequest()];

coerce 'RepeatedResumeQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ResumeQueueRequest'->new($_) } @$_ ] };

declare 'MapStringResumeQueueRequest',
    as HashRef[ResumeQueueRequest()];

declare 'UploadQueueYamlRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::UploadQueueYamlRequest'];

coerce 'UploadQueueYamlRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::UploadQueueYamlRequest'->new($_) };

declare 'RepeatedUploadQueueYamlRequest',
    as ArrayRef[UploadQueueYamlRequest()];

coerce 'RepeatedUploadQueueYamlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::UploadQueueYamlRequest'->new($_) } @$_ ] };

declare 'MapStringUploadQueueYamlRequest',
    as HashRef[UploadQueueYamlRequest()];

declare 'ListTasksRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::ListTasksRequest'];

coerce 'ListTasksRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListTasksRequest'->new($_) };

declare 'RepeatedListTasksRequest',
    as ArrayRef[ListTasksRequest()];

coerce 'RepeatedListTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListTasksRequest'->new($_) } @$_ ] };

declare 'MapStringListTasksRequest',
    as HashRef[ListTasksRequest()];

declare 'ListTasksResponse',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::ListTasksResponse'];

coerce 'ListTasksResponse',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListTasksResponse'->new($_) };

declare 'RepeatedListTasksResponse',
    as ArrayRef[ListTasksResponse()];

coerce 'RepeatedListTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::ListTasksResponse'->new($_) } @$_ ] };

declare 'MapStringListTasksResponse',
    as HashRef[ListTasksResponse()];

declare 'GetTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::GetTaskRequest'];

coerce 'GetTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::GetTaskRequest'->new($_) };

declare 'RepeatedGetTaskRequest',
    as ArrayRef[GetTaskRequest()];

coerce 'RepeatedGetTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::GetTaskRequest'->new($_) } @$_ ] };

declare 'MapStringGetTaskRequest',
    as HashRef[GetTaskRequest()];

declare 'CreateTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::CreateTaskRequest'];

coerce 'CreateTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::CreateTaskRequest'->new($_) };

declare 'RepeatedCreateTaskRequest',
    as ArrayRef[CreateTaskRequest()];

coerce 'RepeatedCreateTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::CreateTaskRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTaskRequest',
    as HashRef[CreateTaskRequest()];

declare 'DeleteTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::DeleteTaskRequest'];

coerce 'DeleteTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::DeleteTaskRequest'->new($_) };

declare 'RepeatedDeleteTaskRequest',
    as ArrayRef[DeleteTaskRequest()];

coerce 'RepeatedDeleteTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::DeleteTaskRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTaskRequest',
    as HashRef[DeleteTaskRequest()];

declare 'LeaseTasksRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::LeaseTasksRequest'];

coerce 'LeaseTasksRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::LeaseTasksRequest'->new($_) };

declare 'RepeatedLeaseTasksRequest',
    as ArrayRef[LeaseTasksRequest()];

coerce 'RepeatedLeaseTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::LeaseTasksRequest'->new($_) } @$_ ] };

declare 'MapStringLeaseTasksRequest',
    as HashRef[LeaseTasksRequest()];

declare 'LeaseTasksResponse',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::LeaseTasksResponse'];

coerce 'LeaseTasksResponse',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::LeaseTasksResponse'->new($_) };

declare 'RepeatedLeaseTasksResponse',
    as ArrayRef[LeaseTasksResponse()];

coerce 'RepeatedLeaseTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::LeaseTasksResponse'->new($_) } @$_ ] };

declare 'MapStringLeaseTasksResponse',
    as HashRef[LeaseTasksResponse()];

declare 'AcknowledgeTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::AcknowledgeTaskRequest'];

coerce 'AcknowledgeTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::AcknowledgeTaskRequest'->new($_) };

declare 'RepeatedAcknowledgeTaskRequest',
    as ArrayRef[AcknowledgeTaskRequest()];

coerce 'RepeatedAcknowledgeTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::AcknowledgeTaskRequest'->new($_) } @$_ ] };

declare 'MapStringAcknowledgeTaskRequest',
    as HashRef[AcknowledgeTaskRequest()];

declare 'RenewLeaseRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::RenewLeaseRequest'];

coerce 'RenewLeaseRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::RenewLeaseRequest'->new($_) };

declare 'RepeatedRenewLeaseRequest',
    as ArrayRef[RenewLeaseRequest()];

coerce 'RepeatedRenewLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::RenewLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringRenewLeaseRequest',
    as HashRef[RenewLeaseRequest()];

declare 'CancelLeaseRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::CancelLeaseRequest'];

coerce 'CancelLeaseRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::CancelLeaseRequest'->new($_) };

declare 'RepeatedCancelLeaseRequest',
    as ArrayRef[CancelLeaseRequest()];

coerce 'RepeatedCancelLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::CancelLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringCancelLeaseRequest',
    as HashRef[CancelLeaseRequest()];

declare 'RunTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Cloudtasks::RunTaskRequest'];

coerce 'RunTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::RunTaskRequest'->new($_) };

declare 'RepeatedRunTaskRequest',
    as ArrayRef[RunTaskRequest()];

coerce 'RepeatedRunTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Cloudtasks::RunTaskRequest'->new($_) } @$_ ] };

declare 'MapStringRunTaskRequest',
    as HashRef[RunTaskRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta2::Cloudtasks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
