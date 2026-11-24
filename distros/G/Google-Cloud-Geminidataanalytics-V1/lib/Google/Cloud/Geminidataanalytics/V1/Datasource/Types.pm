package Google::Cloud::Geminidataanalytics::V1::Datasource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataFilterType',
    as (Int | Str);

declare 'DatasourceReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences'];

coerce 'DatasourceReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences'->new($_) };

declare 'RepeatedDatasourceReferences',
    as ArrayRef[DatasourceReferences()];

coerce 'RepeatedDatasourceReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::DatasourceReferences'->new($_) } @$_ ] };

declare 'MapStringDatasourceReferences',
    as HashRef[DatasourceReferences()];

declare 'BigQueryTableReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReferences'];

coerce 'BigQueryTableReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReferences'->new($_) };

declare 'RepeatedBigQueryTableReferences',
    as ArrayRef[BigQueryTableReferences()];

coerce 'RepeatedBigQueryTableReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReferences'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableReferences',
    as HashRef[BigQueryTableReferences()];

declare 'BigQueryTableReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference'];

coerce 'BigQueryTableReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference'->new($_) };

declare 'RepeatedBigQueryTableReference',
    as ArrayRef[BigQueryTableReference()];

coerce 'RepeatedBigQueryTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryTableReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableReference',
    as HashRef[BigQueryTableReference()];

declare 'BigQueryDatasetReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryDatasetReference'];

coerce 'BigQueryDatasetReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryDatasetReference'->new($_) };

declare 'RepeatedBigQueryDatasetReference',
    as ArrayRef[BigQueryDatasetReference()];

coerce 'RepeatedBigQueryDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryDatasetReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryDatasetReference',
    as HashRef[BigQueryDatasetReference()];

declare 'SearchScope',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::SearchScope'];

coerce 'SearchScope',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::SearchScope'->new($_) };

declare 'RepeatedSearchScope',
    as ArrayRef[SearchScope()];

coerce 'RepeatedSearchScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::SearchScope'->new($_) } @$_ ] };

declare 'MapStringSearchScope',
    as HashRef[SearchScope()];

declare 'StudioDatasourceReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReferences'];

coerce 'StudioDatasourceReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReferences'->new($_) };

declare 'RepeatedStudioDatasourceReferences',
    as ArrayRef[StudioDatasourceReferences()];

coerce 'RepeatedStudioDatasourceReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReferences'->new($_) } @$_ ] };

declare 'MapStringStudioDatasourceReferences',
    as HashRef[StudioDatasourceReferences()];

declare 'StudioDatasourceReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReference'];

coerce 'StudioDatasourceReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReference'->new($_) };

declare 'RepeatedStudioDatasourceReference',
    as ArrayRef[StudioDatasourceReference()];

coerce 'RepeatedStudioDatasourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::StudioDatasourceReference'->new($_) } @$_ ] };

declare 'MapStringStudioDatasourceReference',
    as HashRef[StudioDatasourceReference()];

declare 'LookerExploreReferences',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReferences'];

coerce 'LookerExploreReferences',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReferences'->new($_) };

declare 'RepeatedLookerExploreReferences',
    as ArrayRef[LookerExploreReferences()];

coerce 'RepeatedLookerExploreReferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReferences'->new($_) } @$_ ] };

declare 'MapStringLookerExploreReferences',
    as HashRef[LookerExploreReferences()];

declare 'LookerExploreReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference'];

coerce 'LookerExploreReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference'->new($_) };

declare 'RepeatedLookerExploreReference',
    as ArrayRef[LookerExploreReference()];

coerce 'RepeatedLookerExploreReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::LookerExploreReference'->new($_) } @$_ ] };

declare 'MapStringLookerExploreReference',
    as HashRef[LookerExploreReference()];

declare 'BigQueryPropertyGraphReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference'];

coerce 'BigQueryPropertyGraphReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference'->new($_) };

declare 'RepeatedBigQueryPropertyGraphReference',
    as ArrayRef[BigQueryPropertyGraphReference()];

coerce 'RepeatedBigQueryPropertyGraphReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::BigQueryPropertyGraphReference'->new($_) } @$_ ] };

declare 'MapStringBigQueryPropertyGraphReference',
    as HashRef[BigQueryPropertyGraphReference()];

declare 'PrivateLookerInstanceInfo',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::PrivateLookerInstanceInfo'];

coerce 'PrivateLookerInstanceInfo',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::PrivateLookerInstanceInfo'->new($_) };

declare 'RepeatedPrivateLookerInstanceInfo',
    as ArrayRef[PrivateLookerInstanceInfo()];

coerce 'RepeatedPrivateLookerInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::PrivateLookerInstanceInfo'->new($_) } @$_ ] };

declare 'MapStringPrivateLookerInstanceInfo',
    as HashRef[PrivateLookerInstanceInfo()];

declare 'Datasource',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::Datasource'];

coerce 'Datasource',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::Datasource'->new($_) };

declare 'RepeatedDatasource',
    as ArrayRef[Datasource()];

coerce 'RepeatedDatasource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::Datasource'->new($_) } @$_ ] };

declare 'MapStringDatasource',
    as HashRef[Datasource()];

declare 'Schema',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'Field',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'DataFilter',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Datasource::DataFilter'];

coerce 'DataFilter',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Datasource::DataFilter'->new($_) };

declare 'RepeatedDataFilter',
    as ArrayRef[DataFilter()];

coerce 'RepeatedDataFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Datasource::DataFilter'->new($_) } @$_ ] };

declare 'MapStringDataFilter',
    as HashRef[DataFilter()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::Datasource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
