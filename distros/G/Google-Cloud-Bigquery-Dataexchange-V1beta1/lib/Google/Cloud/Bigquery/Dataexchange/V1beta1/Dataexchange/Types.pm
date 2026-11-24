package Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataExchange',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DataExchange'];

coerce 'DataExchange',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DataExchange'->new($_) };

declare 'RepeatedDataExchange',
    as ArrayRef[DataExchange()];

coerce 'RepeatedDataExchange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DataExchange'->new($_) } @$_ ] };

declare 'MapStringDataExchange',
    as HashRef[DataExchange()];

declare 'DataProvider',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DataProvider'];

coerce 'DataProvider',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DataProvider'->new($_) };

declare 'RepeatedDataProvider',
    as ArrayRef[DataProvider()];

coerce 'RepeatedDataProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DataProvider'->new($_) } @$_ ] };

declare 'MapStringDataProvider',
    as HashRef[DataProvider()];

declare 'Publisher',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Publisher'];

coerce 'Publisher',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Publisher'->new($_) };

declare 'RepeatedPublisher',
    as ArrayRef[Publisher()];

coerce 'RepeatedPublisher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Publisher'->new($_) } @$_ ] };

declare 'MapStringPublisher',
    as HashRef[Publisher()];

declare 'DestinationDatasetReference',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDatasetReference'];

coerce 'DestinationDatasetReference',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDatasetReference'->new($_) };

declare 'RepeatedDestinationDatasetReference',
    as ArrayRef[DestinationDatasetReference()];

coerce 'RepeatedDestinationDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDatasetReference'->new($_) } @$_ ] };

declare 'MapStringDestinationDatasetReference',
    as HashRef[DestinationDatasetReference()];

declare 'DestinationDataset',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDataset'];

coerce 'DestinationDataset',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDataset'->new($_) };

declare 'RepeatedDestinationDataset',
    as ArrayRef[DestinationDataset()];

coerce 'RepeatedDestinationDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDataset'->new($_) } @$_ ] };

declare 'MapStringDestinationDataset',
    as HashRef[DestinationDataset()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDataset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDataset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DestinationDataset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Listing',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Listing'];

coerce 'Listing',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Listing'->new($_) };

declare 'RepeatedListing',
    as ArrayRef[Listing()];

coerce 'RepeatedListing',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Listing'->new($_) } @$_ ] };

declare 'MapStringListing',
    as HashRef[Listing()];

declare 'State',
    as (Int | Str);

declare 'Category',
    as (Int | Str);

declare 'BigQueryDatasetSource',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Listing::BigQueryDatasetSource'];

coerce 'BigQueryDatasetSource',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Listing::BigQueryDatasetSource'->new($_) };

declare 'RepeatedBigQueryDatasetSource',
    as ArrayRef[BigQueryDatasetSource()];

coerce 'RepeatedBigQueryDatasetSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Listing::BigQueryDatasetSource'->new($_) } @$_ ] };

declare 'MapStringBigQueryDatasetSource',
    as HashRef[BigQueryDatasetSource()];

declare 'ListDataExchangesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListDataExchangesRequest'];

coerce 'ListDataExchangesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListDataExchangesRequest'->new($_) };

declare 'RepeatedListDataExchangesRequest',
    as ArrayRef[ListDataExchangesRequest()];

coerce 'RepeatedListDataExchangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListDataExchangesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataExchangesRequest',
    as HashRef[ListDataExchangesRequest()];

declare 'ListDataExchangesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListDataExchangesResponse'];

coerce 'ListDataExchangesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListDataExchangesResponse'->new($_) };

declare 'RepeatedListDataExchangesResponse',
    as ArrayRef[ListDataExchangesResponse()];

coerce 'RepeatedListDataExchangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListDataExchangesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataExchangesResponse',
    as HashRef[ListDataExchangesResponse()];

declare 'ListOrgDataExchangesRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListOrgDataExchangesRequest'];

coerce 'ListOrgDataExchangesRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListOrgDataExchangesRequest'->new($_) };

declare 'RepeatedListOrgDataExchangesRequest',
    as ArrayRef[ListOrgDataExchangesRequest()];

coerce 'RepeatedListOrgDataExchangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListOrgDataExchangesRequest'->new($_) } @$_ ] };

declare 'MapStringListOrgDataExchangesRequest',
    as HashRef[ListOrgDataExchangesRequest()];

declare 'ListOrgDataExchangesResponse',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListOrgDataExchangesResponse'];

coerce 'ListOrgDataExchangesResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListOrgDataExchangesResponse'->new($_) };

declare 'RepeatedListOrgDataExchangesResponse',
    as ArrayRef[ListOrgDataExchangesResponse()];

coerce 'RepeatedListOrgDataExchangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListOrgDataExchangesResponse'->new($_) } @$_ ] };

declare 'MapStringListOrgDataExchangesResponse',
    as HashRef[ListOrgDataExchangesResponse()];

declare 'GetDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::GetDataExchangeRequest'];

coerce 'GetDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::GetDataExchangeRequest'->new($_) };

declare 'RepeatedGetDataExchangeRequest',
    as ArrayRef[GetDataExchangeRequest()];

coerce 'RepeatedGetDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::GetDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataExchangeRequest',
    as HashRef[GetDataExchangeRequest()];

declare 'CreateDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::CreateDataExchangeRequest'];

coerce 'CreateDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::CreateDataExchangeRequest'->new($_) };

declare 'RepeatedCreateDataExchangeRequest',
    as ArrayRef[CreateDataExchangeRequest()];

coerce 'RepeatedCreateDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::CreateDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataExchangeRequest',
    as HashRef[CreateDataExchangeRequest()];

declare 'UpdateDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::UpdateDataExchangeRequest'];

coerce 'UpdateDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::UpdateDataExchangeRequest'->new($_) };

declare 'RepeatedUpdateDataExchangeRequest',
    as ArrayRef[UpdateDataExchangeRequest()];

coerce 'RepeatedUpdateDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::UpdateDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataExchangeRequest',
    as HashRef[UpdateDataExchangeRequest()];

declare 'DeleteDataExchangeRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DeleteDataExchangeRequest'];

coerce 'DeleteDataExchangeRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DeleteDataExchangeRequest'->new($_) };

declare 'RepeatedDeleteDataExchangeRequest',
    as ArrayRef[DeleteDataExchangeRequest()];

coerce 'RepeatedDeleteDataExchangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DeleteDataExchangeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataExchangeRequest',
    as HashRef[DeleteDataExchangeRequest()];

declare 'ListListingsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListListingsRequest'];

coerce 'ListListingsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListListingsRequest'->new($_) };

declare 'RepeatedListListingsRequest',
    as ArrayRef[ListListingsRequest()];

coerce 'RepeatedListListingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListListingsRequest'->new($_) } @$_ ] };

declare 'MapStringListListingsRequest',
    as HashRef[ListListingsRequest()];

declare 'ListListingsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListListingsResponse'];

coerce 'ListListingsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListListingsResponse'->new($_) };

declare 'RepeatedListListingsResponse',
    as ArrayRef[ListListingsResponse()];

coerce 'RepeatedListListingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::ListListingsResponse'->new($_) } @$_ ] };

declare 'MapStringListListingsResponse',
    as HashRef[ListListingsResponse()];

declare 'GetListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::GetListingRequest'];

coerce 'GetListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::GetListingRequest'->new($_) };

declare 'RepeatedGetListingRequest',
    as ArrayRef[GetListingRequest()];

coerce 'RepeatedGetListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::GetListingRequest'->new($_) } @$_ ] };

declare 'MapStringGetListingRequest',
    as HashRef[GetListingRequest()];

declare 'CreateListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::CreateListingRequest'];

coerce 'CreateListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::CreateListingRequest'->new($_) };

declare 'RepeatedCreateListingRequest',
    as ArrayRef[CreateListingRequest()];

coerce 'RepeatedCreateListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::CreateListingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateListingRequest',
    as HashRef[CreateListingRequest()];

declare 'UpdateListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::UpdateListingRequest'];

coerce 'UpdateListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::UpdateListingRequest'->new($_) };

declare 'RepeatedUpdateListingRequest',
    as ArrayRef[UpdateListingRequest()];

coerce 'RepeatedUpdateListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::UpdateListingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateListingRequest',
    as HashRef[UpdateListingRequest()];

declare 'DeleteListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DeleteListingRequest'];

coerce 'DeleteListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DeleteListingRequest'->new($_) };

declare 'RepeatedDeleteListingRequest',
    as ArrayRef[DeleteListingRequest()];

coerce 'RepeatedDeleteListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::DeleteListingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteListingRequest',
    as HashRef[DeleteListingRequest()];

declare 'SubscribeListingRequest',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::SubscribeListingRequest'];

coerce 'SubscribeListingRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::SubscribeListingRequest'->new($_) };

declare 'RepeatedSubscribeListingRequest',
    as ArrayRef[SubscribeListingRequest()];

coerce 'RepeatedSubscribeListingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::SubscribeListingRequest'->new($_) } @$_ ] };

declare 'MapStringSubscribeListingRequest',
    as HashRef[SubscribeListingRequest()];

declare 'SubscribeListingResponse',
    as InstanceOf['Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::SubscribeListingResponse'];

coerce 'SubscribeListingResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::SubscribeListingResponse'->new($_) };

declare 'RepeatedSubscribeListingResponse',
    as ArrayRef[SubscribeListingResponse()];

coerce 'RepeatedSubscribeListingResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::SubscribeListingResponse'->new($_) } @$_ ] };

declare 'MapStringSubscribeListingResponse',
    as HashRef[SubscribeListingResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Dataexchange::V1beta1::Dataexchange::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
