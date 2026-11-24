package Google::Cloud::Appoptimize::V1beta::AppOptimize::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateReportRequest',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest'];

coerce 'CreateReportRequest',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest'->new($_) };

declare 'RepeatedCreateReportRequest',
    as ArrayRef[CreateReportRequest()];

coerce 'RepeatedCreateReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::CreateReportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReportRequest',
    as HashRef[CreateReportRequest()];

declare 'Report',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::Report'];

coerce 'Report',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Report'->new($_) };

declare 'RepeatedReport',
    as ArrayRef[Report()];

coerce 'RepeatedReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Report'->new($_) } @$_ ] };

declare 'MapStringReport',
    as HashRef[Report()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'GetReportRequest',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::GetReportRequest'];

coerce 'GetReportRequest',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::GetReportRequest'->new($_) };

declare 'RepeatedGetReportRequest',
    as ArrayRef[GetReportRequest()];

coerce 'RepeatedGetReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::GetReportRequest'->new($_) } @$_ ] };

declare 'MapStringGetReportRequest',
    as HashRef[GetReportRequest()];

declare 'ListReportsRequest',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsRequest'];

coerce 'ListReportsRequest',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsRequest'->new($_) };

declare 'RepeatedListReportsRequest',
    as ArrayRef[ListReportsRequest()];

coerce 'RepeatedListReportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsRequest'->new($_) } @$_ ] };

declare 'MapStringListReportsRequest',
    as HashRef[ListReportsRequest()];

declare 'ListReportsResponse',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsResponse'];

coerce 'ListReportsResponse',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsResponse'->new($_) };

declare 'RepeatedListReportsResponse',
    as ArrayRef[ListReportsResponse()];

coerce 'RepeatedListReportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ListReportsResponse'->new($_) } @$_ ] };

declare 'MapStringListReportsResponse',
    as HashRef[ListReportsResponse()];

declare 'DeleteReportRequest',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::DeleteReportRequest'];

coerce 'DeleteReportRequest',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::DeleteReportRequest'->new($_) };

declare 'RepeatedDeleteReportRequest',
    as ArrayRef[DeleteReportRequest()];

coerce 'RepeatedDeleteReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::DeleteReportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReportRequest',
    as HashRef[DeleteReportRequest()];

declare 'ReadReportRequest',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportRequest'];

coerce 'ReadReportRequest',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportRequest'->new($_) };

declare 'RepeatedReadReportRequest',
    as ArrayRef[ReadReportRequest()];

coerce 'RepeatedReadReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportRequest'->new($_) } @$_ ] };

declare 'MapStringReadReportRequest',
    as HashRef[ReadReportRequest()];

declare 'ReadReportResponse',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportResponse'];

coerce 'ReadReportResponse',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportResponse'->new($_) };

declare 'RepeatedReadReportResponse',
    as ArrayRef[ReadReportResponse()];

coerce 'RepeatedReadReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::ReadReportResponse'->new($_) } @$_ ] };

declare 'MapStringReadReportResponse',
    as HashRef[ReadReportResponse()];

declare 'Column',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Appoptimize::V1beta::AppOptimize::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Appoptimize::V1beta::AppOptimize::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Appoptimize::V1beta::AppOptimize::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
