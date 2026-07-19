use strict;
use warnings;

use JSON::MaybeXS qw(decode_json encode_json);
use Test::More 0.98;
use File::Temp qw(tempfile);

use GraphQL::Houtou ();
use GraphQL::Houtou::Runtime::OperationCompiler ();
use GraphQL::Houtou::Runtime::VMCompiler ();
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);
use GraphQL::Houtou::Type::Union;

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

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
    name => { type => $String },
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
        resolve => sub { +{ kind => 'user', id => 'u1', name => 'Ana' } },
      },
      greet => {
        type => $String,
        args => {
          name => { type => $String },
        },
        resolve => sub { 'hello' },
      },
      search => {
        type => $SearchResult->list->non_null,
        resolve => sub { [] },
      },
    },
  ),
  types => [ $User, $Node, $SearchResult ],
);

sub lower_vm_program {
  my ($runtime, $document) = @_;
  return GraphQL::Houtou::Runtime::VMCompiler->inflate_program(
    $runtime,
    $runtime->compile_program_descriptor($document),
  );
}

subtest 'schema runtime can lower source into execution program' => sub {
  my $runtime = $schema->compile_runtime;
  my $native_program = $runtime->compile_program('{ viewer { id name } }');
  my $program = lower_vm_program($runtime, '{ viewer { id name } }');

  isa_ok $native_program, 'GraphQL::Houtou::Runtime::NativeProgram';
  isa_ok $program, 'GraphQL::Houtou::Runtime::VMProgram';
  isa_ok $program->root_block, 'GraphQL::Houtou::Runtime::VMBlock';
  is $program->operation_type, 'query', 'query operation inferred';
  is $program->root_block->type_name, 'Query', 'root block keeps root type';

  my ($viewer) = @{ $program->root_block->ops };
  is $viewer->field_name, 'viewer', 'viewer field lowered';
  is $viewer->resolve_family, 'RESOLVE_EXPLICIT', 'explicit resolver lowered';
  is $viewer->complete_family, 'COMPLETE_OBJECT', 'object completion lowered';
  ok $viewer->child_block_name, 'child block emitted for object field';

  my $child = $program->block_by_name($viewer->child_block_name);
  isa_ok $child, 'GraphQL::Houtou::Runtime::VMBlock';
  is $child->type_name, 'User', 'child block uses concrete object type';
  is_deeply [ map { $_->field_name } @{ $child->ops } ], [ qw(id name) ], 'child field instructions lowered';
};

subtest 'top-level helper can lower operation source' => sub {
  my $runtime = $schema->compile_runtime;
  my $program = GraphQL::Houtou::Runtime::OperationCompiler->compile_operation($runtime, '{ search }');

  isa_ok $program, 'GraphQL::Houtou::Runtime::VMProgram';
  my ($search) = @{ $program->root_block->ops };
  is $search->complete_family, 'COMPLETE_LIST', 'list field lowers to list completion op';
  # A list of a union dispatches per item, so the op carries the inner
  # type's abstract dispatch family (plain object lists keep LIST).
  is $search->dispatch_family, 'TAG', 'list-of-union op carries abstract dispatch';
};

subtest 'execution program can round-trip through struct form' => sub {
  my $struct = $schema->compile_program_descriptor('{ viewer { id } }');
  my $program = GraphQL::Houtou::Runtime::VMCompiler->inflate_program(
    $schema->build_runtime,
    $struct,
  );
  my $root_block = $struct->{blocks_compact}[ $struct->{root_block_index} ];

  is $struct->{operation_type_code}, 1, 'descriptor keeps operation type code';
  is $struct->{root_block_index}, $program->root_block_index, 'descriptor keeps root block index';
  is $root_block->[4][0][2], 2, 'root op keeps complete code';
};

subtest 'execution program descriptor can round-trip back into executable program' => sub {
  my $runtime = $schema->compile_runtime;
  my $descriptor = $runtime->compile_program_descriptor('{ viewer { id name } }');
  my $program = $runtime->inflate_program($descriptor);
  my $inflated = GraphQL::Houtou::Runtime::VMCompiler->inflate_program($runtime, $descriptor);
  my $summary = GraphQL::Houtou::XS::VM::native_program_summary_xs($program);

  isa_ok $program, 'GraphQL::Houtou::Runtime::NativeProgram';
  isa_ok $inflated, 'GraphQL::Houtou::Runtime::VMProgram';
  is $inflated->operation_type, 'query', 'inflated program keeps operation type';
  is $summary->{root_block_index}, $descriptor->{root_block_index},
    'public inflate helper keeps root block index';
  is $summary->{block_count}, scalar(@{ $descriptor->{blocks_compact} || [] }),
    'public inflate helper keeps block count';
  is $inflated->root_block->name,
    $descriptor->{blocks_compact}[ $descriptor->{root_block_index} ][0],
    'inflated program keeps root block name';
  is scalar(@{ $inflated->blocks || [] }), scalar(@{ $descriptor->{blocks_compact} || [] }),
    'inflated program keeps block count';
  is_deeply
    [ map { $_->field_name } @{ $inflated->root_block->ops } ],
    [ qw(viewer) ],
    'inflated root block keeps instruction fields';
};

subtest 'schema helper can compile and inflate operation descriptors' => sub {
  my $descriptor = $schema->compile_program_descriptor('{ viewer { id } }');
  my $inflated = $schema->inflate_program($descriptor);
  my $summary = GraphQL::Houtou::XS::VM::native_program_summary_xs($inflated);

  isa_ok $inflated, 'GraphQL::Houtou::Runtime::NativeProgram';
  is $summary->{root_block_index}, $descriptor->{root_block_index},
    'schema helper inflates native program handle with root block index';
  is $summary->{block_count}, scalar(@{ $descriptor->{blocks_compact} || [] }),
    'schema helper inflates native program handle with block count';
};

subtest 'operation descriptor can round-trip through JSON file helpers' => sub {
  my ($fh, $path) = tempfile();
  close $fh;

  my $descriptor = $schema->compile_program_descriptor('{ viewer { id } }');
  open my $out, '>', $path or die $!;
  print {$out} encode_json($descriptor);
  close $out;
  open my $in, '<', $path or die $!;
  local $/;
  my $loaded = decode_json(<$in>);
  close $in;
  my $inflated = $schema->inflate_program($loaded);
  my $summary = GraphQL::Houtou::XS::VM::native_program_summary_xs($inflated);

  isa_ok $inflated, 'GraphQL::Houtou::Runtime::NativeProgram';
  is $summary->{root_block_index}, $descriptor->{root_block_index},
    'schema helper preserves root block index through file boundary';
  is $summary->{block_count}, scalar(@{ $descriptor->{blocks_compact} || [] }),
    'schema helper preserves block count through file boundary';
};

subtest 'instruction lowering classifies static and dynamic args' => sub {
  my $runtime = $schema->compile_runtime;
  my $static = lower_vm_program($runtime, '{ greet(name: "Ana") }');
  my $dynamic = lower_vm_program($runtime, 'query Q($name: String) { greet(name: $name) }');

  my ($static_greet) = grep { $_->field_name eq 'greet' } @{ $static->root_block->ops };
  my ($dynamic_greet) = grep { $_->field_name eq 'greet' } @{ $dynamic->root_block->ops };

  is $static_greet->args_mode, 'STATIC', 'static literal args are lowered as static payload';
  is_deeply $static_greet->args_payload, { name => 'Ana' }, 'static args are materialized during lowering';

  is $dynamic_greet->args_mode, 'DYNAMIC', 'variable args stay as dynamic payload';
  ok exists $dynamic_greet->args_payload->{name}, 'dynamic payload keeps argument key';
};

subtest 'operation variable definitions are lowered into immutable program metadata' => sub {
  my $runtime = $schema->compile_runtime;
  my $program = lower_vm_program($runtime, 'query Q($name: String = "Ana") { greet(name: $name) }');

  is_deeply $program->variable_defs, {
    name => {
      type => { type => 'String' },
      has_default => 1,
      default_value => 'Ana',
    },
  }, 'variable definitions are lowered onto the execution program';
};

subtest 'fragment spreads are normalized into lowered child blocks' => sub {
  my $runtime = $schema->compile_runtime;
  my $program = lower_vm_program($runtime, <<'GRAPHQL');
query Q {
  viewer { ...UserBits }
}

fragment UserBits on User {
  id
  name
}
GRAPHQL
  my ($viewer) = grep { $_->field_name eq 'viewer' } @{ $program->root_block->ops };
  my $child = $program->block_by_name($viewer->child_block_name);
  is_deeply [ map { $_->field_name } @{ $child->ops } ], [ qw(id name) ], 'fragment spread fields are lowered into child block';
};

subtest 'include/skip directives are lowered onto instructions as runtime guards' => sub {
  my $runtime = $schema->compile_runtime;
  my $program = lower_vm_program($runtime, 'query Q($show: Boolean) { viewer { id name @include(if: $show) } }');
  my ($viewer) = grep { $_->field_name eq 'viewer' } @{ $program->root_block->ops };
  my $child = $program->block_by_name($viewer->child_block_name);
  my ($name) = grep { $_->field_name eq 'name' } @{ $child->ops };

  is $name->directives_mode, 'DYNAMIC', 'dynamic include directive is kept as runtime guard payload';
  ok @{ $name->directives_payload || [] }, 'directive payload is retained on lowered instruction';
};

done_testing;
