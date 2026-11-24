package Google::Cloud::Discoveryengine::V1alpha::Schema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Schema',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Schema::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Schema::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Schema::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'FieldConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Schema::FieldConfig'];

coerce 'FieldConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Schema::FieldConfig'->new($_) };

declare 'RepeatedFieldConfig',
    as ArrayRef[FieldConfig()];

coerce 'RepeatedFieldConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Schema::FieldConfig'->new($_) } @$_ ] };

declare 'MapStringFieldConfig',
    as HashRef[FieldConfig()];

declare 'FieldType',
    as (Int | Str);

declare 'IndexableOption',
    as (Int | Str);

declare 'DynamicFacetableOption',
    as (Int | Str);

declare 'SearchableOption',
    as (Int | Str);

declare 'RetrievableOption',
    as (Int | Str);

declare 'CompletableOption',
    as (Int | Str);

declare 'FilterableOption',
    as (Int | Str);

declare 'AdvancedSiteSearchDataSource',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Schema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
