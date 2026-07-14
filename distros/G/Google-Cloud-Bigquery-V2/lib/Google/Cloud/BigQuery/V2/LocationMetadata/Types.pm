package Google::Cloud::BigQuery::V2::LocationMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::BigQuery::V2::LocationMetadata::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::LocationMetadata::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::LocationMetadata::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

1;
