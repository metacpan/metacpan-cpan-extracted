package GraphQL::Houtou::Runtime::SchemaGraph;

use 5.014;
use strict;
use warnings;

use GraphQL::Houtou ();
use GraphQL::Houtou::Runtime::DirectiveRuntime qw(
  slot_needs_runtime_wrapper
  wrap_field_resolver
);
use GraphQL::Houtou::Runtime::OperationCompiler ();
use GraphQL::Houtou::Runtime::SchemaBlock ();
use GraphQL::Houtou::Runtime::Slot ();

sub compile_schema {
  my ($class, $schema, %opts) = @_;
  my $runtime_cache = $schema->prepare_runtime;

  my $type_index = _build_type_index($runtime_cache->{name2type} || {});
  my $dispatch_index = _build_dispatch_index($runtime_cache);
  my ($blocks, $root_blocks, $root_types) = _build_blocks($schema, $runtime_cache);
  my $slot_catalog = _build_slot_catalog($blocks);

  return $class->new(
    version => 1,
    schema => $schema,
    runtime_cache => $runtime_cache,
    type_index => $type_index,
    dispatch_index => $dispatch_index,
    root_types => $root_types,
    slot_catalog => $slot_catalog,
    blocks => $blocks,
    root_blocks => $root_blocks,
  );
}

sub inflate_schema {
  my ($class, $schema, $struct) = @_;
  my $runtime_cache = $schema->prepare_runtime;
  my ($blocks, $root_blocks) = _inflate_blocks($struct);
  my $slot_catalog = [ map { _inflate_slot($_) } @{ $struct->{slot_catalog} || [] } ];
  _apply_slot_catalog_to_blocks($blocks, $slot_catalog) if @$slot_catalog;

  return $class->new(
    version => $struct->{version} || 1,
    schema => $schema,
    runtime_cache => $runtime_cache,
    type_index => $struct->{type_index} || {},
    dispatch_index => $struct->{dispatch_index} || {},
    root_types => $struct->{root_types} || {},
    slot_catalog => $slot_catalog,
    blocks => $blocks,
    root_blocks => $root_blocks,
  );
}

sub new {
  my ($class, %args) = @_;
  return bless {
    version => $args{version} || 1,
    schema => $args{schema},
    runtime_cache => $args{runtime_cache} || {},
    type_index => $args{type_index} || {},
    dispatch_index => $args{dispatch_index} || {},
    root_types => $args{root_types} || {},
    slot_catalog => $args{slot_catalog} || [],
    blocks => $args{blocks} || [],
    root_blocks => $args{root_blocks} || {},
  }, $class;
}

sub version { return $_[0]{version} }
sub schema { return $_[0]{schema} }
sub runtime_cache { return $_[0]{runtime_cache} }
sub type_index { return $_[0]{type_index} }
sub dispatch_index { return $_[0]{dispatch_index} }
sub root_types { return $_[0]{root_types} }
sub slot_catalog { return $_[0]{slot_catalog} }
sub blocks { return $_[0]{blocks} }
sub root_blocks { return $_[0]{root_blocks} }

sub slot_by_index {
  my ($self, $index) = @_;
  return if !defined $index;
  return $self->{slot_catalog}[$index];
}

sub root_block {
  my ($self, $name) = @_;
  return $self->{root_blocks}{$name};
}

sub block_by_type_name {
  my ($self, $type_name) = @_;
  return if !defined $type_name;
  for my $block (@{ $self->{blocks} || [] }) {
    next if !defined $block->root_type_name;
    return $block if $block->root_type_name eq $type_name;
  }
  return;
}

sub compile_program {
  my ($self, $document, %opts) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::load_native_program_xs(
    $self->_compile_native_program_descriptor($document, %opts),
  );
}

sub compile_program_descriptor {
  my ($self, $document, %opts) = @_;
  return $self->_compile_native_program_descriptor($document, %opts);
}

sub inflate_program {
  my ($self, $descriptor) = @_;
  GraphQL::Houtou::Runtime::OperationCompiler::assert_supported_operation_descriptor(
    $descriptor,
  );
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::load_native_program_xs($descriptor);
}

sub execute_program {
  my ($self, $program, %opts) = @_;
  return $self->_native_runtime->execute_program($program, %opts);
}

sub _native_runtime {
  my ($self) = @_;
  return $self->{_compiled_native_runtime} if $self->{_compiled_native_runtime};
  require GraphQL::Houtou::Runtime::NativeRuntime;
  return $self->{_compiled_native_runtime} = GraphQL::Houtou::Runtime::NativeRuntime->new(
    runtime_schema => $self,
  );
}

sub _compile_native_program_descriptor {
  my ($self, $document, %opts) = @_;
  return GraphQL::Houtou::Runtime::OperationCompiler->compile_operation_native_compact(
    $self,
    $document,
    %opts,
  );
}

sub to_struct {
  my ($self) = @_;
  return {
    version => $self->{version},
    root_types => { %{ $self->{root_types} || {} } },
    type_index => { %{ $self->{type_index} || {} } },
    dispatch_index => { %{ $self->{dispatch_index} || {} } },
    slot_catalog => [ map { $_->to_struct } @{ $self->{slot_catalog} || [] } ],
    blocks => [ map { $_->to_struct } @{ $self->{blocks} || [] } ],
    root_blocks => {
      map {
        my $block = $self->{root_blocks}{$_};
        ($_ => ($block ? $block->name : undef));
      } keys %{ $self->{root_blocks} || {} }
    },
  };
}

sub to_native_struct {
  my ($self) = @_;
  return {
    version => $self->{version},
    root_types => { %{ $self->{root_types} || {} } },
    type_index => {
      map {
        my $entry = $self->{type_index}{$_} || {};
        ($_ => {
          %$entry,
          kind_code => _type_kind_name_code($entry->{kind}),
          completion_family_code => _family_code($entry->{completion_family}),
        });
      } keys %{ $self->{type_index} || {} }
    },
    dispatch_index => {
      map {
        my $entry = $self->{dispatch_index}{$_} || {};
        ($_ => {
          %$entry,
          dispatch_family_code => _dispatch_family_code($entry->{dispatch_family}),
        });
      } keys %{ $self->{dispatch_index} || {} }
    },
    slot_catalog => [ map { $_->to_native_struct } @{ $self->{slot_catalog} || [] } ],
  };
}

sub to_native_compact_struct {
  my ($self) = @_;
  return {
    version => $self->{version},
    root_types => { %{ $self->{root_types} || {} } },
    type_index => {
      map {
        my $entry = $self->{type_index}{$_} || {};
        ($_ => {
          %$entry,
          kind_code => _type_kind_name_code($entry->{kind}),
          completion_family_code => _family_code($entry->{completion_family}),
        });
      } keys %{ $self->{type_index} || {} }
    },
    dispatch_index => {
      map {
        my $entry = $self->{dispatch_index}{$_} || {};
        ($_ => {
          %$entry,
          dispatch_family_code => _dispatch_family_code($entry->{dispatch_family}),
        });
      } keys %{ $self->{dispatch_index} || {} }
    },
    slot_catalog_compact => [ map { $_->to_native_compact_struct } @{ $self->{slot_catalog} || [] } ],
  };
}

sub to_native_exec_struct {
  my ($self) = @_;
  my $struct = $self->to_native_compact_struct;
  $struct->{slot_catalog_exec} = [ map { $_->to_native_exec_struct } @{ $self->{slot_catalog} || [] } ];
  $struct->{slot_resolvers} = [ map { _slot_resolver($self, $_) } @{ $self->{slot_catalog} || [] } ];
  $struct->{runtime_cache} = $self->{runtime_cache};
  $struct->{schema} = $self->{schema};
  return $struct;
}

sub _slot_resolver {
  my ($self, $slot) = @_;
  return undef if !$slot;
  return undef if ($slot->resolver_shape || q()) ne 'EXPLICIT';

  my $key = $slot->schema_slot_key;
  return undef if !defined $key || $key eq q();

  my ($type_name, $field_name) = $key =~ /\A(.+)\.([^.]+)\z/;
  return undef if !defined $type_name || !defined $field_name;

  if ($field_name eq '__schema' || $field_name eq '__type') {
    require GraphQL::Houtou::Introspection;
    return $field_name eq '__schema'
      ? wrap_field_resolver(
          schema => $self->{schema},
          field_name => '__schema',
          field => $GraphQL::Houtou::Introspection::SCHEMA_META_FIELD_DEF,
          resolver => $GraphQL::Houtou::Introspection::SCHEMA_META_FIELD_DEF->{resolve},
        )
      : wrap_field_resolver(
          schema => $self->{schema},
          field_name => '__type',
          field => $GraphQL::Houtou::Introspection::TYPE_META_FIELD_DEF,
          resolver => $GraphQL::Houtou::Introspection::TYPE_META_FIELD_DEF->{resolve},
        );
  }

  if ($field_name eq '__typename') {
    return undef;
  }

  my $type = ($self->{runtime_cache}{name2type} || {})->{$type_name};
  return undef if !$type || !$type->can('fields');

  my $field = ($type->fields || {})->{$field_name};
  return undef if ref($field) ne 'HASH';

  my $wrapped = slot_needs_runtime_wrapper(
    schema => $self->{schema},
    field => $field,
  );
  return $field->{resolve} if !$wrapped;

  return wrap_field_resolver(
    schema => $self->{schema},
    field_name => $field_name,
    field => $field,
    resolver => $field->{resolve},
  );
}

sub _type_kind_name_code {
  my ($kind) = @_;
  return 1 if ($kind || q()) eq 'SCALAR';
  return 2 if ($kind || q()) eq 'OBJECT';
  return 3 if ($kind || q()) eq 'LIST';
  return 4 if ($kind || q()) eq 'INTERFACE';
  return 5 if ($kind || q()) eq 'UNION';
  return 6 if ($kind || q()) eq 'ENUM';
  return 7 if ($kind || q()) eq 'INPUT_OBJECT';
  return 8 if ($kind || q()) eq 'NON_NULL';
  return 0;
}

sub _family_code {
  my ($family) = @_;
  return 2 if ($family || q()) eq 'OBJECT';
  return 3 if ($family || q()) eq 'LIST';
  return 4 if ($family || q()) eq 'ABSTRACT';
  return 1;
}

sub _dispatch_family_code {
  my ($family) = @_;
  return 2 if ($family || q()) eq 'RESOLVE_TYPE';
  return 3 if ($family || q()) eq 'TAG';
  return 4 if ($family || q()) eq 'POSSIBLE_TYPES';
  return 1;
}

sub _build_type_index {
  my ($name2type) = @_;
  my %index;

  for my $name (sort keys %{$name2type || {}}) {
    my $type = $name2type->{$name} or next;
    $index{$name} = {
      kind => _type_kind($type),
      completion_family => _completion_family_for_type($type),
      runtime_tag => ($type->can('runtime_tag') ? $type->runtime_tag : undef),
    };
  }

  return \%index;
}

sub _build_dispatch_index {
  my ($runtime_cache) = @_;
  my %dispatch;

  for my $name (sort keys %{ $runtime_cache->{resolve_type_map} || {} }) {
    $dispatch{$name}{dispatch_family} = 'RESOLVE_TYPE';
  }
  for my $name (sort keys %{ $runtime_cache->{tag_resolver_map} || {} }) {
    $dispatch{$name}{dispatch_family} = 'TAG';
  }
  for my $name (sort keys %{ $runtime_cache->{possible_types} || {} }) {
    $dispatch{$name}{dispatch_family} ||= 'POSSIBLE_TYPES';
  }

  return \%dispatch;
}

sub _build_blocks {
  my ($schema, $runtime_cache) = @_;
  my @blocks;
  my %root_blocks;
  my %root_types;
  my %blocks_by_type;

  for my $type_name (sort keys %{ $runtime_cache->{name2type} || {} }) {
    my $type = $runtime_cache->{name2type}{$type_name} or next;
    next if !$type->isa('GraphQL::Houtou::Type::Object');
    my $block = GraphQL::Houtou::Runtime::SchemaBlock->new(
      name => uc($type_name),
      family => 'OBJECT',
      root_type_name => $type->name,
      slots => _build_slots_for_object($schema, $type),
    );
    push @blocks, $block;
    $blocks_by_type{ $type->name } = $block;
  }

  for my $root_name (qw(query mutation subscription)) {
    my $root_type = $runtime_cache->{root_types}{$root_name} or next;
    my $block = $blocks_by_type{ $root_type->name } or next;
    $root_blocks{$root_name} = $block;
    $root_types{$root_name} = $root_type->name;
    _add_introspection_meta_slots($block, $root_type)
      if $root_name eq 'query';
  }

  return (\@blocks, \%root_blocks, \%root_types);
}

sub _inflate_blocks {
  my ($struct) = @_;
  my $legacy_program = $struct->{program} || {};
  my $blocks_struct = $struct->{blocks} || $legacy_program->{blocks} || [];
  my $root_blocks_struct = $struct->{root_blocks} || $legacy_program->{root_blocks} || {};
  my @blocks = map { _inflate_block($_) } @{ $blocks_struct };
  my %by_name = map { ($_->name => $_) } @blocks;
  my %root_blocks = map {
    ($_ => ($root_blocks_struct->{$_} ? $by_name{ $root_blocks_struct->{$_} } : undef));
  } keys %{ $root_blocks_struct };

  return (\@blocks, \%root_blocks);
}

sub _inflate_block {
  my ($struct) = @_;
  return GraphQL::Houtou::Runtime::SchemaBlock->new(
    name => $struct->{name},
    family => $struct->{family},
    root_type_name => $struct->{root_type_name},
    slots => [ map { _inflate_slot($_) } @{ $struct->{slots} || [] } ],
  );
}

sub _inflate_slot {
  my ($struct) = @_;
  return GraphQL::Houtou::Runtime::Slot->new(
    schema_slot_key => $struct->{schema_slot_key},
    schema_slot_index => $struct->{schema_slot_index},
    field_name => $struct->{field_name},
    result_name => $struct->{result_name},
    return_type_name => $struct->{return_type_name},
    resolver_shape => $struct->{resolver_shape},
    resolver_mode => $struct->{resolver_mode},
    completion_family => $struct->{completion_family},
    dispatch_family => $struct->{dispatch_family},
    arg_defs_compact => (
      exists $struct->{arg_defs_compact}
      ? $struct->{arg_defs_compact}
      : ($struct->{arg_defs} || [])
    ),
    return_type_kind_code => $struct->{return_type_kind_code} || 0,
    item_non_null => $struct->{item_non_null} || 0,
    has_args => $struct->{has_args},
    has_directives => $struct->{has_directives},
  );
}

sub _build_slots_for_object {
  my ($schema, $type) = @_;
  my $fields = $type->fields || {};
  my @slots = (
    GraphQL::Houtou::Runtime::Slot->new(
      schema_slot_key => join(q(.), $type->name, '__typename'),
      field_name => '__typename',
      result_name => '__typename',
      return_type_name => 'String',
      resolver_shape => 'DEFAULT',
      resolver_mode => 'DEFAULT',
      completion_family => 'GENERIC',
      dispatch_family => 'GENERIC',
      arg_defs_compact => [],
      return_type_kind_code => 1,
      has_args => 0,
      has_directives => 0,
    ),
  );

  for my $field_name (sort keys %$fields) {
    my $field = $fields->{$field_name} || {};
    my $return_type = $field->{type};
    my $wrapped = slot_needs_runtime_wrapper(
      schema => $schema,
      field => $field,
    );
    push @slots, GraphQL::Houtou::Runtime::Slot->new(
      schema_slot_key => join(q(.), $type->name, $field_name),
      field_name => $field_name,
      result_name => $field_name,
      return_type_name => _type_name($return_type),
      resolver_shape => ($field->{resolve} || $wrapped) ? 'EXPLICIT' : 'DEFAULT',
      resolver_mode => $wrapped
        ? 'DEFAULT'
        : (($field->{resolver_mode} || q()) eq 'native' ? 'NATIVE' : 'DEFAULT'),
      completion_family => _completion_family_for_type($return_type),
      dispatch_family => _dispatch_family_for_type($return_type),
      arg_defs_compact => _build_input_defs_compact($field->{args} || {}),
      return_type_kind_code => _type_kind_code($return_type),
      item_non_null => _item_non_null_for_type($return_type),
      has_args => ($field->{args} && keys %{ $field->{args} }) ? 1 : 0,
      has_directives => ($field->{directives} && @{ $field->{directives} }) ? 1 : 0,
    );
  }

  return \@slots;
}

# True when the field is list-typed and its item type is Non-Null
# ([T!], [T!]!): a null item then propagates to the list position
# (spec 6.4.4). Nested list interiors ([[T!]]) are not tracked yet.
sub _item_non_null_for_type {
  my ($type) = @_;
  return 0 if !$type;
  $type = $type->of if $type->isa('GraphQL::Houtou::Type::NonNull');
  return 0 if !$type->isa('GraphQL::Houtou::Type::List');
  return $type->of && $type->of->isa('GraphQL::Houtou::Type::NonNull') ? 1 : 0;
}

sub _add_introspection_meta_slots {
  my ($block, $root_type) = @_;
  require GraphQL::Houtou::Introspection;

  for my $meta_def (
    $GraphQL::Houtou::Introspection::SCHEMA_META_FIELD_DEF,
    $GraphQL::Houtou::Introspection::TYPE_META_FIELD_DEF,
  ) {
    my $return_type = $meta_def->{type};
    push @{ $block->{slots} }, GraphQL::Houtou::Runtime::Slot->new(
      schema_slot_key  => join(q(.), $root_type->name, $meta_def->{name}),
      field_name       => $meta_def->{name},
      result_name      => $meta_def->{name},
      return_type_name => _type_name($return_type),
      resolver_shape   => 'EXPLICIT',
      resolver_mode    => 'DEFAULT',
      completion_family    => _completion_family_for_type($return_type),
      dispatch_family      => _dispatch_family_for_type($return_type),
      arg_defs_compact     => _build_input_defs_compact($meta_def->{args} || {}),
      return_type_kind_code => _type_kind_code($return_type),
      has_args         => ($meta_def->{args} && keys %{ $meta_def->{args} }) ? 1 : 0,
      has_directives   => 0,
    );
  }
}

sub _build_slot_catalog {
  my ($blocks) = @_;
  my @catalog;
  my %seen;

  for my $block (@{ $blocks || [] }) {
    for my $slot (@{ $block->slots || [] }) {
      my $key = $slot->schema_slot_key // join(q(.), ($block->root_type_name || q()), $slot->field_name);
      next if exists $seen{$key};
      $slot->{schema_slot_key} ||= $key;
      $slot->{schema_slot_index} = scalar @catalog;
      $seen{$key} = $slot;
      push @catalog, $slot;
    }
  }

  return \@catalog;
}

sub _apply_slot_catalog_to_blocks {
  my ($blocks, $slot_catalog) = @_;
  my %catalog_by_key = map {
    my $slot = $slot_catalog->[$_];
    $slot->{schema_slot_index} = $_ if !defined $slot->{schema_slot_index};
    (($slot->schema_slot_key || q()) => $slot);
  } 0 .. $#$slot_catalog;

  for my $block (@{ $blocks || [] }) {
    my @slots;
    for my $slot (@{ $block->slots || [] }) {
      my $key = $slot->schema_slot_key // join(q(.), ($block->root_type_name || q()), $slot->field_name);
      my $catalog_slot = $catalog_by_key{$key} || $slot;
      push @slots, $catalog_slot;
    }
    $block->{slots} = \@slots;
  }

  return $blocks;
}

sub _build_input_defs_compact {
  my ($defs) = @_;
  my @built;
  for my $name (sort keys %{$defs || {}}) {
    my $def = $defs->{$name} || {};
    push @built, [
      $name,
      _typedef_for_type($def->{type}),
      exists $def->{default_value} ? 1 : 0,
      $def->{default_value},
    ];
  }
  return \@built;
}

sub _type_kind_code {
  my ($type) = @_;
  return 0 if !$type;
  return 8 if $type->isa('GraphQL::Houtou::Type::NonNull');
  return 3 if $type->isa('GraphQL::Houtou::Type::List');
  return 2 if $type->isa('GraphQL::Houtou::Type::Object');
  return 4 if $type->isa('GraphQL::Houtou::Type::Interface');
  return 5 if $type->isa('GraphQL::Houtou::Type::Union');
  return 6 if $type->isa('GraphQL::Houtou::Type::Enum');
  return 7 if $type->isa('GraphQL::Houtou::Type::InputObject');
  return 1;
}

sub _type_kind {
  my ($type) = @_;
  return 'NON_NULL' if $type->isa('GraphQL::Houtou::Type::NonNull');
  return 'LIST' if $type->isa('GraphQL::Houtou::Type::List');
  return 'OBJECT' if $type->isa('GraphQL::Houtou::Type::Object');
  return 'INTERFACE' if $type->isa('GraphQL::Houtou::Type::Interface');
  return 'UNION' if $type->isa('GraphQL::Houtou::Type::Union');
  return 'ENUM' if $type->isa('GraphQL::Houtou::Type::Enum');
  return 'INPUT_OBJECT' if $type->isa('GraphQL::Houtou::Type::InputObject');
  return 'SCALAR';
}

sub _completion_family_for_type {
  my ($type) = @_;
  return 'GENERIC' if !$type;
  return _completion_family_for_type($type->of) if $type->isa('GraphQL::Houtou::Type::NonNull');
  return 'OBJECT' if $type->isa('GraphQL::Houtou::Type::Object');
  return 'LIST' if $type->isa('GraphQL::Houtou::Type::List');
  return 'ABSTRACT'
    if $type->isa('GraphQL::Houtou::Type::Interface')
    || $type->isa('GraphQL::Houtou::Type::Union');
  return 'GENERIC';
}

sub _dispatch_family_for_type {
  my ($type) = @_;
  return _dispatch_family_for_type($type->of) if $type && $type->isa('GraphQL::Houtou::Type::NonNull');
  return 'TAG' if $type && ($type->isa('GraphQL::Houtou::Type::Interface') || $type->isa('GraphQL::Houtou::Type::Union'));
  if ($type && $type->isa('GraphQL::Houtou::Type::List')) {
    # A list of an interface/union dispatches per item: the op must carry
    # the abstract dispatch family or the runtime's member-block selection
    # never runs for the items.
    my $inner = _dispatch_family_for_type($type->of);
    return $inner if $inner eq 'TAG' || $inner eq 'RESOLVE_TYPE' || $inner eq 'ABSTRACT';
    return 'LIST';
  }
  return 'OBJECT' if $type && $type->isa('GraphQL::Houtou::Type::Object');
  return 'ABSTRACT' if $type && ($type->isa('GraphQL::Houtou::Type::Interface') || $type->isa('GraphQL::Houtou::Type::Union'));
  return 'GENERIC';
}

sub _type_name {
  my ($type) = @_;
  return if !$type;
  return $type->name if $type->can('name');
  return;
}

sub _typedef_for_type {
  my ($type) = @_;
  return if !$type;
  return { type => ['non_null', _typedef_for_type($type->of)] }
    if $type->isa('GraphQL::Houtou::Type::NonNull');
  return { type => ['list', _typedef_for_type($type->of)] }
    if $type->isa('GraphQL::Houtou::Type::List');
  return { type => $type->name } if $type->can('name');
  return;
}

1;
