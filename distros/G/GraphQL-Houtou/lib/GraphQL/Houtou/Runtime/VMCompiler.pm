package GraphQL::Houtou::Runtime::VMCompiler;

use 5.014;
use strict;
use warnings;

use GraphQL::Houtou::Runtime::OperationCompiler ();
use GraphQL::Houtou::Runtime::Slot ();
use GraphQL::Houtou::Runtime::VMBlock ();
use GraphQL::Houtou::Runtime::VMOp ();
use GraphQL::Houtou::Runtime::VMProgram ();

my %RESOLVE_CODE = (
  RESOLVE_DEFAULT => 1,
  RESOLVE_EXPLICIT => 2,
);


my %COMPLETE_CODE = (
  COMPLETE_GENERIC => 1,
  COMPLETE_OBJECT => 2,
  COMPLETE_LIST => 3,
  COMPLETE_ABSTRACT => 4,
);

sub lower_program {
  my ($class, $runtime_schema, $program) = @_;
  my @blocks = map { _lower_block($_) } @{ $program->blocks || [] };
  my %by_name = map { ($_->name => $_) } @blocks;
  my $root_block = $program->root_block ? $by_name{ $program->root_block->name } : undef;
  my $vm_program = GraphQL::Houtou::Runtime::VMProgram->new(
    version => 1,
    operation_type => $program->operation_type,
    operation_name => $program->operation_name,
    variable_defs => $program->can('variable_defs') ? ($program->variable_defs || {}) : {},
    blocks => \@blocks,
    root_block => $root_block,
    args_payloads => [],
    directives_payloads => [],
  );
  _bind_vm_ops($runtime_schema, $vm_program);
  return $vm_program;
}

sub inflate_program {
  my ($class, $runtime_schema, $struct) = @_;
  if ($struct->{blocks_compact}) {
    my @blocks = map { _inflate_native_block($_) } @{ $struct->{blocks_compact} || [] };
    my $root_block = defined $struct->{root_block_index}
      ? $blocks[ $struct->{root_block_index} ]
      : undef;
    my $vm_program = GraphQL::Houtou::Runtime::VMProgram->new(
      version => $struct->{version} || 1,
      operation_type => $struct->{operation_type} || _operation_type_from_code($struct->{operation_type_code}),
      operation_name => $struct->{operation_name},
      variable_defs => $struct->{variable_defs} || {},
      blocks => \@blocks,
      root_block => $root_block,
      args_payloads => $struct->{args_payloads_compact} || $struct->{args_payloads} || [],
      directives_payloads => $struct->{directives_payloads_compact} || $struct->{directives_payloads} || [],
    );
    _bind_native_vm_ops($runtime_schema, $vm_program, $struct);
    return $vm_program;
  }
  my @blocks = map { _inflate_block($_) } @{ $struct->{blocks} || [] };
  my %by_name = map { ($_->name => $_) } @blocks;
  my $root_block = defined $struct->{root_block} ? $by_name{ $struct->{root_block} } : undef;
  my $vm_program = GraphQL::Houtou::Runtime::VMProgram->new(
    version => $struct->{version} || 1,
    operation_type => $struct->{operation_type} || 'query',
    operation_name => $struct->{operation_name},
    variable_defs => $struct->{variable_defs} || {},
    blocks => \@blocks,
    root_block => $root_block,
    args_payloads => $struct->{args_payloads} || [],
    directives_payloads => $struct->{directives_payloads} || [],
  );
  _bind_vm_ops($runtime_schema, $vm_program);
  return $vm_program;
}

sub inflate_native_bundle {
  my ($class, $runtime_schema, $struct) = @_;
  my $program_struct = $struct->{program} || {};
  my $block_entries = $program_struct->{blocks_compact} || $program_struct->{blocks} || [];
  my @blocks = map { _inflate_native_block($_) } @{ $block_entries };
  my $root_block = defined $program_struct->{root_block_index}
    ? $blocks[ $program_struct->{root_block_index} ]
    : undef;
  my $vm_program = GraphQL::Houtou::Runtime::VMProgram->new(
    version => $program_struct->{version} || 1,
    operation_type => $program_struct->{operation_type} || _operation_type_from_code($program_struct->{operation_type_code}),
    operation_name => $program_struct->{operation_name},
    variable_defs => $program_struct->{variable_defs} || {},
    blocks => \@blocks,
    root_block => $root_block,
    args_payloads => $program_struct->{args_payloads_compact} || $program_struct->{args_payloads} || [],
    directives_payloads => $program_struct->{directives_payloads_compact} || $program_struct->{directives_payloads} || [],
  );
  _bind_native_vm_ops($runtime_schema, $vm_program, $program_struct);
  return $vm_program;
}

sub _lower_block {
  my ($block) = @_;
  return GraphQL::Houtou::Runtime::VMBlock->new(
    name => $block->name,
    type_name => $block->type_name,
    family => $block->family,
    ops => [ map { _lower_instruction($_) } @{ $block->instructions || [] } ],
  );
}

sub _inflate_block {
  my ($struct) = @_;
  return GraphQL::Houtou::Runtime::VMBlock->new(
    name => $struct->{name},
    type_name => $struct->{type_name},
    family => $struct->{family} || 'OBJECT',
    ops => [ map { _inflate_op($_) } @{ $struct->{ops} || [] } ],
  );
}

sub _lower_instruction {
  my ($instruction) = @_;
  my $resolve_family = $instruction->resolve_op || 'RESOLVE_DEFAULT';
  my $complete_family = $instruction->complete_op || 'COMPLETE_GENERIC';
  return GraphQL::Houtou::Runtime::VMOp->new(
    opcode => join(q(:), $resolve_family, $complete_family),
    opcode_code => (($RESOLVE_CODE{$resolve_family} || 0) * 16) + ($COMPLETE_CODE{$complete_family} || 0),
    resolve_family => $resolve_family,
    resolve_code => $RESOLVE_CODE{$resolve_family} || 0,
    complete_family => $complete_family,
    complete_code => $COMPLETE_CODE{$complete_family} || 0,
    field_name => $instruction->field_name,
    result_name => $instruction->result_name,
    return_type_name => $instruction->return_type_name,
    dispatch_family => $instruction->dispatch_family,
    child_block_name => $instruction->child_block_name,
    abstract_child_blocks => $instruction->abstract_child_blocks,
    abstract_child_blocks_index => undef,
    args_mode => $instruction->args_mode,
    args_payload => $instruction->args_payload,
    args_payload_index => undef,
    has_args => $instruction->has_args,
    directives_mode => $instruction->directives_mode,
    directives_payload => $instruction->directives_payload,
    directives_payload_index => undef,
    has_directives => $instruction->has_directives,
    runtime_directives_mode => $instruction->runtime_directives_mode,
    runtime_directives_payload => $instruction->runtime_directives_payload,
    has_runtime_directives => $instruction->has_runtime_directives,
    bound_slot => $instruction->bound_slot,
  );
}

sub _inflate_op {
  my ($struct) = @_;
  return GraphQL::Houtou::Runtime::VMOp->new(
    opcode => $struct->{opcode},
    opcode_code => $struct->{opcode_code} || 0,
    resolve_family => $struct->{resolve_family},
    resolve_code => $struct->{resolve_code} || 0,
    complete_family => $struct->{complete_family},
    complete_code => $struct->{complete_code} || 0,
    field_name => $struct->{field_name},
    result_name => $struct->{result_name},
    return_type_name => $struct->{return_type_name},
    dispatch_family => $struct->{dispatch_family},
    child_block_name => $struct->{child_block_name},
    abstract_child_blocks => $struct->{abstract_child_blocks} || {},
    abstract_child_blocks_index => $struct->{abstract_child_blocks_index},
    args_mode => $struct->{args_mode} || 'NONE',
    args_payload => $struct->{args_payload},
    args_payload_index => $struct->{args_payload_index},
    has_args => $struct->{has_args},
    directives_mode => $struct->{directives_mode} || 'NONE',
    directives_payload => $struct->{directives_payload},
    directives_payload_index => $struct->{directives_payload_index},
    has_directives => $struct->{has_directives},
    runtime_directives_mode => $struct->{runtime_directives_mode} || 'NONE',
    runtime_directives_payload => $struct->{runtime_directives_payload},
    has_runtime_directives => $struct->{has_runtime_directives},
  );
}

sub _inflate_native_block {
  my ($struct) = @_;
  if (ref($struct) eq 'ARRAY') {
    my ($name, $type_name, $family_code, $slots, $ops) = @$struct;
    return GraphQL::Houtou::Runtime::VMBlock->new(
      name => $name,
      type_name => $type_name,
      family => _family_from_code($family_code),
      ops => [ map { _inflate_native_op($_) } @{ $ops || [] } ],
    );
  }
  return GraphQL::Houtou::Runtime::VMBlock->new(
    name => $struct->{name},
    type_name => $struct->{type_name},
    family => $struct->{family} || 'OBJECT',
    ops => [ map { _inflate_native_op($_) } @{ $struct->{ops} || [] } ],
  );
}

sub _inflate_native_op {
  my ($struct) = @_;
  if (ref($struct) eq 'ARRAY') {
    my ($opcode_code, $resolve_code, $complete_code, $dispatch_family_code, $slot_index, $child_block_index, $abstract_child_block_indexes, $args_mode_code, $args_payload_index, $args_payload, $has_args, $directives_mode_code, $directives_payload_index, $directives_payload, $has_directives, $field_name, $result_name, $return_type_name, $runtime_directives_mode_code, $runtime_directives_payload, $has_runtime_directives) = @$struct;
    my $resolve_family = _resolve_family_from_code($resolve_code);
    my $complete_family = _complete_family_from_code($complete_code);
    my $op = GraphQL::Houtou::Runtime::VMOp->new(
      opcode => join(q(:), $resolve_family, $complete_family),
      opcode_code => $opcode_code || 0,
      resolve_family => $resolve_family,
      resolve_code => $resolve_code || 0,
      complete_family => $complete_family,
      complete_code => $complete_code || 0,
      dispatch_family => _dispatch_family_from_code($dispatch_family_code),
      field_name => $field_name,
      result_name => $result_name,
      return_type_name => $return_type_name,
      abstract_child_blocks_index => undef,
      args_mode => _args_mode_from_code($args_mode_code),
      args_payload => $args_payload,
      args_payload_index => $args_payload_index,
      has_args => $has_args,
      directives_mode => _directives_mode_from_code($directives_mode_code),
      directives_payload => $directives_payload,
      directives_payload_index => $directives_payload_index,
      has_directives => $has_directives,
      runtime_directives_mode => _directives_mode_from_code($runtime_directives_mode_code),
      runtime_directives_payload => $runtime_directives_payload,
      has_runtime_directives => $has_runtime_directives,
    );
    $op->set_native_slot_index($slot_index);
    $op->set_native_child_block_index($child_block_index);
    $op->set_native_abstract_child_block_indexes($abstract_child_block_indexes || {});
    return $op;
  }
  my $resolve_family = _resolve_family_from_code($struct->{resolve_code});
  my $complete_family = _complete_family_from_code($struct->{complete_code});
  my $op = GraphQL::Houtou::Runtime::VMOp->new(
    opcode => join(q(:), $resolve_family, $complete_family),
    opcode_code => $struct->{opcode_code} || 0,
    resolve_family => $resolve_family,
    resolve_code => $struct->{resolve_code} || 0,
    complete_family => $complete_family,
    complete_code => $struct->{complete_code} || 0,
    dispatch_family => $struct->{dispatch_family} || _dispatch_family_from_code($struct->{dispatch_family_code}),
    return_type_name => $struct->{return_type_name},
    args_mode => $struct->{args_mode} || 'NONE',
    args_payload => $struct->{args_payload},
    args_payload_index => $struct->{args_payload_index},
    has_args => $struct->{has_args},
    directives_mode => $struct->{directives_mode} || _directives_mode_from_code($struct->{directives_mode_code}),
    directives_payload => $struct->{directives_payload},
    directives_payload_index => $struct->{directives_payload_index},
    has_directives => $struct->{has_directives},
    runtime_directives_mode => $struct->{runtime_directives_mode} || _directives_mode_from_code($struct->{runtime_directives_mode_code}),
    runtime_directives_payload => $struct->{runtime_directives_payload},
    has_runtime_directives => $struct->{has_runtime_directives},
    abstract_child_blocks_index => $struct->{abstract_child_blocks_index},
  );
  $op->set_native_slot_index($struct->{slot_index});
  $op->set_native_child_block_index($struct->{child_block_index});
  $op->set_native_abstract_child_block_indexes($struct->{abstract_child_block_indexes} || {});
  return $op;
}

sub _family_from_code {
  my ($code) = @_;
  return 'OBJECT' if ($code || 0) == 2;
  return 'LIST' if ($code || 0) == 3;
  return 'ABSTRACT' if ($code || 0) == 4;
  return 'GENERIC';
}

sub _dispatch_family_from_code {
  my ($code) = @_;
  return 'RESOLVE_TYPE' if ($code || 0) == 2;
  return 'TAG' if ($code || 0) == 3;
  return 'POSSIBLE_TYPES' if ($code || 0) == 4;
  return 'DEFAULT';
}

sub _operation_type_from_code {
  my ($code) = @_;
  return 'mutation' if ($code || 0) == 2;
  return 'subscription' if ($code || 0) == 3;
  return 'query';
}

sub _args_mode_from_code {
  my ($code) = @_;
  return 'STATIC' if ($code || 0) == 1;
  return 'DYNAMIC' if ($code || 0) == 2;
  return 'NONE';
}

sub _directives_mode_from_code {
  my ($code) = @_;
  return 'STATIC' if ($code || 0) == 1;
  return 'DYNAMIC' if ($code || 0) == 2;
  return 'NONE';
}

sub _bind_vm_ops {
  my ($runtime_schema, $program) = @_;
  my %blocks = map { ($_->name => $_) } @{ $program->blocks || [] };
  if (my $root = $program->root_block) {
    $blocks{ $root->name } = $root;
  }

  for my $block (@{ $program->blocks || [] }, ($program->root_block || ())) {
    next if !$block;
    my $schema_block = $runtime_schema->block_by_type_name($block->type_name);
    my %slots = $schema_block
      ? map { ($_->field_name => $_) } @{ $schema_block->slots || [] }
      : ();

    for my $op (@{ $block->ops || [] }) {
      $op->set_bound_slot($op->bound_slot || $slots{ $op->field_name });
      $op->set_bound_slot($op->bound_slot || _bind_typename_slot($runtime_schema, $block, $op));
      $op->set_bound_child_block($op->child_block_name
        ? $blocks{ $op->child_block_name }
        : undef);
      $op->set_bound_abstract_child_blocks({
        map {
          my $child_name = $op->abstract_child_blocks->{$_};
          ($_ => ($child_name ? $blocks{$child_name} : undef))
        } keys %{ $op->abstract_child_blocks || {} }
      });
    }
  }

  return $program;
}

sub _bind_native_vm_ops {
  my ($runtime_schema, $program, $program_struct) = @_;
  my @block_structs = @{ $program_struct->{blocks_compact} || $program_struct->{blocks} || [] };
  my @blocks = @{ $program->blocks || [] };
  my @runtime_slots = @{ $runtime_schema->slot_catalog || [] };

  for my $block_index (0 .. $#blocks) {
    my $block = $blocks[$block_index] or next;
    my $block_struct = $block_structs[$block_index] || {};
    my @native_slots = ref($block_struct) eq 'ARRAY'
      ? @{ $block_struct->[3] || [] }
      : @{ $block_struct->{slots} || [] };

    for my $op (@{ $block->ops || [] }) {
      my $slot_struct = defined $op->native_slot_index
        ? $native_slots[ $op->native_slot_index ]
        : undef;
      my $schema_slot_index = ref($slot_struct) eq 'ARRAY'
        ? $slot_struct->[3]
        : ($slot_struct ? $slot_struct->{schema_slot_index} : undef);
      my $field_name = ref($slot_struct) eq 'ARRAY'
        ? $slot_struct->[0]
        : ($slot_struct ? $slot_struct->{field_name} : undef);
      my $result_name = ref($slot_struct) eq 'ARRAY'
        ? $slot_struct->[1]
        : ($slot_struct ? $slot_struct->{result_name} : undef);
      my $runtime_slot = defined $schema_slot_index
        ? $runtime_slots[ $schema_slot_index ]
        : undef;

      $op->set_bound_slot($runtime_slot) if $runtime_slot;
      $op->set_field_name($field_name) if defined $field_name;
      $op->set_result_name($result_name) if defined $result_name;
      $op->set_bound_slot($op->bound_slot || _bind_typename_slot($runtime_schema, $block, $op, $slot_struct));

      if (defined $op->native_child_block_index) {
        my $child_block = $blocks[ $op->native_child_block_index ];
        $op->set_bound_child_block($child_block);
        $op->set_child_block_name($child_block ? $child_block->name : undef);
      } else {
        $op->set_bound_child_block(undef);
        $op->set_child_block_name(undef);
      }

      my %abstract_children = map {
        my $idx = $op->native_abstract_child_block_indexes->{$_};
        ($_ => (defined $idx && $blocks[$idx] ? $blocks[$idx]->name : undef))
      } keys %{ $op->native_abstract_child_block_indexes || {} };
      $op->set_abstract_child_blocks(\%abstract_children);
      $op->set_bound_abstract_child_blocks({
        map {
          my $idx = $op->native_abstract_child_block_indexes->{$_};
          ($_ => (defined $idx ? $blocks[$idx] : undef))
        } keys %{ $op->native_abstract_child_block_indexes || {} }
      });
    }
  }

  return $program;
}

sub _bind_typename_slot {
  my ($runtime_schema, $block, $op, $slot_struct) = @_;
  return undef if ($op->field_name || q()) ne '__typename';
  my $return_type_name = ref($slot_struct) eq 'ARRAY'
    ? $slot_struct->[2]
    : ($slot_struct && $slot_struct->{return_type_name});
  my $return_type_kind_code = ref($slot_struct) eq 'ARRAY'
    ? $slot_struct->[7]
    : ($slot_struct && $slot_struct->{return_type_kind_code});

  return GraphQL::Houtou::Runtime::Slot->new(
    schema_slot_key => join(q(.), ($block->type_name || q()), '__typename'),
    field_name => '__typename',
    result_name => ($op->result_name || '__typename'),
    return_type_name => ($return_type_name || 'String'),
    return_type_kind_code => (defined $return_type_kind_code ? $return_type_kind_code : 1),
    resolver_shape => 'DEFAULT',
    resolver_mode => 'DEFAULT',
    completion_family => 'GENERIC',
    dispatch_family => 'GENERIC',
    has_args => 0,
    has_directives => (($op->has_directives || 0) ? 1 : 0),
  );
}

sub _resolve_family_from_code {
  my ($code) = @_;
  return 'RESOLVE_EXPLICIT' if ($code || 0) == 2;
  return 'RESOLVE_DEFAULT';
}

sub _complete_family_from_code {
  my ($code) = @_;
  return 'COMPLETE_OBJECT' if ($code || 0) == 2;
  return 'COMPLETE_LIST' if ($code || 0) == 3;
  return 'COMPLETE_ABSTRACT' if ($code || 0) == 4;
  return 'COMPLETE_GENERIC';
}

1;
