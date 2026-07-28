package Google::Cloud::Dataproc::V1::Sessions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSessionRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest'];

coerce 'CreateSessionRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest'->new($_) };

declare 'RepeatedCreateSessionRequest',
    as ArrayRef[CreateSessionRequest()];

coerce 'RepeatedCreateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::CreateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionRequest',
    as HashRef[CreateSessionRequest()];

declare 'GetSessionRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::GetSessionRequest'];

coerce 'GetSessionRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::GetSessionRequest'->new($_) };

declare 'RepeatedGetSessionRequest',
    as ArrayRef[GetSessionRequest()];

coerce 'RepeatedGetSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::GetSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSessionRequest',
    as HashRef[GetSessionRequest()];

declare 'ListSessionsRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::ListSessionsRequest'];

coerce 'ListSessionsRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::ListSessionsRequest'->new($_) };

declare 'RepeatedListSessionsRequest',
    as ArrayRef[ListSessionsRequest()];

coerce 'RepeatedListSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::ListSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSessionsRequest',
    as HashRef[ListSessionsRequest()];

declare 'ListSessionsResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::ListSessionsResponse'];

coerce 'ListSessionsResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::ListSessionsResponse'->new($_) };

declare 'RepeatedListSessionsResponse',
    as ArrayRef[ListSessionsResponse()];

coerce 'RepeatedListSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::ListSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSessionsResponse',
    as HashRef[ListSessionsResponse()];

declare 'TerminateSessionRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::TerminateSessionRequest'];

coerce 'TerminateSessionRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::TerminateSessionRequest'->new($_) };

declare 'RepeatedTerminateSessionRequest',
    as ArrayRef[TerminateSessionRequest()];

coerce 'RepeatedTerminateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::TerminateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringTerminateSessionRequest',
    as HashRef[TerminateSessionRequest()];

declare 'DeleteSessionRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::DeleteSessionRequest'];

coerce 'DeleteSessionRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::DeleteSessionRequest'->new($_) };

declare 'RepeatedDeleteSessionRequest',
    as ArrayRef[DeleteSessionRequest()];

coerce 'RepeatedDeleteSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::DeleteSessionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSessionRequest',
    as HashRef[DeleteSessionRequest()];

declare 'Session',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

declare 'State',
    as (Int | Str);

declare 'SessionStateHistory',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::Session::SessionStateHistory'];

coerce 'SessionStateHistory',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::Session::SessionStateHistory'->new($_) };

declare 'RepeatedSessionStateHistory',
    as ArrayRef[SessionStateHistory()];

coerce 'RepeatedSessionStateHistory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::Session::SessionStateHistory'->new($_) } @$_ ] };

declare 'MapStringSessionStateHistory',
    as HashRef[SessionStateHistory()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::Session::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::Session::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::Session::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'JupyterConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::JupyterConfig'];

coerce 'JupyterConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::JupyterConfig'->new($_) };

declare 'RepeatedJupyterConfig',
    as ArrayRef[JupyterConfig()];

coerce 'RepeatedJupyterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::JupyterConfig'->new($_) } @$_ ] };

declare 'MapStringJupyterConfig',
    as HashRef[JupyterConfig()];

declare 'Kernel',
    as (Int | Str);

declare 'SparkConnectConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Sessions::SparkConnectConfig'];

coerce 'SparkConnectConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Sessions::SparkConnectConfig'->new($_) };

declare 'RepeatedSparkConnectConfig',
    as ArrayRef[SparkConnectConfig()];

coerce 'RepeatedSparkConnectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Sessions::SparkConnectConfig'->new($_) } @$_ ] };

declare 'MapStringSparkConnectConfig',
    as HashRef[SparkConnectConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::Sessions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
