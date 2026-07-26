use strict;
use warnings;

use Test::More 0.98;
use File::Temp qw(tempfile);

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Runtime::SchemaGraph ();
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::Type::Union;

my $User;

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => {
    id => { type => $String->non_null },
  },
  tag_resolver => sub { $_[0]{kind} },
);

$User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  interfaces => [ $Node ],
  runtime_tag => 'user',
  fields => {
    id => { type => $String->non_null },
    name => { type => $String, accessor => 'display_name' },
  },
);

my $SearchResult = GraphQL::Houtou::Type::Union->new(
  name => 'SearchResult',
  types => [ $User ],
  tag_resolver => sub { $_[0]{kind} },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      viewer => {
        type => $User,
        resolver_mode => 'native',
        resolve => sub { +{ kind => 'user', id => 'u1', name => 'Ana' } },
      },
      ping => {
        type => $String,
        resolver_mode => 'fast_resolve_no_args',
        resolve => sub { 'pong' },
      },
      echo => {
        type => $String,
        resolver_mode => 'fast_resolve_one_arg',
        args => { value => { type => $String } },
        resolve => sub { $_[1] },
      },
      search => {
        type => $SearchResult->list->non_null,
        resolve => sub { [] },
      },
    },
  ),
  types => [ $User, $Node, $SearchResult ],
);

subtest 'schema can compile runtime graph' => sub {
  my $compiled = $schema->build_runtime;

  isa_ok $compiled, 'GraphQL::Houtou::Runtime::SchemaGraph';
  isa_ok $compiled->root_block('query'), 'GraphQL::Houtou::Runtime::SchemaBlock';
  is $compiled->root_types->{query}, 'Query', 'query root type is compiled';
};

subtest 'top-level compile helper returns same graph kind' => sub {
  my $compiled = GraphQL::Houtou::Runtime::SchemaGraph->compile_schema($schema);
  isa_ok $compiled, 'GraphQL::Houtou::Runtime::SchemaGraph';
};

subtest 'runtime graph records field families and dispatch shapes' => sub {
  my $compiled = $schema->compile_runtime;
  my $block = $compiled->root_block('query');
  my %slots = map { ($_->field_name => $_) } @{ $block->slots };

  is $slots{viewer}->completion_family, 'OBJECT', 'viewer compiles to object family';
  is $slots{viewer}->resolver_shape, 'EXPLICIT', 'viewer keeps explicit resolver shape';
  is $slots{viewer}->resolver_mode, 'NATIVE', 'viewer keeps native resolver mode';
  is $slots{ping}->resolver_mode, 'NATIVE_NO_ARGS',
    'ping keeps native_no_args resolver mode';
  is $slots{ping}->callback_abi_code, 4,
    'ping uses the native no-args callback ABI';
  is $slots{echo}->resolver_mode, 'NATIVE_ONE_ARG',
    'echo keeps native_one_arg resolver mode';
  is $slots{echo}->callback_abi_code, 5,
    'echo uses the native one-argument callback ABI';
  is $slots{search}->completion_family, 'LIST', 'search compiles to list family';
  is $compiled->type_index->{Node}{completion_family}, 'ABSTRACT', 'interface recorded as abstract family';
  is $compiled->dispatch_index->{SearchResult}{dispatch_family}, 'TAG', 'union tag dispatch is compiled';
};

subtest 'runtime graph can round-trip through descriptor form' => sub {
  my $descriptor = $schema->compile_runtime_descriptor;
  my $inflated = GraphQL::Houtou::Runtime::SchemaGraph->inflate_schema($schema, $descriptor);

  isa_ok $inflated, 'GraphQL::Houtou::Runtime::SchemaGraph';
  is $inflated->root_block('query')->name, 'QUERY', 'inflated graph restores root block';
  is $inflated->root_block('query')->slots->[0]->can('field_name') ? 1 : 0, 1, 'inflated slot object responds to accessors';
  is_deeply $inflated->to_struct, $descriptor, 'descriptor round-trip is stable';
};

subtest 'runtime graph can emit native descriptor' => sub {
  my $descriptor = $schema->compile_native_runtime_descriptor;
  my ($search_slot) = grep {
    (($_->{schema_slot_key} || q()) eq 'Query.search')
  } @{ $descriptor->{slot_catalog} || [] };
  my ($ping_slot) = grep {
    (($_->{schema_slot_key} || q()) eq 'Query.ping')
  } @{ $descriptor->{slot_catalog} || [] };
  my ($echo_slot) = grep {
    (($_->{schema_slot_key} || q()) eq 'Query.echo')
  } @{ $descriptor->{slot_catalog} || [] };
  my ($name_slot) = grep {
    (($_->{schema_slot_key} || q()) eq 'User.name')
  } @{ $descriptor->{slot_catalog} || [] };
  ok ref($descriptor->{slot_catalog}) eq 'ARRAY' && @{$descriptor->{slot_catalog}} >= 2,
    'native runtime descriptor exports slot catalog';
  ok defined $search_slot->{schema_slot_index},
    'native runtime slot keeps schema slot index';
  ok defined $search_slot->{completion_family_code},
    'native runtime slot keeps numeric family code';
  ok defined $search_slot->{resolver_mode_code},
    'native runtime slot keeps numeric resolver mode code';
  is $search_slot->{schema_slot_key}, 'Query.search',
    'native runtime slot keeps stable schema slot key';
  is $ping_slot->{resolver_mode_code}, 3,
    'native descriptor records the no-args resolver mode';
  is $ping_slot->{callback_abi_code}, 4,
    'native descriptor records the no-args callback ABI';
  is $echo_slot->{resolver_mode_code}, 4,
    'native descriptor records the one-argument resolver mode';
  is $echo_slot->{callback_abi_code}, 5,
    'native descriptor records the one-argument callback ABI';
  is $name_slot->{accessor}, 'display_name',
    'native descriptor records the accessor method name';
};

subtest 'runtime descriptor can round-trip through JSON file helpers' => sub {
  my ($fh, $path) = tempfile();
  close $fh;

  my $descriptor = $schema->dump_runtime_descriptor($path);
  my $inflated = $schema->load_runtime_descriptor($path);

  isa_ok $inflated, 'GraphQL::Houtou::Runtime::SchemaGraph';
  is_deeply $inflated->to_struct, $descriptor, 'schema helper preserves runtime descriptor through file boundary';
};

subtest 'runtime native descriptor can round-trip through JSON file helpers' => sub {
  my ($fh, $path) = tempfile();
  close $fh;

  my $descriptor = $schema->dump_native_runtime_descriptor($path);
  my $loaded = $schema->load_native_runtime_descriptor($path);

  is_deeply $loaded, $descriptor, 'schema helper preserves native runtime descriptor through file boundary';
};

done_testing;
