package GraphQL::Houtou::Runtime::VMOp;

use 5.014;
use strict;
use warnings;

use Scalar::Util qw(refaddr);

use constant {
  OPCODE_SLOT                                => 0,
  OPCODE_CODE_SLOT                           => 1,
  RESOLVE_FAMILY_SLOT                        => 2,
  RESOLVE_CODE_SLOT                          => 3,
  COMPLETE_FAMILY_SLOT                       => 4,
  COMPLETE_CODE_SLOT                         => 5,
  FIELD_NAME_SLOT                            => 6,
  RESULT_NAME_SLOT                           => 7,
  RETURN_TYPE_NAME_SLOT                      => 8,
  DISPATCH_FAMILY_SLOT                       => 9,
  CHILD_BLOCK_NAME_SLOT                      => 10,
  ABSTRACT_CHILD_BLOCKS_SLOT                 => 11,
  ARGS_MODE_SLOT                             => 12,
  ARGS_PAYLOAD_SLOT                          => 13,
  HAS_ARGS_SLOT                              => 14,
  DIRECTIVES_MODE_SLOT                       => 15,
  DIRECTIVES_PAYLOAD_SLOT                    => 16,
  HAS_DIRECTIVES_SLOT                        => 17,
  BOUND_SLOT_SLOT                            => 18,
  BOUND_CHILD_BLOCK_SLOT                     => 19,
  BOUND_ABSTRACT_CHILD_BLOCKS_SLOT           => 20,
  NATIVE_SLOT_INDEX_SLOT                     => 21,
  NATIVE_CHILD_BLOCK_INDEX_SLOT              => 22,
  NATIVE_ABSTRACT_CHILD_BLOCK_INDEXES_SLOT   => 23,
  ARGS_PAYLOAD_INDEX_SLOT                    => 24,
  DIRECTIVES_PAYLOAD_INDEX_SLOT              => 25,
  BLOCK_SLOT                                 => 26,
  ABSTRACT_CHILD_BLOCKS_INDEX_SLOT           => 27,
  RUNTIME_DIRECTIVES_MODE_SLOT               => 28,
  RUNTIME_DIRECTIVES_PAYLOAD_SLOT            => 29,
  HAS_RUNTIME_DIRECTIVES_SLOT                => 30,
};

sub new {
  my ($class, %args) = @_;
  return bless [
    $args{opcode},
    $args{opcode_code} || 0,
    $args{resolve_family},
    $args{resolve_code} || 0,
    $args{complete_family},
    $args{complete_code} || 0,
    $args{field_name},
    $args{result_name},
    $args{return_type_name},
    $args{dispatch_family},
    $args{child_block_name},
    $args{abstract_child_blocks} || {},
    $args{args_mode} || 'NONE',
    $args{args_payload},
    $args{has_args} ? 1 : 0,
    $args{directives_mode} || 'NONE',
    $args{directives_payload},
    $args{has_directives} ? 1 : 0,
    $args{bound_slot},
    $args{bound_child_block},
    $args{bound_abstract_child_blocks} || {},
    $args{native_slot_index},
    $args{native_child_block_index},
    $args{native_abstract_child_block_indexes} || {},
    $args{args_payload_index},
    $args{directives_payload_index},
    undef,
    $args{abstract_child_blocks_index},
    $args{runtime_directives_mode} || 'NONE',
    $args{runtime_directives_payload},
    $args{has_runtime_directives} ? 1 : 0,
  ], $class;
}

sub opcode { return $_[0][OPCODE_SLOT] }
sub opcode_code { return $_[0][OPCODE_CODE_SLOT] }
sub resolve_family { return $_[0][RESOLVE_FAMILY_SLOT] }
sub resolve_code { return $_[0][RESOLVE_CODE_SLOT] }
sub complete_family { return $_[0][COMPLETE_FAMILY_SLOT] }
sub complete_code { return $_[0][COMPLETE_CODE_SLOT] }
sub field_name { return $_[0][FIELD_NAME_SLOT] }
sub result_name { return $_[0][RESULT_NAME_SLOT] }
sub return_type_name { return $_[0][RETURN_TYPE_NAME_SLOT] }
sub dispatch_family { return $_[0][DISPATCH_FAMILY_SLOT] }
sub child_block_name { return $_[0][CHILD_BLOCK_NAME_SLOT] }
sub abstract_child_blocks_index { return $_[0][ABSTRACT_CHILD_BLOCKS_INDEX_SLOT] }
sub args_mode { return $_[0][ARGS_MODE_SLOT] }
sub args_payload {
  return _catalog_payload($_[0], ARGS_PAYLOAD_SLOT, ARGS_PAYLOAD_INDEX_SLOT, 'args_payloads');
}
sub has_args { return $_[0][HAS_ARGS_SLOT] }
sub directives_mode { return $_[0][DIRECTIVES_MODE_SLOT] }
sub directives_payload {
  return _catalog_payload($_[0], DIRECTIVES_PAYLOAD_SLOT, DIRECTIVES_PAYLOAD_INDEX_SLOT, 'directives_payloads');
}
sub has_directives { return $_[0][HAS_DIRECTIVES_SLOT] }
sub bound_slot { return $_[0][BOUND_SLOT_SLOT] }
sub bound_child_block { return $_[0][BOUND_CHILD_BLOCK_SLOT] }
sub bound_abstract_child_blocks { return $_[0][BOUND_ABSTRACT_CHILD_BLOCKS_SLOT] }
sub native_slot_index { return $_[0][NATIVE_SLOT_INDEX_SLOT] }
sub native_child_block_index { return $_[0][NATIVE_CHILD_BLOCK_INDEX_SLOT] }
sub native_abstract_child_block_indexes { return $_[0][NATIVE_ABSTRACT_CHILD_BLOCK_INDEXES_SLOT] }
sub args_payload_index { return $_[0][ARGS_PAYLOAD_INDEX_SLOT] }
sub directives_payload_index { return $_[0][DIRECTIVES_PAYLOAD_INDEX_SLOT] }
sub runtime_directives_mode { return $_[0][RUNTIME_DIRECTIVES_MODE_SLOT] }
sub runtime_directives_payload { return $_[0][RUNTIME_DIRECTIVES_PAYLOAD_SLOT] }
sub has_runtime_directives { return $_[0][HAS_RUNTIME_DIRECTIVES_SLOT] }
sub block { return $_[0][BLOCK_SLOT] }

sub set_field_name { $_[0][FIELD_NAME_SLOT] = $_[1]; return $_[1] }
sub set_result_name { $_[0][RESULT_NAME_SLOT] = $_[1]; return $_[1] }
sub set_child_block_name { $_[0][CHILD_BLOCK_NAME_SLOT] = $_[1]; return $_[1] }
sub set_bound_slot { $_[0][BOUND_SLOT_SLOT] = $_[1]; return $_[1] }
sub set_bound_child_block { $_[0][BOUND_CHILD_BLOCK_SLOT] = $_[1]; return $_[1] }
sub set_bound_abstract_child_blocks { $_[0][BOUND_ABSTRACT_CHILD_BLOCKS_SLOT] = $_[1] || {}; return $_[0][BOUND_ABSTRACT_CHILD_BLOCKS_SLOT] }
sub set_abstract_child_blocks { $_[0][ABSTRACT_CHILD_BLOCKS_SLOT] = $_[1]; return $_[0][ABSTRACT_CHILD_BLOCKS_SLOT] }
sub set_native_slot_index { $_[0][NATIVE_SLOT_INDEX_SLOT] = $_[1]; return $_[1] }
sub set_native_child_block_index { $_[0][NATIVE_CHILD_BLOCK_INDEX_SLOT] = $_[1]; return $_[1] }
sub set_native_abstract_child_block_indexes { $_[0][NATIVE_ABSTRACT_CHILD_BLOCK_INDEXES_SLOT] = $_[1] || {}; return $_[0][NATIVE_ABSTRACT_CHILD_BLOCK_INDEXES_SLOT] }
sub set_abstract_child_blocks_index { $_[0][ABSTRACT_CHILD_BLOCKS_INDEX_SLOT] = $_[1]; return $_[1] }
sub set_args_payload_index { $_[0][ARGS_PAYLOAD_INDEX_SLOT] = $_[1]; return $_[1] }
sub set_directives_payload_index { $_[0][DIRECTIVES_PAYLOAD_INDEX_SLOT] = $_[1]; return $_[1] }
sub set_runtime_directives_mode { $_[0][RUNTIME_DIRECTIVES_MODE_SLOT] = $_[1] || 'NONE'; return $_[0][RUNTIME_DIRECTIVES_MODE_SLOT] }
sub set_runtime_directives_payload { $_[0][RUNTIME_DIRECTIVES_PAYLOAD_SLOT] = $_[1]; return $_[1] }
sub set_has_runtime_directives { $_[0][HAS_RUNTIME_DIRECTIVES_SLOT] = $_[1] ? 1 : 0; return $_[0][HAS_RUNTIME_DIRECTIVES_SLOT] }
sub set_has_args { $_[0][HAS_ARGS_SLOT] = $_[1] ? 1 : 0; return $_[0][HAS_ARGS_SLOT] }
sub set_args_mode { $_[0][ARGS_MODE_SLOT] = $_[1] || 'NONE'; return $_[0][ARGS_MODE_SLOT] }
sub set_args_payload { $_[0][ARGS_PAYLOAD_SLOT] = $_[1]; return $_[1] }
sub set_has_directives { $_[0][HAS_DIRECTIVES_SLOT] = $_[1] ? 1 : 0; return $_[0][HAS_DIRECTIVES_SLOT] }
sub set_directives_mode { $_[0][DIRECTIVES_MODE_SLOT] = $_[1] || 'NONE'; return $_[0][DIRECTIVES_MODE_SLOT] }
sub set_directives_payload { $_[0][DIRECTIVES_PAYLOAD_SLOT] = $_[1]; return $_[1] }
sub set_block {
  my ($self, $block) = @_;
  $self->[BLOCK_SLOT] = $block;
  Scalar::Util::weaken($self->[BLOCK_SLOT]) if ref($self->[BLOCK_SLOT]);
  return $self->[BLOCK_SLOT];
}

sub to_struct {
  my ($self) = @_;
  return {
    opcode => $self->opcode,
    opcode_code => $self->opcode_code,
    resolve_family => $self->resolve_family,
    resolve_code => $self->resolve_code,
    complete_family => $self->complete_family,
    complete_code => $self->complete_code,
    field_name => $self->field_name,
    result_name => $self->result_name,
    return_type_name => $self->return_type_name,
    dispatch_family => $self->dispatch_family,
    child_block_name => $self->child_block_name,
    abstract_child_blocks => _clone_value($self->abstract_child_blocks),
    abstract_child_blocks_index => $self->abstract_child_blocks_index,
    args_mode => $self->args_mode,
    args_payload => _clone_value($self->args_payload),
    args_payload_index => $self->args_payload_index,
    has_args => $self->has_args,
    directives_mode => $self->directives_mode,
    directives_payload => _clone_value($self->directives_payload),
    directives_payload_index => $self->directives_payload_index,
    has_directives => $self->has_directives,
    runtime_directives_mode => $self->runtime_directives_mode,
    runtime_directives_payload => _clone_value($self->runtime_directives_payload),
    has_runtime_directives => $self->has_runtime_directives,
  };
}

sub to_native_struct {
  my ($self, $block_index, $slot_index, $payload_catalog) = @_;
  my $slot = $self->bound_slot;
  my $slot_id = $slot
    ? join("\x1E", refaddr($slot), ($self->result_name // q()))
    : undef;
  my $native_abstract_child_block_indexes = $self->native_abstract_child_block_indexes || {};
  my $abstract_child_blocks = $self->abstract_child_blocks || {};
  my $args_payload_index = defined $self->args_payload_index
    ? $self->args_payload_index
    : ($payload_catalog ? $payload_catalog->intern_args_payload($self->args_payload) : undef);
  my $directives_payload_index = defined $self->directives_payload_index
    ? $self->directives_payload_index
    : ($payload_catalog ? $payload_catalog->intern_directives_payload($self->directives_payload) : undef);
  return {
    opcode_code => $self->opcode_code,
    resolve_code => $self->resolve_code,
    complete_code => $self->complete_code,
    return_type_name => $self->return_type_name,
    dispatch_family_code => _dispatch_family_code($self->dispatch_family),
    slot_index => defined $slot_id && exists $slot_index->{$slot_id}
      ? $slot_index->{$slot_id}
      : undef,
    args_mode_code => _args_mode_code($self->args_mode),
    args_payload_index => $args_payload_index,
    args_payload => defined $args_payload_index ? undef : _clone_value($self->args_payload),
    args_mode => $self->args_mode,
    has_args => $self->has_args,
    directives_mode => $self->directives_mode,
    directives_mode_code => _directives_mode_code($self->directives_mode),
    directives_payload_index => $directives_payload_index,
    directives_payload => defined $directives_payload_index ? undef : _clone_value($self->directives_payload),
    has_directives => $self->has_directives,
    runtime_directives_mode => $self->runtime_directives_mode,
    runtime_directives_mode_code => _directives_mode_code($self->runtime_directives_mode),
    runtime_directives_payload => _clone_value($self->runtime_directives_payload),
    has_runtime_directives => $self->has_runtime_directives,
    child_block_index => defined $self->child_block_name && exists $block_index->{ $self->child_block_name }
      ? $block_index->{ $self->child_block_name }
      : undef,
    abstract_child_block_indexes =>
      (ref($native_abstract_child_block_indexes) eq 'HASH' && keys %$native_abstract_child_block_indexes)
        ? { %$native_abstract_child_block_indexes }
        : {
            map {
              my $child_name = $abstract_child_blocks->{$_};
              ($_ => (defined $child_name && exists $block_index->{$child_name} ? $block_index->{$child_name} : undef))
            } keys %$abstract_child_blocks
          },
    abstract_child_blocks_index => undef,
  };
}

sub to_native_compact_struct {
  my ($self, $block_index, $slot_index, $payload_catalog) = @_;
  my $struct = $self->to_native_struct($block_index, $slot_index, $payload_catalog);
  return [
    $struct->{opcode_code},
    $struct->{resolve_code},
    $struct->{complete_code},
    $struct->{dispatch_family_code},
    $struct->{slot_index},
    $struct->{child_block_index},
    $struct->{abstract_child_block_indexes},
    $struct->{args_mode_code},
    $struct->{args_payload_index},
    $struct->{args_payload},
    $struct->{has_args},
    $struct->{directives_mode_code},
    $struct->{directives_payload_index},
    $struct->{directives_payload},
    $struct->{has_directives},
    $self->field_name,
    $self->result_name,
    $self->return_type_name,
    $struct->{runtime_directives_mode_code},
    $struct->{runtime_directives_payload},
    $struct->{has_runtime_directives},
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

sub _clone_value {
  my ($value) = @_;
  my $ref = ref($value);
  return $value if !$ref;
  return [ map { _clone_value($_) } @$value ] if $ref eq 'ARRAY';
  return { map { $_ => _clone_value($value->{$_}) } keys %$value } if $ref eq 'HASH';
  return $value;
}

sub _catalog_payload {
  my ($self, $payload_slot, $index_slot, $catalog_method) = @_;
  my $payload = $self->[$payload_slot];
  return $payload if defined $payload;
  my $index = $self->[$index_slot];
  return undef if !defined $index;
  my $block = $self->block or return undef;
  my $program = $block->program or return undef;
  my $catalog = $program->$catalog_method || [];
  return $catalog->[$index];
}

sub abstract_child_blocks {
  my ($self) = @_;
  my $payload = $self->[ABSTRACT_CHILD_BLOCKS_SLOT];
  return $payload if defined $payload;
  my $native = $self->[NATIVE_ABSTRACT_CHILD_BLOCK_INDEXES_SLOT];
  return $native if ref($native) eq 'HASH' && keys %$native;
  return _catalog_payload($self, ABSTRACT_CHILD_BLOCKS_SLOT, ABSTRACT_CHILD_BLOCKS_INDEX_SLOT, 'abstract_child_maps');
}

1;
