package GraphQL::Houtou::Runtime::OperationCompiler;

use 5.014;
use strict;
use warnings;
use Scalar::Util qw(refaddr);
use JSON::MaybeXS qw(is_bool);

use GraphQL::Houtou ();
use GraphQL::Houtou::Error ();
use GraphQL::Houtou::Runtime::Slot ();
use GraphQL::Houtou::Runtime::VMBlock ();
use GraphQL::Houtou::Runtime::VMOp ();
use GraphQL::Houtou::Runtime::VMProgram ();

my %RESOLVE_CODE = (
  RESOLVE_DEFAULT  => 1,
  RESOLVE_EXPLICIT => 2,
);


my %COMPLETE_CODE = (
  COMPLETE_GENERIC  => 1,
  COMPLETE_OBJECT   => 2,
  COMPLETE_LIST     => 3,
  COMPLETE_ABSTRACT => 4,
);

sub compile_operation {
  my ($class, $runtime_schema, $document, %opts) = @_;
  my $ast = ref($document) ? $document : GraphQL::Houtou::parse($document);
  my ($operation) = grep { ($_->{kind} || '') eq 'operation' } @{ $ast || [] };
  die "No operation found for runtime compiler.\n" if !$operation;
  my %fragments = map { (($_->{name} || '') => $_) }
    grep { ($_->{kind} || '') eq 'fragment' } @{ $ast || [] };

  my $operation_type = $operation->{operation} || $operation->{operationType} || 'query';
  _assert_supported_operation($operation_type);
  my $schema_block = $runtime_schema->root_block($operation_type)
    or die "No root block for operation type '$operation_type'.\n";

  my %state = (
    runtime_schema => $runtime_schema,
    block_index => 0,
    blocks => [],
    fragments => \%fragments,
  );

  my $root_block = _lower_selection_block(
    \%state,
    $schema_block->root_type_name,
    $schema_block,
    $operation->{selections} || [],
    uc($operation_type),
  );

  my $program = GraphQL::Houtou::Runtime::VMProgram->new(
    operation_type => $operation_type,
    operation_name => $operation->{name},
    variable_defs => _lower_variable_defs($operation->{variables}),
    blocks => $state{blocks},
    root_block => $root_block,
  );

  _bind_instruction_blocks($program);
  return $program;
}

sub compile_operation_native_compact {
  my ($class, $runtime_schema, $document, %opts) = @_;
  my $ast = ref($document) ? $document : GraphQL::Houtou::parse($document);
  my ($operation) = grep { ($_->{kind} || '') eq 'operation' } @{ $ast || [] };
  die "No operation found for runtime compiler.\n" if !$operation;
  my %fragments = map { (($_->{name} || '') => $_) }
    grep { ($_->{kind} || '') eq 'fragment' } @{ $ast || [] };

  my $operation_type = $operation->{operation} || $operation->{operationType} || 'query';
  _assert_supported_operation($operation_type);
  my $schema_block = $runtime_schema->root_block($operation_type)
    or die "No root block for operation type '$operation_type'.\n";

  my %state = (
    runtime_schema => $runtime_schema,
    block_index => 0,
    blocks_compact => [],
    args_payloads_compact => [],
    directives_payloads_compact => [],
    args_payload_index => {},
    directives_payload_index => {},
    fragments => \%fragments,
  );

  my $root_block_index = _lower_selection_block_compact(
    \%state,
    $schema_block->root_type_name,
    $schema_block,
    $operation->{selections} || [],
    uc($operation_type),
  );

  return {
    version => 1,
    operation_type_code => _operation_type_code($operation_type),
    operation_name => $operation->{name},
    variable_defs => _lower_variable_defs($operation->{variables}),
    args_payloads_compact => $state{args_payloads_compact},
    directives_payloads_compact => $state{directives_payloads_compact},
    root_block_index => $root_block_index,
    blocks_compact => $state{blocks_compact},
  };
}

sub _assert_supported_operation {
  my ($operation_type) = @_;
  die GraphQL::Houtou::Error->new(
    message => 'Subscription execution is not supported.',
    extensions => { code => 'SUBSCRIPTION_NOT_SUPPORTED' },
  ) if $operation_type eq 'subscription';
  return;
}

sub assert_supported_operation_descriptor {
  my ($descriptor) = @_;
  return if ref($descriptor) ne 'HASH';
  _assert_supported_operation('subscription')
    if ($descriptor->{operation_type} || q()) eq 'subscription'
      || ($descriptor->{operation_type_code} // q()) eq '3';
  return;
}

sub inflate_operation {
  my ($class, $runtime_schema, $struct) = @_;
  my @blocks = map { _inflate_execution_block($_) } @{ $struct->{blocks} || [] };
  my %by_name = map { ($_->name => $_) } @blocks;
  my $root_block = defined $struct->{root_block} ? $by_name{ $struct->{root_block} } : undef;
  _bind_instructions_to_schema_slots($runtime_schema, \@blocks);
  my $program = GraphQL::Houtou::Runtime::VMProgram->new(
    version => $struct->{version} || 1,
    operation_type => $struct->{operation_type} || 'query',
    operation_name => $struct->{operation_name},
    variable_defs => _clone_argument_value($struct->{variable_defs} || {}),
    blocks => \@blocks,
    root_block => $root_block,
  );
  _bind_instruction_blocks($program);
  return $program;
}

sub _lower_selection_block {
  my ($state, $type_name, $schema_block, $selections, $base_name) = @_;
  my %schema_slots = map { ($_->field_name => $_) } @{ $schema_block->slots || [] };
  my @ops;
  my $field_selections = _normalize_selections($state, $selections, $type_name);

  for my $selection (@{ $field_selections || [] }) {
    next if !$selection || ($selection->{kind} || '') ne 'field';
    my $field_name = $selection->{name};
    if (($field_name || q()) eq '__typename') {
      push @ops, _build_typename_instruction($state, $type_name, $selection);
      next;
    }
    my $slot = $schema_slots{$field_name} or next;
    my $child_block;
    my $abstract_child_blocks;
    my ($args_mode, $args_payload) = _lower_arguments($selection->{arguments});
    my ($directives_mode, $directives_payload) = _lower_directives($selection->{_runtime_guards});
    my ($runtime_directives_mode, $runtime_directives_payload) =
      _lower_directives($selection->{_runtime_directives});

    if ($selection->{selections} && @{ $selection->{selections} }) {
      my $child_type_name = $slot->return_type_name;
      if (($slot->completion_family || '') eq 'ABSTRACT') {
        $abstract_child_blocks = _lower_abstract_child_blocks(
          $state,
          $child_type_name,
          $selection->{selections},
          $base_name . q(.) . $field_name,
        );
      }
      elsif (my $child_schema_block = $state->{runtime_schema}->block_by_type_name($child_type_name)) {
        $child_block = _lower_selection_block(
          $state,
          $child_type_name,
          $child_schema_block,
          $selection->{selections},
          $base_name . q(.) . $field_name,
        );
      }
      elsif (@{ $state->{runtime_schema}->runtime_cache->{possible_types}{$child_type_name} || [] }) {
        # A list of an interface/union: the inner type has no object block
        # of its own, so lower one member block per possible type and let
        # the runtime pick per item.
        $abstract_child_blocks = _lower_abstract_child_blocks(
          $state,
          $child_type_name,
          $selection->{selections},
          $base_name . q(.) . $field_name,
        );
      }
    }

    my $resolve_family = _resolve_op_for_slot($slot);
    my $complete_family = _complete_op_for_slot($slot);
    push @ops, GraphQL::Houtou::Runtime::VMOp->new(
      opcode => join(q(:), $resolve_family, $complete_family),
      opcode_code => (($RESOLVE_CODE{$resolve_family} || 0) * 16) + ($COMPLETE_CODE{$complete_family} || 0),
      field_name => $field_name,
      result_name => ($selection->{alias} || $field_name),
      return_type_name => $slot->return_type_name,
      resolve_family => $resolve_family,
      resolve_code => $RESOLVE_CODE{$resolve_family} || 0,
      complete_family => $complete_family,
      complete_code => $COMPLETE_CODE{$complete_family} || 0,
      dispatch_family => $slot->dispatch_family,
      has_args => $slot->has_args,
      args_mode => $args_mode,
      args_payload => $args_payload,
      has_directives => (($directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
      directives_mode => $directives_mode,
      directives_payload => $directives_payload,
      has_runtime_directives => (($runtime_directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
      runtime_directives_mode => $runtime_directives_mode,
      runtime_directives_payload => $runtime_directives_payload,
      child_block_name => $child_block ? $child_block->name : undef,
      abstract_child_blocks => $abstract_child_blocks,
      abstract_child_blocks_index => undef,
      bound_slot => $slot,
    );
  }

  my $block = GraphQL::Houtou::Runtime::VMBlock->new(
    name => _next_block_name($state, $base_name),
    type_name => $type_name,
    family => 'OBJECT',
    ops => \@ops,
  );
  push @{ $state->{blocks} }, $block;
  return $block;
}

sub _lower_selection_block_compact {
  my ($state, $type_name, $schema_block, $selections, $base_name) = @_;
  my %schema_slots = map { ($_->field_name => $_) } @{ $schema_block->slots || [] };
  my @ops;
  my @slot_table;
  my %slot_index;
  my $field_selections = _normalize_selections($state, $selections, $type_name);

  for my $selection (@{ $field_selections || [] }) {
    next if !$selection || ($selection->{kind} || '') ne 'field';
    my $field_name = $selection->{name};

    if (($field_name || q()) eq '__typename') {
      my ($directives_mode, $directives_payload) = _lower_directives($selection->{_runtime_guards});
      my ($runtime_directives_mode, $runtime_directives_payload) =
        _lower_directives($selection->{_runtime_directives});
      my $directives_payload_index = _intern_compact_payload(
        $state->{directives_payloads_compact},
        $state->{directives_payload_index},
        $directives_payload,
      );
      my $result_name = ($selection->{alias} || '__typename');
      my $slot = _lookup_typename_slot($state->{runtime_schema}, $type_name, $result_name, $directives_mode);
      my $slot_compact_index = _intern_slot_compact(\@slot_table, \%slot_index, $slot, $result_name);
      push @ops, _build_compact_op(
        field_name => '__typename',
        result_name => $result_name,
        return_type_name => 'String',
        resolve_family => 'RESOLVE_DEFAULT',
        complete_family => 'COMPLETE_GENERIC',
        dispatch_family => 'DEFAULT',
        slot_index => $slot_compact_index,
        args_mode => 'NONE',
        args_payload_index => undef,
        args_payload => undef,
        has_args => 0,
        directives_mode => $directives_mode,
        directives_payload_index => $directives_payload_index,
        directives_payload => defined $directives_payload_index ? undef : $directives_payload,
        has_directives => (($directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
        runtime_directives_mode => $runtime_directives_mode,
        runtime_directives_payload => $runtime_directives_payload,
        has_runtime_directives => (($runtime_directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
        child_block_index => undef,
        abstract_child_block_indexes => {},
      );
      next;
    }

    my $slot = $schema_slots{$field_name} or next;
    my $child_block_index;
    my $abstract_child_block_indexes = {};
    my ($args_mode, $args_payload) = _lower_arguments($selection->{arguments});
    my ($directives_mode, $directives_payload) = _lower_directives($selection->{_runtime_guards});
    my ($runtime_directives_mode, $runtime_directives_payload) =
      _lower_directives($selection->{_runtime_directives});
    my $args_payload_index = _intern_compact_payload(
      $state->{args_payloads_compact},
      $state->{args_payload_index},
      $args_payload,
    );
    my $directives_payload_index = _intern_compact_payload(
      $state->{directives_payloads_compact},
      $state->{directives_payload_index},
      $directives_payload,
    );

    if ($selection->{selections} && @{ $selection->{selections} }) {
      my $child_type_name = $slot->return_type_name;
      if (($slot->completion_family || '') eq 'ABSTRACT') {
        $abstract_child_block_indexes = _lower_abstract_child_blocks_compact(
          $state,
          $child_type_name,
          $selection->{selections},
          $base_name . q(.) . $field_name,
        );
      }
      elsif (my $child_schema_block = $state->{runtime_schema}->block_by_type_name($child_type_name)) {
        $child_block_index = _lower_selection_block_compact(
          $state,
          $child_type_name,
          $child_schema_block,
          $selection->{selections},
          $base_name . q(.) . $field_name,
        );
      }
      elsif (@{ $state->{runtime_schema}->runtime_cache->{possible_types}{$child_type_name} || [] }) {
        # A list of an interface/union: the inner type has no object block
        # of its own, so lower one member block per possible type and let
        # the runtime pick per item.
        $abstract_child_block_indexes = _lower_abstract_child_blocks_compact(
          $state,
          $child_type_name,
          $selection->{selections},
          $base_name . q(.) . $field_name,
        );
      }
    }

    my $resolve_family = _resolve_op_for_slot($slot);
    my $complete_family = _complete_op_for_slot($slot);
    my $result_name = ($selection->{alias} || $field_name);
    my $slot_compact_index = _intern_slot_compact(\@slot_table, \%slot_index, $slot, $result_name);

    push @ops, _build_compact_op(
      field_name => $field_name,
      result_name => $result_name,
      return_type_name => $slot->return_type_name,
      resolve_family => $resolve_family,
      complete_family => $complete_family,
      dispatch_family => $slot->dispatch_family,
      slot_index => $slot_compact_index,
      args_mode => $args_mode,
      args_payload_index => $args_payload_index,
      args_payload => defined $args_payload_index ? undef : $args_payload,
      has_args => $slot->has_args,
      directives_mode => $directives_mode,
      directives_payload_index => $directives_payload_index,
      directives_payload => defined $directives_payload_index ? undef : $directives_payload,
      has_directives => (($directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
      runtime_directives_mode => $runtime_directives_mode,
      runtime_directives_payload => $runtime_directives_payload,
      has_runtime_directives => (($runtime_directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
      child_block_index => $child_block_index,
      abstract_child_block_indexes => $abstract_child_block_indexes,
    );
  }

  my $name = _next_block_name($state, $base_name);
  my $block = [
    $name,
    $type_name,
    2,
    \@slot_table,
    \@ops,
  ];
  push @{ $state->{blocks_compact} }, $block;
  return $#{$state->{blocks_compact}};
}

sub _next_block_name {
  my ($state, $base_name) = @_;
  my $name = sprintf('%s#%d', $base_name, $state->{block_index}++);
  return $name;
}

sub _inflate_execution_block {
  my ($struct) = @_;
  return GraphQL::Houtou::Runtime::VMBlock->new(
    name => $struct->{name},
    type_name => $struct->{type_name},
    family => $struct->{family} || 'OBJECT',
    ops => [ map { _inflate_instruction($_) } @{ $struct->{ops} || $struct->{instructions} || [] } ],
  );
}

sub _inflate_instruction {
  my ($struct) = @_;
  my $resolve_family = $struct->{resolve_family} || $struct->{resolve_op} || 'RESOLVE_DEFAULT';
  my $complete_family = $struct->{complete_family} || $struct->{complete_op} || 'COMPLETE_GENERIC';
  return GraphQL::Houtou::Runtime::VMOp->new(
    opcode => $struct->{opcode} || join(q(:), $resolve_family, $complete_family),
    opcode_code => $struct->{opcode_code} || (($RESOLVE_CODE{$resolve_family} || 0) * 16) + ($COMPLETE_CODE{$complete_family} || 0),
    field_name => $struct->{field_name},
    result_name => $struct->{result_name},
    return_type_name => $struct->{return_type_name},
    resolve_family => $resolve_family,
    resolve_code => $struct->{resolve_code} || $RESOLVE_CODE{$resolve_family} || 0,
    complete_family => $complete_family,
    complete_code => $struct->{complete_code} || $COMPLETE_CODE{$complete_family} || 0,
    dispatch_family => $struct->{dispatch_family},
    has_args => $struct->{has_args},
    args_mode => $struct->{args_mode} || 'NONE',
    args_payload => _clone_argument_value($struct->{args_payload}),
    has_directives => $struct->{has_directives},
    directives_mode => $struct->{directives_mode} || 'NONE',
    directives_payload => _clone_argument_value($struct->{directives_payload}),
    has_runtime_directives => $struct->{has_runtime_directives},
    runtime_directives_mode => $struct->{runtime_directives_mode} || 'NONE',
    runtime_directives_payload => _clone_argument_value($struct->{runtime_directives_payload}),
    child_block_name => $struct->{child_block_name},
    abstract_child_blocks => _clone_argument_value($struct->{abstract_child_blocks} || {}),
    abstract_child_blocks_index => $struct->{abstract_child_blocks_index},
  );
}

sub _bind_instructions_to_schema_slots {
  my ($runtime_schema, $blocks) = @_;

  for my $block (@{ $blocks || [] }) {
    my $schema_block = $runtime_schema->block_by_type_name($block->type_name) or next;
    my %slots = map { ($_->field_name => $_) } @{ $schema_block->slots || [] };
    for my $op (@{ $block->ops || [] }) {
      $op->set_bound_slot($slots{ $op->field_name });
    }
  }

  return $blocks;
}

sub _bind_instruction_blocks {
  my ($program) = @_;
  my %by_name = map { ($_->name => $_) } @{ $program->blocks || [] };
  if (my $root = $program->root_block) {
    $by_name{ $root->name } = $root;
  }

  for my $block (@{ $program->blocks || [] }, ($program->root_block || ())) {
    next if !$block;
    for my $op (@{ $block->ops || [] }) {
      $op->set_bound_child_block($op->child_block_name
        ? $by_name{ $op->child_block_name }
        : undef);
      $op->set_bound_abstract_child_blocks({
        map {
          my $child_name = $op->abstract_child_blocks->{$_};
          ($_ => ($child_name ? $by_name{$child_name} : undef))
        } keys %{ $op->abstract_child_blocks || {} }
      });
    }
  }

  return $program;
}

sub _lower_abstract_child_blocks {
  my ($state, $abstract_type_name, $selections, $base_name) = @_;
  my $possible_types = $state->{runtime_schema}->runtime_cache->{possible_types}{$abstract_type_name} || [];
  my %blocks;

  for my $type (@$possible_types) {
    next if !$type || !$type->isa('GraphQL::Houtou::Type::Object');
    my $schema_block = $state->{runtime_schema}->block_by_type_name($type->name) or next;
    my $block = _lower_selection_block(
      $state,
      $type->name,
      $schema_block,
      $selections,
      $base_name . q(.) . $type->name,
    );
    $blocks{ $type->name } = $block->name if $block;
  }

  return \%blocks;
}

sub _lower_abstract_child_blocks_compact {
  my ($state, $abstract_type_name, $selections, $base_name) = @_;
  my $possible_types = $state->{runtime_schema}->runtime_cache->{possible_types}{$abstract_type_name} || [];
  my %blocks;

  for my $type (@$possible_types) {
    next if !$type || !$type->isa('GraphQL::Houtou::Type::Object');
    my $schema_block = $state->{runtime_schema}->block_by_type_name($type->name) or next;
    my $block_index = _lower_selection_block_compact(
      $state,
      $type->name,
      $schema_block,
      $selections,
      $base_name . q(.) . $type->name,
    );
    $blocks{ $type->name } = $block_index if defined $block_index;
  }

  return \%blocks;
}

sub _intern_slot_compact {
  my ($slot_table, $slot_index, $slot, $result_name) = @_;
  my $id = join("\x1E", refaddr($slot), ($result_name // q()));
  return $slot_index->{$id} if exists $slot_index->{$id};
  my $compact = $slot->to_native_compact_struct;
  $compact->[1] = ($result_name // $compact->[1]);
  my $index = @$slot_table;
  push @$slot_table, $compact;
  $slot_index->{$id} = $index;
  return $index;
}

sub _build_compact_op {
  my (%args) = @_;
  my $resolve_code = $RESOLVE_CODE{ $args{resolve_family} || 'RESOLVE_DEFAULT' } || 0;
  my $complete_code = $COMPLETE_CODE{ $args{complete_family} || 'COMPLETE_GENERIC' } || 0;
  return [
    ($resolve_code * 16) + $complete_code,
    $resolve_code,
    $complete_code,
    _dispatch_family_code($args{dispatch_family}),
    $args{slot_index},
    $args{child_block_index},
    $args{abstract_child_block_indexes} || {},
    _args_mode_code($args{args_mode}),
    $args{args_payload_index},
    $args{args_payload},
    $args{has_args} ? 1 : 0,
    _directives_mode_code($args{directives_mode}),
    $args{directives_payload_index},
    $args{directives_payload},
    $args{has_directives} ? 1 : 0,
    $args{field_name},
    $args{result_name},
    $args{return_type_name},
    _directives_mode_code($args{runtime_directives_mode}),
    $args{runtime_directives_payload},
    $args{has_runtime_directives} ? 1 : 0,
  ];
}

sub _dispatch_family_code {
  my ($family) = @_;
  return 2 if ($family || q()) eq 'RESOLVE_TYPE';
  return 3 if ($family || q()) eq 'TAG';
  return 4 if ($family || q()) eq 'POSSIBLE_TYPES';
  return 1;
}

sub _args_mode_code {
  my ($mode) = @_;
  return 1 if ($mode || q()) eq 'STATIC';
  return 2 if ($mode || q()) eq 'DYNAMIC';
  return 0;
}

sub _directives_mode_code {
  my ($mode) = @_;
  return 1 if ($mode || q()) eq 'STATIC';
  return 2 if ($mode || q()) eq 'DYNAMIC';
  return 0;
}

sub _operation_type_code {
  my ($type) = @_;
  return 2 if ($type || q()) eq 'mutation';
  return 3 if ($type || q()) eq 'subscription';
  return 1;
}

sub _normalize_selections {
  my ($state, $selections, $type_name, $visited, $inherited_guards, $inherited_runtime_directives) = @_;
  $visited ||= {};
  $inherited_guards ||= [];
  $inherited_runtime_directives ||= [];
  my @normalized;

  for my $selection (@{ $selections || [] }) {
    next if !$selection;
    my $kind = $selection->{kind} || '';
    my ($allowed, $dynamic_guards, $runtime_directives) = _partition_runtime_guards($selection->{directives});
    next if !$allowed;
    my $combined_guards = [ @$inherited_guards, @$dynamic_guards ];
    my $combined_runtime_directives = [ @$inherited_runtime_directives, @$runtime_directives ];
    if ($kind eq 'field') {
      my %copy = %$selection;
      $copy{_runtime_guards} = $combined_guards if @$combined_guards;
      $copy{_runtime_directives} = $combined_runtime_directives if @$combined_runtime_directives;
      push @normalized, \%copy;
      next;
    }
    if ($kind eq 'inline_fragment') {
      my $on = $selection->{on};
      next if defined($on) && defined($type_name) && $on ne $type_name;
      push @normalized, @{ _normalize_selections(
        $state,
        $selection->{selections} || [],
        $type_name,
        $visited,
        $combined_guards,
        $combined_runtime_directives,
      ) };
      next;
    }
    if ($kind eq 'fragment_spread') {
      my $name = $selection->{name} || '';
      next if !$name || $visited->{$name};
      my $fragment = $state->{fragments}{$name} or next;
      my $on = $fragment->{on};
      next if defined($on) && defined($type_name) && $on ne $type_name;
      local $visited->{$name} = 1;
      push @normalized, @{ _normalize_selections(
        $state,
        $fragment->{selections} || [],
        $type_name,
        $visited,
        $combined_guards,
        $combined_runtime_directives,
      ) };
      next;
    }
  }

  return \@normalized;
}

sub _build_typename_instruction {
  my ($state, $type_name, $selection) = @_;
  my ($directives_mode, $directives_payload) = _lower_directives($selection->{_runtime_guards});
  my ($runtime_directives_mode, $runtime_directives_payload) =
    _lower_directives($selection->{_runtime_directives});
  my $result_name = ($selection->{alias} || '__typename');
  my $slot = _lookup_typename_slot($state->{runtime_schema}, $type_name, $result_name, $directives_mode);
  my $resolve_family = 'RESOLVE_DEFAULT';
  my $complete_family = 'COMPLETE_GENERIC';
  return GraphQL::Houtou::Runtime::VMOp->new(
    opcode => 'RESOLVE_DEFAULT:COMPLETE_GENERIC',
    opcode_code => (($RESOLVE_CODE{$resolve_family} || 0) * 16) + ($COMPLETE_CODE{$complete_family} || 0),
    field_name => '__typename',
    result_name => $result_name,
    return_type_name => 'String',
    resolve_family => $resolve_family,
    resolve_code => $RESOLVE_CODE{$resolve_family} || 0,
    complete_family => $complete_family,
    complete_code => $COMPLETE_CODE{$complete_family} || 0,
    dispatch_family => 'DEFAULT',
    has_args => 0,
    args_mode => 'NONE',
    args_payload => undef,
    has_directives => (($directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
    directives_mode => $directives_mode,
    directives_payload => $directives_payload,
    has_runtime_directives => (($runtime_directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
    runtime_directives_mode => $runtime_directives_mode,
    runtime_directives_payload => $runtime_directives_payload,
    bound_slot => $slot,
  );
}

sub _lookup_typename_slot {
  my ($runtime_schema, $type_name, $result_name, $directives_mode) = @_;
  my $schema_block = $runtime_schema->block_by_type_name($type_name);
  if ($schema_block) {
    for my $slot (@{ $schema_block->slots || [] }) {
      next if ($slot->field_name || q()) ne '__typename';
      return GraphQL::Houtou::Runtime::Slot->new(
        schema_slot_key => $slot->schema_slot_key,
        schema_slot_index => $slot->schema_slot_index,
        field_name => '__typename',
        result_name => $result_name,
        return_type_name => $slot->return_type_name,
        return_type_kind_code => $slot->return_type_kind_code,
        resolver_shape => $slot->resolver_shape,
        resolver_mode => $slot->resolver_mode,
        completion_family => $slot->completion_family,
        dispatch_family => $slot->dispatch_family,
        has_args => 0,
        has_directives => (($directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
      );
    }
  }
  return GraphQL::Houtou::Runtime::Slot->new(
    schema_slot_key => join(q(.), ($type_name || q()), '__typename'),
    field_name => '__typename',
    result_name => $result_name,
    return_type_name => 'String',
    return_type_kind_code => 1,
    resolver_shape => 'DEFAULT',
    resolver_mode => 'DEFAULT',
    completion_family => 'GENERIC',
    dispatch_family => 'GENERIC',
    has_args => 0,
    has_directives => (($directives_mode || 'NONE') ne 'NONE') ? 1 : 0,
  );
}

sub _resolve_op_for_slot {
  my ($slot) = @_;
  return 'RESOLVE_EXPLICIT' if ($slot->resolver_shape || '') eq 'EXPLICIT';
  return 'RESOLVE_DEFAULT';
}

sub _lower_variable_defs {
  my ($variables) = @_;
  return {} if !$variables || !keys %$variables;
  my %defs;
  for my $name (sort keys %$variables) {
    my $def = $variables->{$name} || {};
    $defs{$name} = {
      type => { type => _clone_argument_value($def->{type}) },
      has_default => exists $def->{default_value} ? 1 : 0,
      default_value => exists $def->{default_value}
        ? _materialize_static_value($def->{default_value})
        : undef,
    };
  }
  return \%defs;
}

sub _lower_directives {
  my ($directives) = @_;
  return ('NONE', undef) if !$directives || !@$directives;
  return ('STATIC', _materialize_static_value($directives))
    if !_contains_variable_refs($directives);
  return ('DYNAMIC', _clone_argument_value($directives));
}

sub _partition_runtime_guards {
  my ($directives) = @_;
  return (1, [], []) if !$directives || !@$directives;
  my @dynamic;
  my @runtime_directives;
  for my $directive (@$directives) {
    next if !$directive;
    my $name = $directive->{name} || '';
    if ($name ne 'include' && $name ne 'skip') {
      push @runtime_directives, {
        name => $name,
        arguments => _clone_argument_value($directive->{arguments} || {}),
      };
      next;
    }
    my $arguments = $directive->{arguments} || {};
    my $if_value = $arguments->{if};
    if (!_contains_variable_refs($if_value)) {
      my $bool = _directive_truthy(_materialize_static_value($if_value));
      return (0, [], []) if $name eq 'skip' && $bool;
      return (0, [], []) if $name eq 'include' && !$bool;
      next;
    }
    push @dynamic, {
      name => $name,
      arguments => _clone_argument_value($arguments),
    };
  }
  return (1, \@dynamic, \@runtime_directives);
}

sub _directive_truthy {
  my ($value) = @_;
  return $value ? 1 : 0;
}

sub _lower_arguments {
  my ($arguments) = @_;
  return ('NONE', undef) if !$arguments || !keys %$arguments;
  return ('STATIC', _materialize_static_value($arguments))
    if !_contains_variable_refs($arguments);
  return ('DYNAMIC', _clone_argument_value($arguments));
}

sub _contains_variable_refs {
  my ($value) = @_;
  my $ref = ref($value);
  return 0 if !$ref;
  return 1 if $ref eq 'SCALAR';
  # A REF (\\'NAME') is the parser's enum-literal marker, not a variable:
  # recursing into it would misread the inner scalar ref as a variable and
  # send the argument down the dynamic path, where 'NAME' gets looked up
  # as a (missing) variable and the argument silently becomes undef.
  return 0 if $ref eq 'REF';
  if ($ref eq 'ARRAY') {
    for my $item (@$value) {
      return 1 if _contains_variable_refs($item);
    }
    return 0;
  }
  if ($ref eq 'HASH') {
    for my $key (keys %$value) {
      return 1 if _contains_variable_refs($value->{$key});
    }
    return 0;
  }
  return 0;
}

sub _materialize_static_value {
  my ($value) = @_;
  my $ref = ref($value);
  return $value if !$ref;
  return $value ? 1 : 0 if is_bool($value);
  return $$$value if $ref eq 'REF';
  return [ map { _materialize_static_value($_) } @$value ] if $ref eq 'ARRAY';
  return { map { $_ => _materialize_static_value($value->{$_}) } keys %$value } if $ref eq 'HASH';
  die "Unsupported static argument value ref '$ref' in runtime compiler.\n"
    if $ref eq 'SCALAR';
  return $value;
}

sub _clone_argument_value {
  my ($value) = @_;
  my $ref = ref($value);
  return $value if !$ref;
  return $value if $ref eq 'REF' || $ref eq 'SCALAR';
  return [ map { _clone_argument_value($_) } @$value ] if $ref eq 'ARRAY';
  return { map { $_ => _clone_argument_value($value->{$_}) } keys %$value } if $ref eq 'HASH';
  return $value;
}

sub _intern_compact_payload {
  my ($payloads, $index, $payload) = @_;
  return undef if !_payload_present($payload);
  my $key = _compact_payload_key($payload);
  return $index->{$key} if exists $index->{$key};
  my $slot = @$payloads;
  push @$payloads, _clone_argument_value($payload);
  $index->{$key} = $slot;
  return $slot;
}

sub _payload_present {
  my ($value) = @_;
  return 0 if !defined $value;
  my $ref = ref($value);
  return 1 if !$ref;
  return scalar(@$value) ? 1 : 0 if $ref eq 'ARRAY';
  return scalar(keys %$value) ? 1 : 0 if $ref eq 'HASH';
  return 1;
}

sub _compact_payload_key {
  my ($value) = @_;
  my $ref = ref($value);
  return '!undef' if !defined $value;
  return "S:$value" if !$ref;
  return "R:${$value}" if $ref eq 'REF' || $ref eq 'SCALAR';
  return 'A:[' . join(',', map { _compact_payload_key($_) } @$value) . ']' if $ref eq 'ARRAY';
  return 'H:{' . join(',', map { $_ . '=>' . _compact_payload_key($value->{$_}) } sort keys %$value) . '}' if $ref eq 'HASH';
  return "$ref:$value";
}

sub _complete_op_for_slot {
  my ($slot) = @_;
  my $family = $slot->completion_family || 'GENERIC';
  return 'COMPLETE_OBJECT' if $family eq 'OBJECT';
  return 'COMPLETE_LIST' if $family eq 'LIST';
  return 'COMPLETE_ABSTRACT' if $family eq 'ABSTRACT';
  return 'COMPLETE_GENERIC';
}

1;
