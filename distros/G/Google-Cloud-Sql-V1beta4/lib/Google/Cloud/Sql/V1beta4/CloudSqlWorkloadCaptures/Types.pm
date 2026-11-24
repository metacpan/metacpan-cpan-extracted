package Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WorkloadCapturesStartRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest'];

coerce 'WorkloadCapturesStartRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest'->new($_) };

declare 'RepeatedWorkloadCapturesStartRequest',
    as ArrayRef[WorkloadCapturesStartRequest()];

coerce 'RepeatedWorkloadCapturesStartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest'->new($_) } @$_ ] };

declare 'MapStringWorkloadCapturesStartRequest',
    as HashRef[WorkloadCapturesStartRequest()];

declare 'WorkloadCapturesStopRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest'];

coerce 'WorkloadCapturesStopRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest'->new($_) };

declare 'RepeatedWorkloadCapturesStopRequest',
    as ArrayRef[WorkloadCapturesStopRequest()];

coerce 'RepeatedWorkloadCapturesStopRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest'->new($_) } @$_ ] };

declare 'MapStringWorkloadCapturesStopRequest',
    as HashRef[WorkloadCapturesStopRequest()];

declare 'WorkloadCapturesStartReplayRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest'];

coerce 'WorkloadCapturesStartReplayRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest'->new($_) };

declare 'RepeatedWorkloadCapturesStartReplayRequest',
    as ArrayRef[WorkloadCapturesStartReplayRequest()];

coerce 'RepeatedWorkloadCapturesStartReplayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest'->new($_) } @$_ ] };

declare 'MapStringWorkloadCapturesStartReplayRequest',
    as HashRef[WorkloadCapturesStartReplayRequest()];

declare 'WorkloadCapturesStopReplayRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest'];

coerce 'WorkloadCapturesStopReplayRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest'->new($_) };

declare 'RepeatedWorkloadCapturesStopReplayRequest',
    as ArrayRef[WorkloadCapturesStopReplayRequest()];

coerce 'RepeatedWorkloadCapturesStopReplayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest'->new($_) } @$_ ] };

declare 'MapStringWorkloadCapturesStopReplayRequest',
    as HashRef[WorkloadCapturesStopReplayRequest()];

declare 'SqlWorkloadCapturesListRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest'];

coerce 'SqlWorkloadCapturesListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest'->new($_) };

declare 'RepeatedSqlWorkloadCapturesListRequest',
    as ArrayRef[SqlWorkloadCapturesListRequest()];

coerce 'RepeatedSqlWorkloadCapturesListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlWorkloadCapturesListRequest',
    as HashRef[SqlWorkloadCapturesListRequest()];

declare 'WorkloadCapturesListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse'];

coerce 'WorkloadCapturesListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse'->new($_) };

declare 'RepeatedWorkloadCapturesListResponse',
    as ArrayRef[WorkloadCapturesListResponse()];

coerce 'RepeatedWorkloadCapturesListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse'->new($_) } @$_ ] };

declare 'MapStringWorkloadCapturesListResponse',
    as HashRef[WorkloadCapturesListResponse()];

declare 'WorkloadCapture',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapture'];

coerce 'WorkloadCapture',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapture'->new($_) };

declare 'RepeatedWorkloadCapture',
    as ArrayRef[WorkloadCapture()];

coerce 'RepeatedWorkloadCapture',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapture'->new($_) } @$_ ] };

declare 'MapStringWorkloadCapture',
    as HashRef[WorkloadCapture()];

declare 'State',
    as (Int | Str);

declare 'WorkloadCaptureMode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
