use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use lib 'lib';
use GraphQL::Houtou ();
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Runtime::VMCompiler ();
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Scalar qw($String);

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'VmNode',
  fields => {
    id => { type => $String },
  },
  tag_resolver => sub { $_[0]{kind} },
);

my $User = GraphQL::Houtou::Type::Object->new(
  name => 'VmUser',
  interfaces => [ $Node ],
  runtime_tag => 'user',
  fields => {
    id => { type => $String },
  },
);

my $Query = GraphQL::Houtou::Type::Object->new(
  name => 'VmQuery',
  fields => {
    viewer => {
      type => $User,
      resolve => sub { return { id => 'u1' } },
    },
    node => {
      type => $Node,
      resolve => sub { return { kind => 'user', id => 'u2' } },
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => $Query,
  types => [ $User, $Node ],
);

sub lower_vm_program {
  my ($schema, $document) = @_;
  my $runtime = $schema->build_runtime;
  return GraphQL::Houtou::Runtime::VMCompiler->inflate_program(
    $runtime,
    $runtime->compile_program_descriptor($document),
  );
}

subtest 'schema can lower operation into VM program' => sub {
  my $native_program = $schema->compile_program('{ viewer { id } node { id } }');
  my $vm = lower_vm_program($schema, '{ viewer { id } node { id } }');
  isa_ok $native_program, 'GraphQL::Houtou::Runtime::NativeProgram';
  isa_ok $vm, 'GraphQL::Houtou::Runtime::VMProgram';
  isa_ok $vm->root_block, 'GraphQL::Houtou::Runtime::VMBlock';
  is $vm->operation_type, 'query', 'vm program keeps operation type';
  my ($viewer, $node) = @{ $vm->root_block->ops || [] };
  like $viewer->opcode, qr/^RESOLVE_.*:COMPLETE_OBJECT$/, 'viewer lowers to object completion opcode';
  like $node->opcode, qr/^RESOLVE_.*:COMPLETE_ABSTRACT$/, 'node lowers to abstract completion opcode';
  is $node->abstract_child_blocks->{VmUser}, 'QUERY.node.VmUser#1',
    'abstract op keeps lowered child block mapping';
  ok $viewer->resolve_code, 'viewer op has resolve code';
  ok $viewer->complete_code, 'viewer op has complete code';
  ok $viewer->opcode_code, 'viewer op has opcode code';
  ok $viewer->opcode_code, 'viewer op binds numeric opcode code';
  is $viewer->resolve_code, 2, 'viewer op binds resolve family code';
  is $viewer->complete_code, 2, 'viewer op binds complete family code';
  isa_ok $vm->block_by_name('QUERY.node.VmUser#1'), 'GraphQL::Houtou::Runtime::VMBlock',
    'vm program keeps direct block map';
};

subtest 'VM program descriptor can round-trip through schema helpers' => sub {
  my $descriptor = $schema->compile_program_descriptor('{ viewer { id } }');
  my $vm = $schema->inflate_program($descriptor);
  isa_ok $vm, 'GraphQL::Houtou::Runtime::NativeProgram';
  my $summary = GraphQL::Houtou::XS::VM::native_program_summary_xs($vm);
  is $summary->{root_block_index}, $descriptor->{root_block_index},
    'inflated native program keeps root block index';
  is $summary->{block_count}, scalar(@{ $descriptor->{blocks_compact} || [] }),
    'inflated native program keeps block count';
};

subtest 'schema can emit XS-friendly native VM descriptor' => sub {
  my $descriptor = $schema->compile_native_program_descriptor('{ viewer { id } node { id } }');
  ok defined $descriptor->{root_block_index}, 'native descriptor keeps root block index';
  ok ref($descriptor->{blocks_compact}) eq 'ARRAY' && @{$descriptor->{blocks_compact}} >= 2,
    'native descriptor keeps indexed blocks';
  my $root = $descriptor->{blocks_compact}[ $descriptor->{root_block_index} ];
  ok ref($root->[3]) eq 'ARRAY' && @{$root->[3]} >= 2,
    'native block keeps compact slot table';
  ok defined $root->[3][0][3],
    'native block slot keeps schema slot index';
  ok $root->[4][0][0], 'native op keeps opcode code';
  ok defined $root->[4][0][4], 'native op keeps slot index';
  ok exists $root->[4][1][6]{VmUser},
    'native op keeps abstract child block indexes';
};

subtest 'native VM program descriptor can inflate into a native program handle' => sub {
  my $descriptor = $schema->compile_native_program_descriptor('{ viewer { id } node { id } }');
  my $handle = GraphQL::Houtou::XS::VM::load_native_program_xs($descriptor);

  isa_ok $handle, 'GraphQL::Houtou::Runtime::NativeProgram';
  my $summary = GraphQL::Houtou::XS::VM::native_program_summary_xs($handle);
  is $summary->{block_count}, scalar(@{ $descriptor->{blocks_compact} || [] }),
    'native program handle sees block count';
  is $summary->{root_block_index}, $descriptor->{root_block_index},
    'native program handle keeps root block index';
};

subtest 'schema can emit bundled native runtime and VM descriptor' => sub {
  my $bundle = $schema->compile_native_bundle_descriptor('{ viewer { id } node { id } }');
  my $codes = GraphQL::Houtou::XS::VM::native_codes_xs();
  ok ref($bundle->{runtime}{slot_catalog_compact}) eq 'ARRAY' && @{$bundle->{runtime}{slot_catalog_compact}} >= 2,
    'native bundle keeps runtime slot catalog';
  ok defined $bundle->{runtime}{slot_catalog_compact}[0][5],
    'native bundle keeps runtime numeric family code';
  is $bundle->{runtime}{slot_catalog_compact}[1][5], $codes->{family_abstract},
    'native runtime family code matches XS header constant';
  is $bundle->{runtime}{slot_catalog_compact}[1][7], $codes->{kind_interface},
    'native runtime slot keeps return type kind code';
  ok ref($bundle->{program}{blocks_compact}) eq 'ARRAY' && @{$bundle->{program}{blocks_compact}} >= 2,
    'native bundle keeps vm program blocks';
  is $bundle->{program}{operation_type_code}, $codes->{optype_query},
    'native bundle keeps operation type code';
  is $bundle->{program}{blocks_compact}[ $bundle->{program}{root_block_index} ][2], $codes->{family_object},
    'native bundle keeps block family code';
  ok defined $bundle->{program}{blocks_compact}[ $bundle->{program}{root_block_index} ][4][0][4],
    'native bundle op keeps slot index';
  is $bundle->{program}{blocks_compact}[ $bundle->{program}{root_block_index} ][4][0][1], $codes->{resolve_explicit},
    'native op resolve code matches XS header constant';
  is $bundle->{program}{blocks_compact}[ $bundle->{program}{root_block_index} ][4][1][3], $codes->{dispatch_tag},
    'native op dispatch family code matches XS header constant';
};

subtest 'native VM bundle descriptor can round-trip through JSON helpers' => sub {
  my ($fh, $path) = tempfile();
  close $fh;

  my $descriptor = $schema->dump_native_bundle_descriptor('{ viewer { id } node { id } }', $path);
  my $loaded = $schema->load_native_bundle_descriptor($path);

  is_deeply $loaded, $descriptor, 'native bundle survives JSON file boundary';
};

subtest 'native VM bundle can inflate back into a VM program' => sub {
  my $bundle = $schema->compile_native_bundle_descriptor('{ viewer { id } node { id } }');
  my $vm = $schema->inflate_native_bundle_descriptor($bundle);
  isa_ok $vm, 'GraphQL::Houtou::Runtime::VMProgram';
  isa_ok $vm->root_block, 'GraphQL::Houtou::Runtime::VMBlock';
  is $vm->root_block->ops->[0]->field_name, 'viewer', 'inflated native bundle restores field name';
};

subtest 'XS can inflate native VM bundle descriptor into a native handle' => sub {
  my $bundle = $schema->compile_native_bundle_descriptor('{ viewer { id } node { id } }');
  my $codes = GraphQL::Houtou::XS::VM::native_codes_xs();
  my $handle = GraphQL::Houtou::XS::VM::load_native_bundle_xs($bundle);

  isa_ok $handle, 'GraphQL::Houtou::Runtime::NativeBundle';

  my $summary = GraphQL::Houtou::XS::VM::native_bundle_summary_xs($handle);
  is $summary->{runtime_slot_count}, scalar(@{ $bundle->{runtime}{slot_catalog_compact} || [] }),
    'XS native handle sees runtime slot count';
  is $summary->{block_count}, scalar(@{ $bundle->{program}{blocks_compact} || [] }),
    'XS native handle sees block count';
  is $summary->{root_block_index}, $bundle->{program}{root_block_index},
    'XS native handle keeps root block index';
  is $summary->{operation_type_code}, $codes->{optype_query},
    'XS native handle keeps operation type code';
  is $summary->{root_family_code}, $codes->{family_object},
    'XS native handle keeps root block family code';
  is_deeply $summary->{root_dispatch_family_codes}, [ $codes->{dispatch_generic}, $codes->{dispatch_tag} ],
    'XS native handle keeps root op dispatch family codes';
};

subtest 'XS can inflate runtime schema into a native runtime handle' => sub {
  my $runtime = $schema->build_runtime;
  my $handle = GraphQL::Houtou::XS::VM::load_native_runtime_xs($runtime->to_native_exec_struct);

  isa_ok $handle, 'GraphQL::Houtou::Runtime::NativeRuntime';

  my $summary = GraphQL::Houtou::XS::VM::native_runtime_summary_xs($handle);
  is $summary->{runtime_slot_count}, scalar(@{ $runtime->slot_catalog || [] }),
    'native runtime handle sees slot catalog count';
  ok $summary->{has_slot_type_objects}, 'native runtime handle keeps concrete type objects';
  ok $summary->{has_tag_dispatch_tables}, 'native runtime handle keeps tag dispatch tables';
  ok $summary->{has_possible_type_entries}, 'native runtime handle keeps possible-type entries';
};

done_testing;
