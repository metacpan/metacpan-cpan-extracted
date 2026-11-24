package Google::Cloud::Geminidataanalytics::V1beta::Datasource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFilterType',
    as (Int | Str);

declare 'DatasourceReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::DatasourceReferences'];

coerce 'DatasourceReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::DatasourceReferences'->new($_) };

declare 'RepeatedDatasourceReferences',
    as ArrayRef[DatasourceReferences()];

coerce 'RepeatedDatasourceReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::DatasourceReferences'->new($_) } @$_ ] };

declare 'MapStringDatasourceReferences',
    as HashRef[DatasourceReferences()];

declare 'BigQueryTableReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReferences'];

coerce 'BigQueryTableReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReferences'->new($_) };

declare 'RepeatedBigQueryTableReferences',
    as ArrayRef[BigQueryTableReferences()];

coerce 'RepeatedBigQueryTableReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReferences'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableReferences',
    as HashRef[BigQueryTableReferences()];

declare 'BigQueryTableReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReference'];

coerce 'BigQueryTableReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReference'->new($_) };

declare 'RepeatedBigQueryTableReference',
    as ArrayRef[BigQueryTableReference()];

coerce 'RepeatedBigQueryTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryTableReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableReference',
    as HashRef[BigQueryTableReference()];

declare 'BigQueryDatasetReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryDatasetReference'];

coerce 'BigQueryDatasetReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryDatasetReference'->new($_) };

declare 'RepeatedBigQueryDatasetReference',
    as ArrayRef[BigQueryDatasetReference()];

coerce 'RepeatedBigQueryDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryDatasetReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryDatasetReference',
    as HashRef[BigQueryDatasetReference()];

declare 'SearchScope',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::SearchScope'];

coerce 'SearchScope',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::SearchScope'->new($_) };

declare 'RepeatedSearchScope',
    as ArrayRef[SearchScope()];

coerce 'RepeatedSearchScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::SearchScope'->new($_) } @$_ ] };

declare 'MapStringSearchScope',
    as HashRef[SearchScope()];

declare 'StudioDatasourceReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::StudioDatasourceReferences'];

coerce 'StudioDatasourceReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::StudioDatasourceReferences'->new($_) };

declare 'RepeatedStudioDatasourceReferences',
    as ArrayRef[StudioDatasourceReferences()];

coerce 'RepeatedStudioDatasourceReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::StudioDatasourceReferences'->new($_) } @$_ ] };

declare 'MapStringStudioDatasourceReferences',
    as HashRef[StudioDatasourceReferences()];

declare 'StudioDatasourceReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::StudioDatasourceReference'];

coerce 'StudioDatasourceReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::StudioDatasourceReference'->new($_) };

declare 'RepeatedStudioDatasourceReference',
    as ArrayRef[StudioDatasourceReference()];

coerce 'RepeatedStudioDatasourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::StudioDatasourceReference'->new($_) } @$_ ] };

declare 'MapStringStudioDatasourceReference',
    as HashRef[StudioDatasourceReference()];

declare 'AlloyDbReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::AlloyDbReference'];

coerce 'AlloyDbReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::AlloyDbReference'->new($_) };

declare 'RepeatedAlloyDbReference',
    as ArrayRef[AlloyDbReference()];

coerce 'RepeatedAlloyDbReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::AlloyDbReference'->new($_) } @$_ ] };

declare 'MapStringAlloyDbReference',
    as HashRef[AlloyDbReference()];

declare 'DatabaseTableReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::DatabaseTableReference'];

coerce 'DatabaseTableReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::DatabaseTableReference'->new($_) };

declare 'RepeatedDatabaseTableReference',
    as ArrayRef[DatabaseTableReference()];

coerce 'RepeatedDatabaseTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::DatabaseTableReference'->new($_) } @$_ ] };

declare 'MapStringDatabaseTableReference',
    as HashRef[DatabaseTableReference()];

declare 'AlloyDbDatabaseReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::AlloyDbDatabaseReference'];

coerce 'AlloyDbDatabaseReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::AlloyDbDatabaseReference'->new($_) };

declare 'RepeatedAlloyDbDatabaseReference',
    as ArrayRef[AlloyDbDatabaseReference()];

coerce 'RepeatedAlloyDbDatabaseReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::AlloyDbDatabaseReference'->new($_) } @$_ ] };

declare 'MapStringAlloyDbDatabaseReference',
    as HashRef[AlloyDbDatabaseReference()];

declare 'BigtableReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigtableReference'];

coerce 'BigtableReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigtableReference'->new($_) };

declare 'RepeatedBigtableReference',
    as ArrayRef[BigtableReference()];

coerce 'RepeatedBigtableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigtableReference'->new($_) } @$_ ] };

declare 'MapStringBigtableReference',
    as HashRef[BigtableReference()];

declare 'BigtableDatabaseReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigtableDatabaseReference'];

coerce 'BigtableDatabaseReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigtableDatabaseReference'->new($_) };

declare 'RepeatedBigtableDatabaseReference',
    as ArrayRef[BigtableDatabaseReference()];

coerce 'RepeatedBigtableDatabaseReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigtableDatabaseReference'->new($_) } @$_ ] };

declare 'MapStringBigtableDatabaseReference',
    as HashRef[BigtableDatabaseReference()];

declare 'FirestoreReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::FirestoreReference'];

coerce 'FirestoreReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::FirestoreReference'->new($_) };

declare 'RepeatedFirestoreReference',
    as ArrayRef[FirestoreReference()];

coerce 'RepeatedFirestoreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::FirestoreReference'->new($_) } @$_ ] };

declare 'MapStringFirestoreReference',
    as HashRef[FirestoreReference()];

declare 'FirestoreDatabaseReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::FirestoreDatabaseReference'];

coerce 'FirestoreDatabaseReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::FirestoreDatabaseReference'->new($_) };

declare 'RepeatedFirestoreDatabaseReference',
    as ArrayRef[FirestoreDatabaseReference()];

coerce 'RepeatedFirestoreDatabaseReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::FirestoreDatabaseReference'->new($_) } @$_ ] };

declare 'MapStringFirestoreDatabaseReference',
    as HashRef[FirestoreDatabaseReference()];

declare 'SpannerReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::SpannerReference'];

coerce 'SpannerReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::SpannerReference'->new($_) };

declare 'RepeatedSpannerReference',
    as ArrayRef[SpannerReference()];

coerce 'RepeatedSpannerReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::SpannerReference'->new($_) } @$_ ] };

declare 'MapStringSpannerReference',
    as HashRef[SpannerReference()];

declare 'SpannerDatabaseReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::SpannerDatabaseReference'];

coerce 'SpannerDatabaseReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::SpannerDatabaseReference'->new($_) };

declare 'RepeatedSpannerDatabaseReference',
    as ArrayRef[SpannerDatabaseReference()];

coerce 'RepeatedSpannerDatabaseReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::SpannerDatabaseReference'->new($_) } @$_ ] };

declare 'MapStringSpannerDatabaseReference',
    as HashRef[SpannerDatabaseReference()];

declare 'Engine',
    as (Int | Str);

declare 'CloudSqlReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::CloudSqlReference'];

coerce 'CloudSqlReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::CloudSqlReference'->new($_) };

declare 'RepeatedCloudSqlReference',
    as ArrayRef[CloudSqlReference()];

coerce 'RepeatedCloudSqlReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::CloudSqlReference'->new($_) } @$_ ] };

declare 'MapStringCloudSqlReference',
    as HashRef[CloudSqlReference()];

declare 'CloudSqlDatabaseReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::CloudSqlDatabaseReference'];

coerce 'CloudSqlDatabaseReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::CloudSqlDatabaseReference'->new($_) };

declare 'RepeatedCloudSqlDatabaseReference',
    as ArrayRef[CloudSqlDatabaseReference()];

coerce 'RepeatedCloudSqlDatabaseReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::CloudSqlDatabaseReference'->new($_) } @$_ ] };

declare 'MapStringCloudSqlDatabaseReference',
    as HashRef[CloudSqlDatabaseReference()];

declare 'Engine',
    as (Int | Str);

declare 'LookerExploreReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::LookerExploreReferences'];

coerce 'LookerExploreReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::LookerExploreReferences'->new($_) };

declare 'RepeatedLookerExploreReferences',
    as ArrayRef[LookerExploreReferences()];

coerce 'RepeatedLookerExploreReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::LookerExploreReferences'->new($_) } @$_ ] };

declare 'MapStringLookerExploreReferences',
    as HashRef[LookerExploreReferences()];

declare 'LookerExploreReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::LookerExploreReference'];

coerce 'LookerExploreReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::LookerExploreReference'->new($_) };

declare 'RepeatedLookerExploreReference',
    as ArrayRef[LookerExploreReference()];

coerce 'RepeatedLookerExploreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::LookerExploreReference'->new($_) } @$_ ] };

declare 'MapStringLookerExploreReference',
    as HashRef[LookerExploreReference()];

declare 'BigQueryPropertyGraphReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryPropertyGraphReference'];

coerce 'BigQueryPropertyGraphReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryPropertyGraphReference'->new($_) };

declare 'RepeatedBigQueryPropertyGraphReference',
    as ArrayRef[BigQueryPropertyGraphReference()];

coerce 'RepeatedBigQueryPropertyGraphReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::BigQueryPropertyGraphReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryPropertyGraphReference',
    as HashRef[BigQueryPropertyGraphReference()];

declare 'PrivateLookerInstanceInfo',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::PrivateLookerInstanceInfo'];

coerce 'PrivateLookerInstanceInfo',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::PrivateLookerInstanceInfo'->new($_) };

declare 'RepeatedPrivateLookerInstanceInfo',
    as ArrayRef[PrivateLookerInstanceInfo()];

coerce 'RepeatedPrivateLookerInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::PrivateLookerInstanceInfo'->new($_) } @$_ ] };

declare 'MapStringPrivateLookerInstanceInfo',
    as HashRef[PrivateLookerInstanceInfo()];

declare 'Datasource',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::Datasource'];

coerce 'Datasource',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::Datasource'->new($_) };

declare 'RepeatedDatasource',
    as ArrayRef[Datasource()];

coerce 'RepeatedDatasource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::Datasource'->new($_) } @$_ ] };

declare 'MapStringDatasource',
    as HashRef[Datasource()];

declare 'Schema',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'Field',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'DataFilter',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Datasource::DataFilter'];

coerce 'DataFilter',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::DataFilter'->new($_) };

declare 'RepeatedDataFilter',
    as ArrayRef[DataFilter()];

coerce 'RepeatedDataFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Datasource::DataFilter'->new($_) } @$_ ] };

declare 'MapStringDataFilter',
    as HashRef[DataFilter()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::Datasource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
