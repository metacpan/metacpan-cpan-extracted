package Google::Cloud::Dataplex::V1::DataTaxonomy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataTaxonomy',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataTaxonomy'];

coerce 'DataTaxonomy',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataTaxonomy'->new($_) };

declare 'RepeatedDataTaxonomy',
    as ArrayRef[DataTaxonomy()];

coerce 'RepeatedDataTaxonomy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataTaxonomy'->new($_) } @$_ ] };

declare 'MapStringDataTaxonomy',
    as HashRef[DataTaxonomy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataTaxonomy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataTaxonomy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataTaxonomy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DataAttribute',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttribute'];

coerce 'DataAttribute',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttribute'->new($_) };

declare 'RepeatedDataAttribute',
    as ArrayRef[DataAttribute()];

coerce 'RepeatedDataAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttribute'->new($_) } @$_ ] };

declare 'MapStringDataAttribute',
    as HashRef[DataAttribute()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttribute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttribute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttribute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DataAttributeBinding',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding'];

coerce 'DataAttributeBinding',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding'->new($_) };

declare 'RepeatedDataAttributeBinding',
    as ArrayRef[DataAttributeBinding()];

coerce 'RepeatedDataAttributeBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding'->new($_) } @$_ ] };

declare 'MapStringDataAttributeBinding',
    as HashRef[DataAttributeBinding()];

declare 'Path',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding::Path'];

coerce 'Path',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding::Path'->new($_) };

declare 'RepeatedPath',
    as ArrayRef[Path()];

coerce 'RepeatedPath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding::Path'->new($_) } @$_ ] };

declare 'MapStringPath',
    as HashRef[Path()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DataAttributeBinding::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateDataTaxonomyRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataTaxonomyRequest'];

coerce 'CreateDataTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataTaxonomyRequest'->new($_) };

declare 'RepeatedCreateDataTaxonomyRequest',
    as ArrayRef[CreateDataTaxonomyRequest()];

coerce 'RepeatedCreateDataTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataTaxonomyRequest',
    as HashRef[CreateDataTaxonomyRequest()];

declare 'UpdateDataTaxonomyRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataTaxonomyRequest'];

coerce 'UpdateDataTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataTaxonomyRequest'->new($_) };

declare 'RepeatedUpdateDataTaxonomyRequest',
    as ArrayRef[UpdateDataTaxonomyRequest()];

coerce 'RepeatedUpdateDataTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataTaxonomyRequest',
    as HashRef[UpdateDataTaxonomyRequest()];

declare 'GetDataTaxonomyRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataTaxonomyRequest'];

coerce 'GetDataTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataTaxonomyRequest'->new($_) };

declare 'RepeatedGetDataTaxonomyRequest',
    as ArrayRef[GetDataTaxonomyRequest()];

coerce 'RepeatedGetDataTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataTaxonomyRequest',
    as HashRef[GetDataTaxonomyRequest()];

declare 'ListDataTaxonomiesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataTaxonomiesRequest'];

coerce 'ListDataTaxonomiesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataTaxonomiesRequest'->new($_) };

declare 'RepeatedListDataTaxonomiesRequest',
    as ArrayRef[ListDataTaxonomiesRequest()];

coerce 'RepeatedListDataTaxonomiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataTaxonomiesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataTaxonomiesRequest',
    as HashRef[ListDataTaxonomiesRequest()];

declare 'ListDataTaxonomiesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataTaxonomiesResponse'];

coerce 'ListDataTaxonomiesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataTaxonomiesResponse'->new($_) };

declare 'RepeatedListDataTaxonomiesResponse',
    as ArrayRef[ListDataTaxonomiesResponse()];

coerce 'RepeatedListDataTaxonomiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataTaxonomiesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataTaxonomiesResponse',
    as HashRef[ListDataTaxonomiesResponse()];

declare 'DeleteDataTaxonomyRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataTaxonomyRequest'];

coerce 'DeleteDataTaxonomyRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataTaxonomyRequest'->new($_) };

declare 'RepeatedDeleteDataTaxonomyRequest',
    as ArrayRef[DeleteDataTaxonomyRequest()];

coerce 'RepeatedDeleteDataTaxonomyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataTaxonomyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataTaxonomyRequest',
    as HashRef[DeleteDataTaxonomyRequest()];

declare 'CreateDataAttributeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataAttributeRequest'];

coerce 'CreateDataAttributeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataAttributeRequest'->new($_) };

declare 'RepeatedCreateDataAttributeRequest',
    as ArrayRef[CreateDataAttributeRequest()];

coerce 'RepeatedCreateDataAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataAttributeRequest',
    as HashRef[CreateDataAttributeRequest()];

declare 'UpdateDataAttributeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataAttributeRequest'];

coerce 'UpdateDataAttributeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataAttributeRequest'->new($_) };

declare 'RepeatedUpdateDataAttributeRequest',
    as ArrayRef[UpdateDataAttributeRequest()];

coerce 'RepeatedUpdateDataAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataAttributeRequest',
    as HashRef[UpdateDataAttributeRequest()];

declare 'GetDataAttributeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataAttributeRequest'];

coerce 'GetDataAttributeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataAttributeRequest'->new($_) };

declare 'RepeatedGetDataAttributeRequest',
    as ArrayRef[GetDataAttributeRequest()];

coerce 'RepeatedGetDataAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataAttributeRequest',
    as HashRef[GetDataAttributeRequest()];

declare 'ListDataAttributesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributesRequest'];

coerce 'ListDataAttributesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributesRequest'->new($_) };

declare 'RepeatedListDataAttributesRequest',
    as ArrayRef[ListDataAttributesRequest()];

coerce 'RepeatedListDataAttributesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataAttributesRequest',
    as HashRef[ListDataAttributesRequest()];

declare 'ListDataAttributesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributesResponse'];

coerce 'ListDataAttributesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributesResponse'->new($_) };

declare 'RepeatedListDataAttributesResponse',
    as ArrayRef[ListDataAttributesResponse()];

coerce 'RepeatedListDataAttributesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataAttributesResponse',
    as HashRef[ListDataAttributesResponse()];

declare 'DeleteDataAttributeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataAttributeRequest'];

coerce 'DeleteDataAttributeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataAttributeRequest'->new($_) };

declare 'RepeatedDeleteDataAttributeRequest',
    as ArrayRef[DeleteDataAttributeRequest()];

coerce 'RepeatedDeleteDataAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataAttributeRequest',
    as HashRef[DeleteDataAttributeRequest()];

declare 'CreateDataAttributeBindingRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataAttributeBindingRequest'];

coerce 'CreateDataAttributeBindingRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataAttributeBindingRequest'->new($_) };

declare 'RepeatedCreateDataAttributeBindingRequest',
    as ArrayRef[CreateDataAttributeBindingRequest()];

coerce 'RepeatedCreateDataAttributeBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::CreateDataAttributeBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataAttributeBindingRequest',
    as HashRef[CreateDataAttributeBindingRequest()];

declare 'UpdateDataAttributeBindingRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataAttributeBindingRequest'];

coerce 'UpdateDataAttributeBindingRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataAttributeBindingRequest'->new($_) };

declare 'RepeatedUpdateDataAttributeBindingRequest',
    as ArrayRef[UpdateDataAttributeBindingRequest()];

coerce 'RepeatedUpdateDataAttributeBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::UpdateDataAttributeBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataAttributeBindingRequest',
    as HashRef[UpdateDataAttributeBindingRequest()];

declare 'GetDataAttributeBindingRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataAttributeBindingRequest'];

coerce 'GetDataAttributeBindingRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataAttributeBindingRequest'->new($_) };

declare 'RepeatedGetDataAttributeBindingRequest',
    as ArrayRef[GetDataAttributeBindingRequest()];

coerce 'RepeatedGetDataAttributeBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::GetDataAttributeBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataAttributeBindingRequest',
    as HashRef[GetDataAttributeBindingRequest()];

declare 'ListDataAttributeBindingsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributeBindingsRequest'];

coerce 'ListDataAttributeBindingsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributeBindingsRequest'->new($_) };

declare 'RepeatedListDataAttributeBindingsRequest',
    as ArrayRef[ListDataAttributeBindingsRequest()];

coerce 'RepeatedListDataAttributeBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributeBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataAttributeBindingsRequest',
    as HashRef[ListDataAttributeBindingsRequest()];

declare 'ListDataAttributeBindingsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributeBindingsResponse'];

coerce 'ListDataAttributeBindingsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributeBindingsResponse'->new($_) };

declare 'RepeatedListDataAttributeBindingsResponse',
    as ArrayRef[ListDataAttributeBindingsResponse()];

coerce 'RepeatedListDataAttributeBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::ListDataAttributeBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataAttributeBindingsResponse',
    as HashRef[ListDataAttributeBindingsResponse()];

declare 'DeleteDataAttributeBindingRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataAttributeBindingRequest'];

coerce 'DeleteDataAttributeBindingRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataAttributeBindingRequest'->new($_) };

declare 'RepeatedDeleteDataAttributeBindingRequest',
    as ArrayRef[DeleteDataAttributeBindingRequest()];

coerce 'RepeatedDeleteDataAttributeBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataTaxonomy::DeleteDataAttributeBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataAttributeBindingRequest',
    as HashRef[DeleteDataAttributeBindingRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataTaxonomy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
