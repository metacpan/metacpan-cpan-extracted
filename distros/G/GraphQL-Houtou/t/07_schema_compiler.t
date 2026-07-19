use strict;
use warnings;

use Test::More 0.98;

use GraphQL::Houtou::Directive;
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Enum;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Boolean $Int $String);
use GraphQL::Houtou::Type::Union;

my $Node;
my $User;

$Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => {
    id => { type => $String->non_null },
  },
  resolve_type => sub { $User },
  tag_resolver => sub { $_[0]{kind} },
);

my $Status = GraphQL::Houtou::Type::Enum->new(
  name => 'Status',
  values => {
    ACTIVE => {},
    DISABLED => {
      deprecation_reason => 'Use ACTIVE instead',
    },
  },
);

my $Filter = GraphQL::Houtou::Type::InputObject->new(
  name => 'Filter',
  fields => {
    q => { type => $String },
    limit => { type => $Int, default_value => 20 },
    exact => { type => $Boolean, default_value => 0 },
  },
);

$User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  interfaces => [ $Node ],
  is_type_of => sub { ref($_[0]) eq 'HASH' && $_[0]{kind} && $_[0]{kind} eq 'user' },
  runtime_tag => 'user',
  fields => {
    id => { type => $String->non_null },
    name => { type => $String },
    status => { type => $Status },
  },
);

my $SearchResult = GraphQL::Houtou::Type::Union->new(
  name => 'SearchResult',
  types => [ $User ],
  resolve_type => sub { $User },
  tag_resolver => sub { $_[0]{kind} },
);

my $auth = GraphQL::Houtou::Directive->new(
  name => 'auth',
  locations => [ qw(FIELD OBJECT) ],
  args => {
    role => { type => $String->non_null },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      viewer => {
        type => $User,
        directives => [
          { name => 'auth', arguments => { role => 'reader' } },
        ],
        resolve => sub { +{ kind => 'user', id => 'u1', name => 'Ana', status => 'ACTIVE' } },
      },
      search => {
        type => $SearchResult->list->non_null,
        args => {
          filter => { type => $Filter },
          ids => { type => $String->non_null->list },
        },
        resolve => sub { [] },
      },
    },
  ),
  types => [ $User, $Node, $SearchResult, $Filter, $Status ],
  directives => [ @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES, $auth ],
);

my $compiled = $schema->compile_runtime;
my $descriptor = $schema->compile_runtime_descriptor;
my $inflated = $schema->inflate_runtime($descriptor);

subtest 'Houtou wrappers stay in the Houtou namespace' => sub {
  isa_ok $schema, 'GraphQL::Houtou::Schema';
  isa_ok $schema->query, 'GraphQL::Houtou::Type::Object';
  isa_ok $schema->query->fields->{viewer}{type}, 'GraphQL::Houtou::Type::Object';
  isa_ok $schema->name2type->{Node}, 'GraphQL::Houtou::Type::Interface';
  isa_ok $schema->query->fields->{search}{type}, 'GraphQL::Houtou::Type::NonNull';
  isa_ok $schema->query->fields->{search}{type}->of, 'GraphQL::Houtou::Type::List';
  isa_ok $schema->query->fields->{search}{args}{ids}{type}->of, 'GraphQL::Houtou::Type::NonNull';
  isa_ok $schema->directives->[-1], 'GraphQL::Houtou::Directive';
  isa_ok $schema->name2type->{String}, 'GraphQL::Houtou::Type::Scalar';
  isa_ok $schema->name2type->{Status}, 'GraphQL::Houtou::Type::Enum';
  isa_ok $schema->name2type->{Filter}, 'GraphQL::Houtou::Type::InputObject';
  ok !$schema->query->fields->{search}{type}->isa('GraphQL::Type::NonNull'), 'non-null wrapper no longer uses upstream class';
  ok !$schema->query->fields->{search}{type}->of->isa('GraphQL::Type::List'), 'list wrapper no longer uses upstream class';
  ok !$schema->name2type->{String}->isa('GraphQL::Type::Scalar'), 'scalar no longer uses upstream class';
  ok !$schema->isa('GraphQL::Schema'), 'schema no longer uses upstream class';
  ok !$schema->directives->[-1]->isa('GraphQL::Directive'), 'directive no longer uses upstream class';
  ok !$schema->query->isa('GraphQL::Type::Object'), 'object no longer uses upstream class';
  ok !$schema->name2type->{Node}->isa('GraphQL::Type::Interface'), 'interface no longer uses upstream class';
  ok !$schema->name2type->{Status}->isa('GraphQL::Type::Enum'), 'enum no longer uses upstream class';
  ok !$schema->name2type->{Filter}->isa('GraphQL::Type::InputObject'), 'input object no longer uses upstream class';
};

subtest 'Houtou types consume Houtou roles' => sub {
  ok $schema->query->DOES('GraphQL::Houtou::Role::Output'), 'object uses Houtou output role';
  ok $schema->query->DOES('GraphQL::Houtou::Role::FieldsOutput'), 'object uses Houtou fields output role';
  ok $schema->name2type->{Node}->DOES('GraphQL::Houtou::Role::Abstract'), 'interface uses Houtou abstract role';
  ok $schema->name2type->{Filter}->DOES('GraphQL::Houtou::Role::Input'), 'input object uses Houtou input role';
  ok $schema->name2type->{Filter}->DOES('GraphQL::Houtou::Role::FieldsInput'), 'input object uses Houtou fields input role';
  ok $schema->name2type->{Status}->DOES('GraphQL::Houtou::Role::Leaf'), 'enum uses Houtou leaf role';
  ok $schema->directives->[-1]->can('name'), 'directive keeps named accessor without helper role';
  ok defined $schema->directives->[-1]->name, 'directive accessor returns a directive name';
  ok !$schema->query->DOES('GraphQL::Role::Output'), 'object no longer depends on upstream output role';
  ok !$schema->name2type->{Filter}->DOES('GraphQL::Role::Input'), 'input object no longer depends on upstream input role';
  isa_ok $compiled, 'GraphQL::Houtou::Runtime::SchemaGraph';
  isa_ok $inflated, 'GraphQL::Houtou::Runtime::SchemaGraph';
};

subtest 'runtime schema cache can be warmed explicitly' => sub {
  ok $schema->runtime_cache, 'compile_runtime primes runtime_cache';
  $schema->clear_runtime_cache;
  is $schema->runtime_cache, undef, 'clear_runtime_cache clears getter-visible cache';

  my $cache = $schema->prepare_runtime;

  is $cache->{root_types}{query}->name, 'Query', 'prepare_runtime exposes query root';
  is $cache->{name2type}{User}->name, 'User', 'prepare_runtime exposes named type cache';
  is_deeply(
    [ map $_->name, @{ $cache->{interface2types}{Node} || [] } ],
    ['User'],
    'prepare_runtime exposes interface implementation cache',
  );
  is ref($cache->{resolve_type_map}{Node}), 'CODE', 'prepare_runtime caches interface resolve_type callback';
  is ref($cache->{resolve_type_map}{SearchResult}), 'CODE', 'prepare_runtime caches union resolve_type callback';
  is ref($cache->{is_type_of_map}{User}), 'CODE', 'prepare_runtime caches object is_type_of callback';
  is ref($cache->{tag_resolver_map}{Node}), 'CODE', 'prepare_runtime caches interface tag_resolver callback';
  is ref($cache->{tag_resolver_map}{SearchResult}), 'CODE', 'prepare_runtime caches union tag_resolver callback';
  is $cache->{runtime_tag_map}{Node}{user}->name, 'User', 'prepare_runtime caches interface runtime tag map';
  is $cache->{runtime_tag_map}{SearchResult}{user}->name, 'User', 'prepare_runtime caches union runtime tag map';

  is $schema->runtime_cache, $cache, 'runtime_cache returns warmed cache';
  $schema->clear_runtime_cache;
  is $schema->runtime_cache, undef, 'clear_runtime_cache clears getter-visible cache';
  isnt $schema->prepare_runtime, $cache, 'clear_runtime_cache forces rebuild';
};

subtest 'runtime graph is descriptor-roundtrip stable' => sub {
  is_deeply $compiled->to_struct, $inflated->to_struct, 'inflate_runtime preserves runtime graph shape';
};

subtest 'root blocks and slots are compiled' => sub {
  is_deeply $compiled->root_types, {
    query => 'Query',
  }, 'root_types keep active root names';

  my $query_block = $compiled->root_block('query');
  isa_ok $query_block, 'GraphQL::Houtou::Runtime::SchemaBlock';
  is $query_block->root_type_name, 'Query', 'query block points at Query';

  my ($viewer_slot) = grep { $_->field_name eq 'viewer' } @{ $query_block->slots || [] };
  ok $viewer_slot, 'viewer slot is present';
  is $viewer_slot->completion_family, 'OBJECT', 'viewer slot is object family';
  is $viewer_slot->dispatch_family, 'OBJECT', 'viewer slot dispatch stays object';

  my ($search_slot) = grep { $_->field_name eq 'search' } @{ $query_block->slots || [] };
  ok $search_slot, 'search slot is present';
  is $search_slot->completion_family, 'LIST', 'search slot is list family';
  # A list of a union dispatches per item, so the slot carries the inner
  # type's abstract dispatch family (plain object lists keep LIST).
  is $search_slot->dispatch_family, 'TAG', 'list-of-union slot carries abstract dispatch';
  my ($ids_arg) = grep { $_->[0] eq 'ids' } @{ $search_slot->arg_defs_compact || [] };
  is_deeply $ids_arg, [
    'ids',
    { type => ['list', { type => ['non_null', { type => 'String' }] }] },
    0,
    undef,
  ], 'argument lowering preserves compact arg defs';
};

subtest 'type and dispatch indexes are compiled' => sub {
  is $compiled->type_index->{Query}{kind}, 'OBJECT', 'query root kind';
  is $compiled->type_index->{Node}{kind}, 'INTERFACE', 'interface kind';
  is $compiled->type_index->{SearchResult}{kind}, 'UNION', 'union kind';
  is $compiled->type_index->{Filter}{kind}, 'INPUT_OBJECT', 'input object kind';
  is $compiled->type_index->{Status}{kind}, 'ENUM', 'enum kind';

  is $compiled->type_index->{User}{runtime_tag}, 'user', 'runtime_tag is indexed';
  is $compiled->dispatch_index->{Node}{dispatch_family}, 'TAG', 'interface dispatch prefers tag resolver';
  is $compiled->dispatch_index->{SearchResult}{dispatch_family}, 'TAG', 'union dispatch prefers tag resolver';
};

subtest 'slot catalog and block lookup are stable' => sub {
  my $user_block = $compiled->block_by_type_name('User');
  isa_ok $user_block, 'GraphQL::Houtou::Runtime::SchemaBlock';
  is $user_block->name, 'USER', 'user block can be looked up by type name';

  my $slot = $compiled->slot_by_index(0);
  isa_ok $slot, 'GraphQL::Houtou::Runtime::Slot';
  like $slot->schema_slot_key, qr/\AQuery\./, 'slot catalog exposes schema slot keys';
};

subtest 'native descriptors are available from runtime graph' => sub {
  my $native = $compiled->to_native_struct;
  ok ref($native->{slot_catalog}) eq 'ARRAY', 'native struct exposes slot catalog';
  ok ref($native->{dispatch_index}) eq 'HASH', 'native struct exposes dispatch index';

  my $compact = $compiled->to_native_compact_struct;
  ok ref($compact->{slot_catalog_compact}) eq 'ARRAY', 'compact native struct exposes compact slot catalog';
};

done_testing;
