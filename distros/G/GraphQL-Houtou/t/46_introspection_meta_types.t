use strict;
use warnings;

use Test::More 0.98;

# Restored from legacy-tests/original-t/09_introspection.t: the
# introspection meta types (__Schema, __Type, ...) must be Houtou-owned
# wrappers, marked is_introspection, and registered in every schema's
# name2type map. This still holds on the current architecture unchanged.

use GraphQL::Houtou::Introspection qw(
  $TYPE_KIND_META_TYPE
  $DIRECTIVE_LOCATION_META_TYPE
  $ENUM_VALUE_META_TYPE
  $INPUT_VALUE_META_TYPE
  $FIELD_META_TYPE
  $DIRECTIVE_META_TYPE
  $TYPE_META_TYPE
  $SCHEMA_META_TYPE
  $SCHEMA_META_FIELD_DEF
  $TYPE_META_FIELD_DEF
  $TYPE_NAME_META_FIELD_DEF
);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

subtest 'meta types are Houtou-owned objects' => sub {
  isa_ok $TYPE_KIND_META_TYPE, 'GraphQL::Houtou::Type::Enum';
  isa_ok $DIRECTIVE_LOCATION_META_TYPE, 'GraphQL::Houtou::Type::Enum';
  isa_ok $ENUM_VALUE_META_TYPE, 'GraphQL::Houtou::Type::Object';
  isa_ok $INPUT_VALUE_META_TYPE, 'GraphQL::Houtou::Type::Object';
  isa_ok $FIELD_META_TYPE, 'GraphQL::Houtou::Type::Object';
  isa_ok $DIRECTIVE_META_TYPE, 'GraphQL::Houtou::Type::Object';
  isa_ok $TYPE_META_TYPE, 'GraphQL::Houtou::Type::Object';
  isa_ok $SCHEMA_META_TYPE, 'GraphQL::Houtou::Type::Object';

  ok !$TYPE_KIND_META_TYPE->isa('GraphQL::Type::Enum'), '__TypeKind no longer uses upstream enum class';
  ok !$SCHEMA_META_TYPE->isa('GraphQL::Type::Object'), '__Schema no longer uses upstream object class';
  ok $TYPE_META_TYPE->is_introspection, '__Type is marked as introspection';
  ok $SCHEMA_META_TYPE->is_introspection, '__Schema is marked as introspection';
};

subtest 'meta field definitions use Houtou type wrappers' => sub {
  isa_ok $SCHEMA_META_FIELD_DEF->{type}, 'GraphQL::Houtou::Type::NonNull';
  isa_ok $SCHEMA_META_FIELD_DEF->{type}->of, 'GraphQL::Houtou::Type::Object';
  isa_ok $TYPE_NAME_META_FIELD_DEF->{type}, 'GraphQL::Houtou::Type::NonNull';
  isa_ok $TYPE_NAME_META_FIELD_DEF->{type}->of, 'GraphQL::Houtou::Type::Scalar';
  isa_ok $TYPE_META_FIELD_DEF->{args}{name}{type}, 'GraphQL::Houtou::Type::NonNull';
  isa_ok $TYPE_META_FIELD_DEF->{args}{name}{type}->of, 'GraphQL::Houtou::Type::Scalar';
};

subtest 'schema exposes Houtou introspection types' => sub {
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        hello => { type => $String },
      },
    ),
  );

  isa_ok $schema->name2type->{__Schema}, 'GraphQL::Houtou::Type::Object';
  isa_ok $schema->name2type->{__Type}, 'GraphQL::Houtou::Type::Object';
  isa_ok $schema->name2type->{__DirectiveLocation}, 'GraphQL::Houtou::Type::Enum';
  ok $schema->name2type->{__Schema}->is_introspection, '__Schema remains tagged in schema map';
};

done_testing;
