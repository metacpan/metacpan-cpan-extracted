package GraphQL::Houtou::Runtime::VMBlock;

use 5.014;
use strict;
use warnings;
use Scalar::Util qw(refaddr weaken);

use constant {
  NAME_SLOT      => 0,
  TYPE_NAME_SLOT => 1,
  FAMILY_SLOT    => 2,
  OPS_SLOT       => 3,
  PROGRAM_SLOT   => 4,
};

sub new {
  my ($class, %args) = @_;
  return bless [
    $args{name},
    $args{type_name},
    $args{family} || 'OBJECT',
    $args{ops} || [],
    undef,
  ], $class;
}

sub name { return $_[0][NAME_SLOT] }
sub type_name { return $_[0][TYPE_NAME_SLOT] }
sub family { return $_[0][FAMILY_SLOT] }
sub ops { return $_[0][OPS_SLOT] }
sub program { return $_[0][PROGRAM_SLOT] }
sub set_ops { $_[0][OPS_SLOT] = $_[1] || []; return $_[0][OPS_SLOT] }
sub set_program {
  my ($self, $program) = @_;
  $self->[PROGRAM_SLOT] = $program;
  weaken($self->[PROGRAM_SLOT]) if ref($self->[PROGRAM_SLOT]);
  for my $op (@{ $self->ops || [] }) {
    next if !$op || !$op->can('set_block');
    $op->set_block($self);
  }
  return $self->[PROGRAM_SLOT];
}

sub to_struct {
  my ($self) = @_;
  return {
    name => $self->name,
    type_name => $self->type_name,
    family => $self->family,
    ops => [ map { $_->to_struct } @{ $self->ops || [] } ],
  };
}

sub to_native_struct {
  my ($self, $block_index, $payload_catalog) = @_;
  my @slot_table;
  my %slot_index;
  for my $op (@{ $self->ops || [] }) {
    my $slot = $op->bound_slot or next;
    my $id = join("\x1E", refaddr($slot), ($op->result_name // q()));
    next if exists $slot_index{$id};
    $slot_index{$id} = scalar @slot_table;
    my $native_slot = $slot->to_native_struct(include_arg_defs => 1);
    $native_slot->{result_name} = $op->result_name;
    push @slot_table, $native_slot;
  }
  return {
    name => $self->name,
    type_name => $self->type_name,
    family => $self->family,
    family_code => _family_code($self->family),
    slots => \@slot_table,
    ops => [ map { $_->to_native_struct($block_index, \%slot_index, $payload_catalog) } @{ $self->ops || [] } ],
  };
}

sub to_native_compact_struct {
  my ($self, $block_index, $payload_catalog) = @_;
  my @slot_table;
  my %slot_index;
  for my $op (@{ $self->ops || [] }) {
    my $slot = $op->bound_slot or next;
    my $id = join("\x1E", refaddr($slot), ($op->result_name // q()));
    next if exists $slot_index{$id};
    $slot_index{$id} = scalar @slot_table;
    my $native_slot = $slot->to_native_compact_struct(include_arg_defs => 1);
    $native_slot->[1] = ($op->result_name // $native_slot->[1]);
    push @slot_table, $native_slot;
  }
  return [
    $self->name,
    $self->type_name,
    _family_code($self->family),
    \@slot_table,
    [ map { $_->to_native_compact_struct($block_index, \%slot_index, $payload_catalog) } @{ $self->ops || [] } ],
  ];
}

sub _family_code {
  my ($family) = @_;
  return 2 if ($family || q()) eq 'OBJECT';
  return 3 if ($family || q()) eq 'LIST';
  return 4 if ($family || q()) eq 'ABSTRACT';
  return 1;
}

1;
