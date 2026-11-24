package Google::Datastore::V1beta3::Query::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntityResult',
    as InstanceOf['Google::Datastore::V1beta3::Query::EntityResult'];

coerce 'EntityResult',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::EntityResult'->new($_) };

declare 'RepeatedEntityResult',
    as ArrayRef[EntityResult()];

coerce 'RepeatedEntityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::EntityResult'->new($_) } @$_ ] };

declare 'MapStringEntityResult',
    as HashRef[EntityResult()];

declare 'ResultType',
    as (Int | Str);

declare 'Query',
    as InstanceOf['Google::Datastore::V1beta3::Query::Query'];

coerce 'Query',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::Query'->new($_) };

declare 'RepeatedQuery',
    as ArrayRef[Query()];

coerce 'RepeatedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::Query'->new($_) } @$_ ] };

declare 'MapStringQuery',
    as HashRef[Query()];

declare 'KindExpression',
    as InstanceOf['Google::Datastore::V1beta3::Query::KindExpression'];

coerce 'KindExpression',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::KindExpression'->new($_) };

declare 'RepeatedKindExpression',
    as ArrayRef[KindExpression()];

coerce 'RepeatedKindExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::KindExpression'->new($_) } @$_ ] };

declare 'MapStringKindExpression',
    as HashRef[KindExpression()];

declare 'PropertyReference',
    as InstanceOf['Google::Datastore::V1beta3::Query::PropertyReference'];

coerce 'PropertyReference',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::PropertyReference'->new($_) };

declare 'RepeatedPropertyReference',
    as ArrayRef[PropertyReference()];

coerce 'RepeatedPropertyReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::PropertyReference'->new($_) } @$_ ] };

declare 'MapStringPropertyReference',
    as HashRef[PropertyReference()];

declare 'Projection',
    as InstanceOf['Google::Datastore::V1beta3::Query::Projection'];

coerce 'Projection',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::Projection'->new($_) };

declare 'RepeatedProjection',
    as ArrayRef[Projection()];

coerce 'RepeatedProjection',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::Projection'->new($_) } @$_ ] };

declare 'MapStringProjection',
    as HashRef[Projection()];

declare 'PropertyOrder',
    as InstanceOf['Google::Datastore::V1beta3::Query::PropertyOrder'];

coerce 'PropertyOrder',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::PropertyOrder'->new($_) };

declare 'RepeatedPropertyOrder',
    as ArrayRef[PropertyOrder()];

coerce 'RepeatedPropertyOrder',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::PropertyOrder'->new($_) } @$_ ] };

declare 'MapStringPropertyOrder',
    as HashRef[PropertyOrder()];

declare 'Direction',
    as (Int | Str);

declare 'Filter',
    as InstanceOf['Google::Datastore::V1beta3::Query::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'CompositeFilter',
    as InstanceOf['Google::Datastore::V1beta3::Query::CompositeFilter'];

coerce 'CompositeFilter',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::CompositeFilter'->new($_) };

declare 'RepeatedCompositeFilter',
    as ArrayRef[CompositeFilter()];

coerce 'RepeatedCompositeFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::CompositeFilter'->new($_) } @$_ ] };

declare 'MapStringCompositeFilter',
    as HashRef[CompositeFilter()];

declare 'Operator',
    as (Int | Str);

declare 'PropertyFilter',
    as InstanceOf['Google::Datastore::V1beta3::Query::PropertyFilter'];

coerce 'PropertyFilter',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::PropertyFilter'->new($_) };

declare 'RepeatedPropertyFilter',
    as ArrayRef[PropertyFilter()];

coerce 'RepeatedPropertyFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::PropertyFilter'->new($_) } @$_ ] };

declare 'MapStringPropertyFilter',
    as HashRef[PropertyFilter()];

declare 'Operator',
    as (Int | Str);

declare 'GqlQuery',
    as InstanceOf['Google::Datastore::V1beta3::Query::GqlQuery'];

coerce 'GqlQuery',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::GqlQuery'->new($_) };

declare 'RepeatedGqlQuery',
    as ArrayRef[GqlQuery()];

coerce 'RepeatedGqlQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::GqlQuery'->new($_) } @$_ ] };

declare 'MapStringGqlQuery',
    as HashRef[GqlQuery()];

declare 'NamedBindingsEntry',
    as InstanceOf['Google::Datastore::V1beta3::Query::GqlQuery::NamedBindingsEntry'];

coerce 'NamedBindingsEntry',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::GqlQuery::NamedBindingsEntry'->new($_) };

declare 'RepeatedNamedBindingsEntry',
    as ArrayRef[NamedBindingsEntry()];

coerce 'RepeatedNamedBindingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::GqlQuery::NamedBindingsEntry'->new($_) } @$_ ] };

declare 'MapStringNamedBindingsEntry',
    as HashRef[NamedBindingsEntry()];

declare 'GqlQueryParameter',
    as InstanceOf['Google::Datastore::V1beta3::Query::GqlQueryParameter'];

coerce 'GqlQueryParameter',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::GqlQueryParameter'->new($_) };

declare 'RepeatedGqlQueryParameter',
    as ArrayRef[GqlQueryParameter()];

coerce 'RepeatedGqlQueryParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::GqlQueryParameter'->new($_) } @$_ ] };

declare 'MapStringGqlQueryParameter',
    as HashRef[GqlQueryParameter()];

declare 'QueryResultBatch',
    as InstanceOf['Google::Datastore::V1beta3::Query::QueryResultBatch'];

coerce 'QueryResultBatch',
    from HashRef, via { 'Google::Datastore::V1beta3::Query::QueryResultBatch'->new($_) };

declare 'RepeatedQueryResultBatch',
    as ArrayRef[QueryResultBatch()];

coerce 'RepeatedQueryResultBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1beta3::Query::QueryResultBatch'->new($_) } @$_ ] };

declare 'MapStringQueryResultBatch',
    as HashRef[QueryResultBatch()];

declare 'MoreResultsType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Datastore::V1beta3::Query::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
