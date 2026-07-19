package GraphQL::Houtou::Runtime::VMProgram;

use 5.014;
use strict;
use warnings;
use Scalar::Util qw(refaddr);

use GraphQL::Houtou ();

use constant {
  VERSION_SLOT        => 0,
  OPERATION_TYPE_SLOT => 1,
  OPERATION_NAME_SLOT => 2,
  VARIABLE_DEFS_SLOT  => 3,
  BLOCKS_SLOT         => 4,
  ROOT_BLOCK_SLOT     => 5,
  BLOCK_MAP_SLOT      => 6,
  DISPATCH_BOUND_SLOT => 7,
  NATIVE_COMPACT_STRUCT_SLOT => 8,
  ROOT_BLOCK_INDEX_SLOT => 9,
  ARGS_PAYLOADS_SLOT => 10,
  DIRECTIVES_PAYLOADS_SLOT => 11,
  ABSTRACT_CHILD_MAPS_SLOT => 12,
};

{
  package GraphQL::Houtou::Runtime::VMProgram::PayloadCatalog;

  use 5.014;
  use strict;
  use warnings;

  sub new {
    my ($class, %args) = @_;
    my $args_payloads = [ map { GraphQL::Houtou::Runtime::VMProgram::_clone_value($_) } @{ $args{args_payloads} || [] } ];
    my $directives_payloads = [ map { GraphQL::Houtou::Runtime::VMProgram::_clone_value($_) } @{ $args{directives_payloads} || [] } ];
    my %args_index = map {
      (_canonical_key($args_payloads->[$_]) => $_)
    } 0 .. $#$args_payloads;
    my %directives_index = map {
      (_canonical_key($directives_payloads->[$_]) => $_)
    } 0 .. $#$directives_payloads;
    return bless {
      args_payloads => $args_payloads,
      directives_payloads => $directives_payloads,
      args_index => \%args_index,
      directives_index => \%directives_index,
    }, $class;
  }

  sub args_payloads { return $_[0]{args_payloads} }
  sub directives_payloads { return $_[0]{directives_payloads} }

  sub intern_args_payload {
    my ($self, $payload) = @_;
    return undef if !_payload_present($payload);
    my $key = _canonical_key($payload);
    return $self->{args_index}{$key} if exists $self->{args_index}{$key};
    my $index = @{ $self->{args_payloads} };
    push @{ $self->{args_payloads} }, GraphQL::Houtou::Runtime::VMProgram::_clone_value($payload);
    $self->{args_index}{$key} = $index;
    return $index;
  }

  sub intern_directives_payload {
    my ($self, $payload) = @_;
    return undef if !_payload_present($payload);
    my $key = _canonical_key($payload);
    return $self->{directives_index}{$key} if exists $self->{directives_index}{$key};
    my $index = @{ $self->{directives_payloads} };
    push @{ $self->{directives_payloads} }, GraphQL::Houtou::Runtime::VMProgram::_clone_value($payload);
    $self->{directives_index}{$key} = $index;
    return $index;
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

  sub _canonical_key {
    my ($value) = @_;
    my $ref = ref($value);
    return '!undef' if !defined $value;
    return "S:$value" if !$ref;
    return 'A:[' . join(',', map { _canonical_key($_) } @$value) . ']' if $ref eq 'ARRAY';
    return 'H:{' . join(',', map { $_ . '=>' . _canonical_key($value->{$_}) } sort keys %$value) . '}' if $ref eq 'HASH';
    return "$ref:$value";
  }
}

sub new {
  my ($class, %args) = @_;
  my $root_block = $args{root_block};
  my @blocks = @{ $args{blocks} || [] };
  my %block_map = map { defined $_->name ? ($_->name => $_) : () } @blocks;
  $block_map{ $root_block->name } = $root_block if $root_block && defined $root_block->name;
  my $self = bless [
    $args{version} || 1,
    $args{operation_type} || 'query',
    $args{operation_name},
    $args{variable_defs} || {},
    \@blocks,
    $root_block,
    \%block_map,
    0,
    undef,
    undef,
    $args{args_payloads} || [],
    $args{directives_payloads} || [],
    [],
  ], $class;
  for my $block (@blocks, ($root_block || ())) {
    next if !$block;
    my $owner = $block->can('program') ? $block->program : undef;
    next if $owner && refaddr($owner) == refaddr($self);
    $block->set_program($self) if $block->can('set_program');
  }
  _canonicalize_catalog_backed_payloads($self);
  return $self;
}

sub version { return $_[0][VERSION_SLOT] }
sub operation_type { return $_[0][OPERATION_TYPE_SLOT] }
sub operation_name { return $_[0][OPERATION_NAME_SLOT] }
sub variable_defs { return $_[0][VARIABLE_DEFS_SLOT] }
sub blocks { return $_[0][BLOCKS_SLOT] }
sub root_block { return $_[0][ROOT_BLOCK_SLOT] }
sub root_block_index {
  my ($self) = @_;
  return $self->[ROOT_BLOCK_INDEX_SLOT] if defined $self->[ROOT_BLOCK_INDEX_SLOT];
  my @blocks = @{ $self->blocks || [] };
  my %block_index = map { ($blocks[$_]->name => $_) } 0 .. $#blocks;
  return $self->[ROOT_BLOCK_INDEX_SLOT] =
    ($self->root_block ? $block_index{ $self->root_block->name } : undef);
}
sub dispatch_bound { return $_[0][DISPATCH_BOUND_SLOT] }
sub args_payloads { return $_[0][ARGS_PAYLOADS_SLOT] }
sub directives_payloads { return $_[0][DIRECTIVES_PAYLOADS_SLOT] }
sub abstract_child_maps { return $_[0][ABSTRACT_CHILD_MAPS_SLOT] }
sub set_variable_defs {
  $_[0][VARIABLE_DEFS_SLOT] = $_[1] || {};
  $_[0][NATIVE_COMPACT_STRUCT_SLOT] = undef;
  $_[0][ROOT_BLOCK_INDEX_SLOT] = undef;
  return $_[0][VARIABLE_DEFS_SLOT];
}
sub set_dispatch_bound {
  $_[0][DISPATCH_BOUND_SLOT] = $_[1] ? 1 : 0;
  $_[0][NATIVE_COMPACT_STRUCT_SLOT] = undef;
  $_[0][ROOT_BLOCK_INDEX_SLOT] = undef;
  return $_[0][DISPATCH_BOUND_SLOT];
}

sub block_by_name {
  my ($self, $name) = @_;
  return if !defined $name;
  return $self->[BLOCK_MAP_SLOT]{$name};
}

sub to_struct {
  my ($self) = @_;
  return {
    version => $self->version,
    operation_type => $self->operation_type,
    operation_name => $self->operation_name,
    variable_defs => { %{ $self->variable_defs || {} } },
    args_payloads => [ map { _clone_value($_) } @{ $self->args_payloads || [] } ],
    directives_payloads => [ map { _clone_value($_) } @{ $self->directives_payloads || [] } ],
    root_block => $self->root_block ? $self->root_block->name : undef,
    blocks => [ map { $_->to_struct } @{ $self->blocks || [] } ],
  };
}

sub to_native_struct {
  my ($self) = @_;
  my @blocks = @{ $self->blocks || [] };
  my %block_index = map { ($blocks[$_]->name => $_) } 0 .. $#blocks;
  my $payload_catalog = GraphQL::Houtou::Runtime::VMProgram::PayloadCatalog->new(
    args_payloads => $self->args_payloads,
    directives_payloads => $self->directives_payloads,
  );
  return {
    version => $self->version,
    operation_type => $self->operation_type,
    operation_type_code => _operation_type_code($self->operation_type),
    operation_name => $self->operation_name,
    variable_defs => { %{ $self->variable_defs || {} } },
    args_payloads => $payload_catalog->args_payloads,
    directives_payloads => $payload_catalog->directives_payloads,
    root_block_index => $self->root_block_index,
    blocks => [ map { $_->to_native_struct(\%block_index, $payload_catalog) } @blocks ],
  };
}

sub to_native_compact_struct {
  my ($self) = @_;
  return $self->[NATIVE_COMPACT_STRUCT_SLOT] if $self->[NATIVE_COMPACT_STRUCT_SLOT];
  my @blocks = @{ $self->blocks || [] };
  my %block_index = map { ($blocks[$_]->name => $_) } 0 .. $#blocks;
  my $payload_catalog = GraphQL::Houtou::Runtime::VMProgram::PayloadCatalog->new(
    args_payloads => $self->args_payloads,
    directives_payloads => $self->directives_payloads,
  );
  return $self->[NATIVE_COMPACT_STRUCT_SLOT] = {
    version => $self->version,
    operation_type_code => _operation_type_code($self->operation_type),
    operation_name => $self->operation_name,
    variable_defs => { %{ $self->variable_defs || {} } },
    args_payloads_compact => $payload_catalog->args_payloads,
    directives_payloads_compact => $payload_catalog->directives_payloads,
    root_block_index => $self->root_block_index,
    blocks_compact => [ map { $_->to_native_compact_struct(\%block_index, $payload_catalog) } @blocks ],
  };
}

sub _operation_type_code {
  my ($type) = @_;
  return 2 if ($type || q()) eq 'mutation';
  return 3 if ($type || q()) eq 'subscription';
  return 1;
}

sub _clone_value {
  my ($value) = @_;
  my $ref = ref($value);
  return $value if !$ref;
  return [ map { _clone_value($_) } @$value ] if $ref eq 'ARRAY';
  return { map { $_ => _clone_value($value->{$_}) } keys %$value } if $ref eq 'HASH';
  return $value;
}

sub _canonicalize_catalog_backed_payloads {
  my ($self) = @_;
  my $catalog = GraphQL::Houtou::Runtime::VMProgram::PayloadCatalog->new(
    args_payloads => $self->args_payloads,
    directives_payloads => $self->directives_payloads,
  );
  for my $block (@{ $self->blocks || [] }, ($self->root_block || ())) {
    next if !$block;
    $block->set_program($self) if $block->can('set_program');
    for my $op (@{ $block->ops || [] }) {
      next if !$op;
      my $args_payload = $op->args_payload;
      if (GraphQL::Houtou::Runtime::VMProgram::PayloadCatalog::_payload_present($args_payload)) {
        my $index = $catalog->intern_args_payload($args_payload);
        $op->set_args_payload_index($index);
        $op->set_args_payload(undef);
      }
      my $directives_payload = $op->directives_payload;
      if (GraphQL::Houtou::Runtime::VMProgram::PayloadCatalog::_payload_present($directives_payload)) {
        my $index = $catalog->intern_directives_payload($directives_payload);
        $op->set_directives_payload_index($index);
        $op->set_directives_payload(undef);
      }
    }
  }
  $self->[ARGS_PAYLOADS_SLOT] = $catalog->args_payloads;
  $self->[DIRECTIVES_PAYLOADS_SLOT] = $catalog->directives_payloads;
  $self->[ABSTRACT_CHILD_MAPS_SLOT] = [];
  $self->[NATIVE_COMPACT_STRUCT_SLOT] = undef;
}

1;
