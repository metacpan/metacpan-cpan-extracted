package Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReceiveTaskNotificationRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest'];

coerce 'ReceiveTaskNotificationRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest'->new($_) };

declare 'RepeatedReceiveTaskNotificationRequest',
    as ArrayRef[ReceiveTaskNotificationRequest()];

coerce 'RepeatedReceiveTaskNotificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest'->new($_) } @$_ ] };

declare 'MapStringReceiveTaskNotificationRequest',
    as HashRef[ReceiveTaskNotificationRequest()];

declare 'ReceiveTaskNotificationResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse'];

coerce 'ReceiveTaskNotificationResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse'->new($_) };

declare 'RepeatedReceiveTaskNotificationResponse',
    as ArrayRef[ReceiveTaskNotificationResponse()];

coerce 'RepeatedReceiveTaskNotificationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse'->new($_) } @$_ ] };

declare 'MapStringReceiveTaskNotificationResponse',
    as HashRef[ReceiveTaskNotificationResponse()];

declare 'StartNextTaskRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest'];

coerce 'StartNextTaskRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest'->new($_) };

declare 'RepeatedStartNextTaskRequest',
    as ArrayRef[StartNextTaskRequest()];

coerce 'RepeatedStartNextTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest'->new($_) } @$_ ] };

declare 'MapStringStartNextTaskRequest',
    as HashRef[StartNextTaskRequest()];

declare 'StartNextTaskResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse'];

coerce 'StartNextTaskResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse'->new($_) };

declare 'RepeatedStartNextTaskResponse',
    as ArrayRef[StartNextTaskResponse()];

coerce 'RepeatedStartNextTaskResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse'->new($_) } @$_ ] };

declare 'MapStringStartNextTaskResponse',
    as HashRef[StartNextTaskResponse()];

declare 'ReportTaskProgressRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest'];

coerce 'ReportTaskProgressRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest'->new($_) };

declare 'RepeatedReportTaskProgressRequest',
    as ArrayRef[ReportTaskProgressRequest()];

coerce 'RepeatedReportTaskProgressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest'->new($_) } @$_ ] };

declare 'MapStringReportTaskProgressRequest',
    as HashRef[ReportTaskProgressRequest()];

declare 'ReportTaskProgressResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse'];

coerce 'ReportTaskProgressResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse'->new($_) };

declare 'RepeatedReportTaskProgressResponse',
    as ArrayRef[ReportTaskProgressResponse()];

coerce 'RepeatedReportTaskProgressResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse'->new($_) } @$_ ] };

declare 'MapStringReportTaskProgressResponse',
    as HashRef[ReportTaskProgressResponse()];

declare 'ReportTaskCompleteRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest'];

coerce 'ReportTaskCompleteRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest'->new($_) };

declare 'RepeatedReportTaskCompleteRequest',
    as ArrayRef[ReportTaskCompleteRequest()];

coerce 'RepeatedReportTaskCompleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest'->new($_) } @$_ ] };

declare 'MapStringReportTaskCompleteRequest',
    as HashRef[ReportTaskCompleteRequest()];

declare 'ReportTaskCompleteResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse'];

coerce 'ReportTaskCompleteResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse'->new($_) };

declare 'RepeatedReportTaskCompleteResponse',
    as ArrayRef[ReportTaskCompleteResponse()];

coerce 'RepeatedReportTaskCompleteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse'->new($_) } @$_ ] };

declare 'MapStringReportTaskCompleteResponse',
    as HashRef[ReportTaskCompleteResponse()];

declare 'RegisterAgentRequest',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest'];

coerce 'RegisterAgentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest'->new($_) };

declare 'RepeatedRegisterAgentRequest',
    as ArrayRef[RegisterAgentRequest()];

coerce 'RepeatedRegisterAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterAgentRequest',
    as HashRef[RegisterAgentRequest()];

declare 'RegisterAgentResponse',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse'];

coerce 'RegisterAgentResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse'->new($_) };

declare 'RepeatedRegisterAgentResponse',
    as ArrayRef[RegisterAgentResponse()];

coerce 'RepeatedRegisterAgentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse'->new($_) } @$_ ] };

declare 'MapStringRegisterAgentResponse',
    as HashRef[RegisterAgentResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
