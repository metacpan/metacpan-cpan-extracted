package Google::Cloud::Financialservices::V1::Dataset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Dataset',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::Dataset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::Dataset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::Dataset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TableSpecsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::Dataset::TableSpecsEntry'];

coerce 'TableSpecsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::Dataset::TableSpecsEntry'->new($_) };

declare 'RepeatedTableSpecsEntry',
    as ArrayRef[TableSpecsEntry()];

coerce 'RepeatedTableSpecsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::Dataset::TableSpecsEntry'->new($_) } @$_ ] };

declare 'MapStringTableSpecsEntry',
    as HashRef[TableSpecsEntry()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListDatasetsResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::ListDatasetsResponse'];

coerce 'ListDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::ListDatasetsResponse'->new($_) };

declare 'RepeatedListDatasetsResponse',
    as ArrayRef[ListDatasetsResponse()];

coerce 'RepeatedListDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::ListDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetsResponse',
    as HashRef[ListDatasetsResponse()];

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'CreateDatasetRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::CreateDatasetRequest'];

coerce 'CreateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::CreateDatasetRequest'->new($_) };

declare 'RepeatedCreateDatasetRequest',
    as ArrayRef[CreateDatasetRequest()];

coerce 'RepeatedCreateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::CreateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetRequest',
    as HashRef[CreateDatasetRequest()];

declare 'UpdateDatasetRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::UpdateDatasetRequest'];

coerce 'UpdateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::UpdateDatasetRequest'->new($_) };

declare 'RepeatedUpdateDatasetRequest',
    as ArrayRef[UpdateDatasetRequest()];

coerce 'RepeatedUpdateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::UpdateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetRequest',
    as HashRef[UpdateDatasetRequest()];

declare 'DeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Dataset::DeleteDatasetRequest'];

coerce 'DeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Dataset::DeleteDatasetRequest'->new($_) };

declare 'RepeatedDeleteDatasetRequest',
    as ArrayRef[DeleteDatasetRequest()];

coerce 'RepeatedDeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Dataset::DeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetRequest',
    as HashRef[DeleteDatasetRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::Dataset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
