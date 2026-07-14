package Google::Cloud::BigQuery::V2::ExternalDatasetReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalDatasetReference',
    as InstanceOf['Google::Cloud::BigQuery::V2::ExternalDatasetReference::ExternalDatasetReference'];

coerce 'ExternalDatasetReference',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::ExternalDatasetReference::ExternalDatasetReference'->new($_) };

declare 'RepeatedExternalDatasetReference',
    as ArrayRef[ExternalDatasetReference()];

coerce 'RepeatedExternalDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::ExternalDatasetReference::ExternalDatasetReference'->new($_) } @$_ ] };

declare 'MapStringExternalDatasetReference',
    as HashRef[ExternalDatasetReference()];

1;
