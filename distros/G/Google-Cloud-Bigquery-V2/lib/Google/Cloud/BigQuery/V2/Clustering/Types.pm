package Google::Cloud::BigQuery::V2::Clustering::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Clustering',
    as InstanceOf['Google::Cloud::BigQuery::V2::Clustering::Clustering'];

coerce 'Clustering',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Clustering::Clustering'->new($_) };

declare 'RepeatedClustering',
    as ArrayRef[Clustering()];

coerce 'RepeatedClustering',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Clustering::Clustering'->new($_) } @$_ ] };

declare 'MapStringClustering',
    as HashRef[Clustering()];

1;
