package Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReceiveTaskNotificationRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest'];

coerce 'ReceiveTaskNotificationRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest'->new($_) };

declare 'RepeatedReceiveTaskNotificationRequest',
    as ArrayRef[ReceiveTaskNotificationRequest()];

coerce 'RepeatedReceiveTaskNotificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationRequest'->new($_) } @$_ ] };

declare 'MapStringReceiveTaskNotificationRequest',
    as HashRef[ReceiveTaskNotificationRequest()];

declare 'ReceiveTaskNotificationResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse'];

coerce 'ReceiveTaskNotificationResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse'->new($_) };

declare 'RepeatedReceiveTaskNotificationResponse',
    as ArrayRef[ReceiveTaskNotificationResponse()];

coerce 'RepeatedReceiveTaskNotificationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReceiveTaskNotificationResponse'->new($_) } @$_ ] };

declare 'MapStringReceiveTaskNotificationResponse',
    as HashRef[ReceiveTaskNotificationResponse()];

declare 'StartNextTaskRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest'];

coerce 'StartNextTaskRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest'->new($_) };

declare 'RepeatedStartNextTaskRequest',
    as ArrayRef[StartNextTaskRequest()];

coerce 'RepeatedStartNextTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskRequest'->new($_) } @$_ ] };

declare 'MapStringStartNextTaskRequest',
    as HashRef[StartNextTaskRequest()];

declare 'StartNextTaskResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse'];

coerce 'StartNextTaskResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse'->new($_) };

declare 'RepeatedStartNextTaskResponse',
    as ArrayRef[StartNextTaskResponse()];

coerce 'RepeatedStartNextTaskResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::StartNextTaskResponse'->new($_) } @$_ ] };

declare 'MapStringStartNextTaskResponse',
    as HashRef[StartNextTaskResponse()];

declare 'ReportTaskProgressRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest'];

coerce 'ReportTaskProgressRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest'->new($_) };

declare 'RepeatedReportTaskProgressRequest',
    as ArrayRef[ReportTaskProgressRequest()];

coerce 'RepeatedReportTaskProgressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressRequest'->new($_) } @$_ ] };

declare 'MapStringReportTaskProgressRequest',
    as HashRef[ReportTaskProgressRequest()];

declare 'ReportTaskProgressResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse'];

coerce 'ReportTaskProgressResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse'->new($_) };

declare 'RepeatedReportTaskProgressResponse',
    as ArrayRef[ReportTaskProgressResponse()];

coerce 'RepeatedReportTaskProgressResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskProgressResponse'->new($_) } @$_ ] };

declare 'MapStringReportTaskProgressResponse',
    as HashRef[ReportTaskProgressResponse()];

declare 'ReportTaskCompleteRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest'];

coerce 'ReportTaskCompleteRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest'->new($_) };

declare 'RepeatedReportTaskCompleteRequest',
    as ArrayRef[ReportTaskCompleteRequest()];

coerce 'RepeatedReportTaskCompleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteRequest'->new($_) } @$_ ] };

declare 'MapStringReportTaskCompleteRequest',
    as HashRef[ReportTaskCompleteRequest()];

declare 'ReportTaskCompleteResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse'];

coerce 'ReportTaskCompleteResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse'->new($_) };

declare 'RepeatedReportTaskCompleteResponse',
    as ArrayRef[ReportTaskCompleteResponse()];

coerce 'RepeatedReportTaskCompleteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportTaskCompleteResponse'->new($_) } @$_ ] };

declare 'MapStringReportTaskCompleteResponse',
    as HashRef[ReportTaskCompleteResponse()];

declare 'RegisterAgentRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest'];

coerce 'RegisterAgentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest'->new($_) };

declare 'RepeatedRegisterAgentRequest',
    as ArrayRef[RegisterAgentRequest()];

coerce 'RepeatedRegisterAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterAgentRequest',
    as HashRef[RegisterAgentRequest()];

declare 'RegisterAgentResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse'];

coerce 'RegisterAgentResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse'->new($_) };

declare 'RepeatedRegisterAgentResponse',
    as ArrayRef[RegisterAgentResponse()];

coerce 'RepeatedRegisterAgentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::RegisterAgentResponse'->new($_) } @$_ ] };

declare 'MapStringRegisterAgentResponse',
    as HashRef[RegisterAgentResponse()];

declare 'ReportInventoryRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest'];

coerce 'ReportInventoryRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest'->new($_) };

declare 'RepeatedReportInventoryRequest',
    as ArrayRef[ReportInventoryRequest()];

coerce 'RepeatedReportInventoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryRequest'->new($_) } @$_ ] };

declare 'MapStringReportInventoryRequest',
    as HashRef[ReportInventoryRequest()];

declare 'ReportInventoryResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse'];

coerce 'ReportInventoryResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse'->new($_) };

declare 'RepeatedReportInventoryResponse',
    as ArrayRef[ReportInventoryResponse()];

coerce 'RepeatedReportInventoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportInventoryResponse'->new($_) } @$_ ] };

declare 'MapStringReportInventoryResponse',
    as HashRef[ReportInventoryResponse()];

declare 'ReportVmInventoryRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest'];

coerce 'ReportVmInventoryRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest'->new($_) };

declare 'RepeatedReportVmInventoryRequest',
    as ArrayRef[ReportVmInventoryRequest()];

coerce 'RepeatedReportVmInventoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryRequest'->new($_) } @$_ ] };

declare 'MapStringReportVmInventoryRequest',
    as HashRef[ReportVmInventoryRequest()];

declare 'ReportVmInventoryResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse'];

coerce 'ReportVmInventoryResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse'->new($_) };

declare 'RepeatedReportVmInventoryResponse',
    as ArrayRef[ReportVmInventoryResponse()];

coerce 'RepeatedReportVmInventoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::ReportVmInventoryResponse'->new($_) } @$_ ] };

declare 'MapStringReportVmInventoryResponse',
    as HashRef[ReportVmInventoryResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::Agentendpoint::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
