package Google::Cloud::Sql::V1::CloudSqlOperations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlOperationsGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest'];

coerce 'SqlOperationsGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest'->new($_) };

declare 'RepeatedSqlOperationsGetRequest',
    as ArrayRef[SqlOperationsGetRequest()];

coerce 'RepeatedSqlOperationsGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlOperationsGetRequest',
    as HashRef[SqlOperationsGetRequest()];

declare 'SqlOperationsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest'];

coerce 'SqlOperationsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest'->new($_) };

declare 'RepeatedSqlOperationsListRequest',
    as ArrayRef[SqlOperationsListRequest()];

coerce 'RepeatedSqlOperationsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlOperationsListRequest',
    as HashRef[SqlOperationsListRequest()];

declare 'OperationsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse'];

coerce 'OperationsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse'->new($_) };

declare 'RepeatedOperationsListResponse',
    as ArrayRef[OperationsListResponse()];

coerce 'RepeatedOperationsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse'->new($_) } @$_ ] };

declare 'MapStringOperationsListResponse',
    as HashRef[OperationsListResponse()];

declare 'SqlOperationsCancelRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest'];

coerce 'SqlOperationsCancelRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest'->new($_) };

declare 'RepeatedSqlOperationsCancelRequest',
    as ArrayRef[SqlOperationsCancelRequest()];

coerce 'RepeatedSqlOperationsCancelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest'->new($_) } @$_ ] };

declare 'MapStringSqlOperationsCancelRequest',
    as HashRef[SqlOperationsCancelRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
