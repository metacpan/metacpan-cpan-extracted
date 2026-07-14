package Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalCatalogDatasetOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions'];

coerce 'ExternalCatalogDatasetOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions'->new($_) };

declare 'RepeatedExternalCatalogDatasetOptions',
    as ArrayRef[ExternalCatalogDatasetOptions()];

coerce 'RepeatedExternalCatalogDatasetOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions'->new($_) } @$_ ] };

declare 'MapStringExternalCatalogDatasetOptions',
    as HashRef[ExternalCatalogDatasetOptions()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions::ExternalCatalogDatasetOptions::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

1;
