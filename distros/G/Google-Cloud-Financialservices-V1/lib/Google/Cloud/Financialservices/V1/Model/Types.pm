package Google::Cloud::Financialservices::V1::Model::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Model',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::Model'];

coerce 'Model',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::Model'->new($_) };

declare 'RepeatedModel',
    as ArrayRef[Model()];

coerce 'RepeatedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::Model'->new($_) } @$_ ] };

declare 'MapStringModel',
    as HashRef[Model()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::Model::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::Model::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::Model::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'GetModelRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'CreateModelRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::CreateModelRequest'];

coerce 'CreateModelRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::CreateModelRequest'->new($_) };

declare 'RepeatedCreateModelRequest',
    as ArrayRef[CreateModelRequest()];

coerce 'RepeatedCreateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::CreateModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateModelRequest',
    as HashRef[CreateModelRequest()];

declare 'UpdateModelRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::UpdateModelRequest'];

coerce 'UpdateModelRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::UpdateModelRequest'->new($_) };

declare 'RepeatedUpdateModelRequest',
    as ArrayRef[UpdateModelRequest()];

coerce 'RepeatedUpdateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::UpdateModelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateModelRequest',
    as HashRef[UpdateModelRequest()];

declare 'DeleteModelRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::DeleteModelRequest'];

coerce 'DeleteModelRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::DeleteModelRequest'->new($_) };

declare 'RepeatedDeleteModelRequest',
    as ArrayRef[DeleteModelRequest()];

coerce 'RepeatedDeleteModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::DeleteModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteModelRequest',
    as HashRef[DeleteModelRequest()];

declare 'ExportModelMetadataRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::ExportModelMetadataRequest'];

coerce 'ExportModelMetadataRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::ExportModelMetadataRequest'->new($_) };

declare 'RepeatedExportModelMetadataRequest',
    as ArrayRef[ExportModelMetadataRequest()];

coerce 'RepeatedExportModelMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::ExportModelMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringExportModelMetadataRequest',
    as HashRef[ExportModelMetadataRequest()];

declare 'ExportModelMetadataResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::Model::ExportModelMetadataResponse'];

coerce 'ExportModelMetadataResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::Model::ExportModelMetadataResponse'->new($_) };

declare 'RepeatedExportModelMetadataResponse',
    as ArrayRef[ExportModelMetadataResponse()];

coerce 'RepeatedExportModelMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::Model::ExportModelMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringExportModelMetadataResponse',
    as HashRef[ExportModelMetadataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::Model::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
