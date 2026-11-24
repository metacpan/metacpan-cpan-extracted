package Google::Cloud::Sql::V1beta4::CloudSqlData::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlDataFeature',
    as (Int | Str);

declare 'StreamSqlDataRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest'];

coerce 'StreamSqlDataRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest'->new($_) };

declare 'RepeatedStreamSqlDataRequest',
    as ArrayRef[StreamSqlDataRequest()];

coerce 'RepeatedStreamSqlDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest'->new($_) } @$_ ] };

declare 'MapStringStreamSqlDataRequest',
    as HashRef[StreamSqlDataRequest()];

declare 'StartSession',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::StartSession'];

coerce 'StartSession',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::StartSession'->new($_) };

declare 'RepeatedStartSession',
    as ArrayRef[StartSession()];

coerce 'RepeatedStartSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::StartSession'->new($_) } @$_ ] };

declare 'MapStringStartSession',
    as HashRef[StartSession()];

declare 'ContinueSession',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::ContinueSession'];

coerce 'ContinueSession',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::ContinueSession'->new($_) };

declare 'RepeatedContinueSession',
    as ArrayRef[ContinueSession()];

coerce 'RepeatedContinueSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::ContinueSession'->new($_) } @$_ ] };

declare 'MapStringContinueSession',
    as HashRef[ContinueSession()];

declare 'StreamSqlDataResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse'];

coerce 'StreamSqlDataResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse'->new($_) };

declare 'RepeatedStreamSqlDataResponse',
    as ArrayRef[StreamSqlDataResponse()];

coerce 'RepeatedStreamSqlDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse'->new($_) } @$_ ] };

declare 'MapStringStreamSqlDataResponse',
    as HashRef[StreamSqlDataResponse()];

declare 'SessionMetadata',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::SessionMetadata'];

coerce 'SessionMetadata',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::SessionMetadata'->new($_) };

declare 'RepeatedSessionMetadata',
    as ArrayRef[SessionMetadata()];

coerce 'RepeatedSessionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::SessionMetadata'->new($_) } @$_ ] };

declare 'MapStringSessionMetadata',
    as HashRef[SessionMetadata()];

declare 'DataPacket',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket'];

coerce 'DataPacket',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket'->new($_) };

declare 'RepeatedDataPacket',
    as ArrayRef[DataPacket()];

coerce 'RepeatedDataPacket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::DataPacket'->new($_) } @$_ ] };

declare 'MapStringDataPacket',
    as HashRef[DataPacket()];

declare 'Ack',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::Ack'];

coerce 'Ack',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::Ack'->new($_) };

declare 'RepeatedAck',
    as ArrayRef[Ack()];

coerce 'RepeatedAck',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::Ack'->new($_) } @$_ ] };

declare 'MapStringAck',
    as HashRef[Ack()];

declare 'TerminateSession',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession'];

coerce 'TerminateSession',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession'->new($_) };

declare 'RepeatedTerminateSession',
    as ArrayRef[TerminateSession()];

coerce 'RepeatedTerminateSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlData::TerminateSession'->new($_) } @$_ ] };

declare 'MapStringTerminateSession',
    as HashRef[TerminateSession()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlData::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
