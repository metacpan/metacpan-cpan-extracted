package Google::Firestore::Admin::V1::Index::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Index',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index'];

coerce 'Index',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index'->new($_) };

declare 'RepeatedIndex',
    as ArrayRef[Index()];

coerce 'RepeatedIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index'->new($_) } @$_ ] };

declare 'MapStringIndex',
    as HashRef[Index()];

declare 'QueryScope',
    as (Int | Str);

declare 'ApiScope',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Density',
    as (Int | Str);

declare 'IndexField',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField'];

coerce 'IndexField',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField'->new($_) };

declare 'RepeatedIndexField',
    as ArrayRef[IndexField()];

coerce 'RepeatedIndexField',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField'->new($_) } @$_ ] };

declare 'MapStringIndexField',
    as HashRef[IndexField()];

declare 'Order',
    as (Int | Str);

declare 'ArrayConfig',
    as (Int | Str);

declare 'VectorConfig',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField::VectorConfig'];

coerce 'VectorConfig',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField::VectorConfig'->new($_) };

declare 'RepeatedVectorConfig',
    as ArrayRef[VectorConfig()];

coerce 'RepeatedVectorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField::VectorConfig'->new($_) } @$_ ] };

declare 'MapStringVectorConfig',
    as HashRef[VectorConfig()];

declare 'FlatIndex',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField::VectorConfig::FlatIndex'];

coerce 'FlatIndex',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField::VectorConfig::FlatIndex'->new($_) };

declare 'RepeatedFlatIndex',
    as ArrayRef[FlatIndex()];

coerce 'RepeatedFlatIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField::VectorConfig::FlatIndex'->new($_) } @$_ ] };

declare 'MapStringFlatIndex',
    as HashRef[FlatIndex()];

declare 'SearchConfig',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig'];

coerce 'SearchConfig',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig'->new($_) };

declare 'RepeatedSearchConfig',
    as ArrayRef[SearchConfig()];

coerce 'RepeatedSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig'->new($_) } @$_ ] };

declare 'MapStringSearchConfig',
    as HashRef[SearchConfig()];

declare 'TextIndexType',
    as (Int | Str);

declare 'TextMatchType',
    as (Int | Str);

declare 'SearchTextIndexSpec',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchTextIndexSpec'];

coerce 'SearchTextIndexSpec',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchTextIndexSpec'->new($_) };

declare 'RepeatedSearchTextIndexSpec',
    as ArrayRef[SearchTextIndexSpec()];

coerce 'RepeatedSearchTextIndexSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchTextIndexSpec'->new($_) } @$_ ] };

declare 'MapStringSearchTextIndexSpec',
    as HashRef[SearchTextIndexSpec()];

declare 'SearchTextSpec',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchTextSpec'];

coerce 'SearchTextSpec',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchTextSpec'->new($_) };

declare 'RepeatedSearchTextSpec',
    as ArrayRef[SearchTextSpec()];

coerce 'RepeatedSearchTextSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchTextSpec'->new($_) } @$_ ] };

declare 'MapStringSearchTextSpec',
    as HashRef[SearchTextSpec()];

declare 'SearchGeoSpec',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchGeoSpec'];

coerce 'SearchGeoSpec',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchGeoSpec'->new($_) };

declare 'RepeatedSearchGeoSpec',
    as ArrayRef[SearchGeoSpec()];

coerce 'RepeatedSearchGeoSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::IndexField::SearchConfig::SearchGeoSpec'->new($_) } @$_ ] };

declare 'MapStringSearchGeoSpec',
    as HashRef[SearchGeoSpec()];

declare 'SearchIndexOptions',
    as InstanceOf['Google::Firestore::Admin::V1::Index::Index::SearchIndexOptions'];

coerce 'SearchIndexOptions',
    from HashRef, via { 'Google::Firestore::Admin::V1::Index::Index::SearchIndexOptions'->new($_) };

declare 'RepeatedSearchIndexOptions',
    as ArrayRef[SearchIndexOptions()];

coerce 'RepeatedSearchIndexOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::Admin::V1::Index::Index::SearchIndexOptions'->new($_) } @$_ ] };

declare 'MapStringSearchIndexOptions',
    as HashRef[SearchIndexOptions()];

1;

__END__

=head1 NAME

Google::Firestore::Admin::V1::Index::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
