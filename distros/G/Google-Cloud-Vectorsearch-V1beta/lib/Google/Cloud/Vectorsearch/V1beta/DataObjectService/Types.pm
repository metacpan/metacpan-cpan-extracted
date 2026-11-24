package Google::Cloud::Vectorsearch::V1beta::DataObjectService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDataObjectRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest'];

coerce 'CreateDataObjectRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest'->new($_) };

declare 'RepeatedCreateDataObjectRequest',
    as ArrayRef[CreateDataObjectRequest()];

coerce 'RepeatedCreateDataObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::CreateDataObjectRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataObjectRequest',
    as HashRef[CreateDataObjectRequest()];

declare 'BatchCreateDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsRequest'];

coerce 'BatchCreateDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsRequest'->new($_) };

declare 'RepeatedBatchCreateDataObjectsRequest',
    as ArrayRef[BatchCreateDataObjectsRequest()];

coerce 'RepeatedBatchCreateDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateDataObjectsRequest',
    as HashRef[BatchCreateDataObjectsRequest()];

declare 'BatchCreateDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsResponse'];

coerce 'BatchCreateDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsResponse'->new($_) };

declare 'RepeatedBatchCreateDataObjectsResponse',
    as ArrayRef[BatchCreateDataObjectsResponse()];

coerce 'RepeatedBatchCreateDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchCreateDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateDataObjectsResponse',
    as HashRef[BatchCreateDataObjectsResponse()];

declare 'GetDataObjectRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::GetDataObjectRequest'];

coerce 'GetDataObjectRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::GetDataObjectRequest'->new($_) };

declare 'RepeatedGetDataObjectRequest',
    as ArrayRef[GetDataObjectRequest()];

coerce 'RepeatedGetDataObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::GetDataObjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataObjectRequest',
    as HashRef[GetDataObjectRequest()];

declare 'UpdateDataObjectRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest'];

coerce 'UpdateDataObjectRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest'->new($_) };

declare 'RepeatedUpdateDataObjectRequest',
    as ArrayRef[UpdateDataObjectRequest()];

coerce 'RepeatedUpdateDataObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::UpdateDataObjectRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataObjectRequest',
    as HashRef[UpdateDataObjectRequest()];

declare 'BatchUpdateDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsRequest'];

coerce 'BatchUpdateDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsRequest'->new($_) };

declare 'RepeatedBatchUpdateDataObjectsRequest',
    as ArrayRef[BatchUpdateDataObjectsRequest()];

coerce 'RepeatedBatchUpdateDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateDataObjectsRequest',
    as HashRef[BatchUpdateDataObjectsRequest()];

declare 'BatchUpdateDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsResponse'];

coerce 'BatchUpdateDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsResponse'->new($_) };

declare 'RepeatedBatchUpdateDataObjectsResponse',
    as ArrayRef[BatchUpdateDataObjectsResponse()];

coerce 'RepeatedBatchUpdateDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchUpdateDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateDataObjectsResponse',
    as HashRef[BatchUpdateDataObjectsResponse()];

declare 'DeleteDataObjectRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest'];

coerce 'DeleteDataObjectRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest'->new($_) };

declare 'RepeatedDeleteDataObjectRequest',
    as ArrayRef[DeleteDataObjectRequest()];

coerce 'RepeatedDeleteDataObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::DeleteDataObjectRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataObjectRequest',
    as HashRef[DeleteDataObjectRequest()];

declare 'BatchDeleteDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchDeleteDataObjectsRequest'];

coerce 'BatchDeleteDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchDeleteDataObjectsRequest'->new($_) };

declare 'RepeatedBatchDeleteDataObjectsRequest',
    as ArrayRef[BatchDeleteDataObjectsRequest()];

coerce 'RepeatedBatchDeleteDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObjectService::BatchDeleteDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDataObjectsRequest',
    as HashRef[BatchDeleteDataObjectsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::DataObjectService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
