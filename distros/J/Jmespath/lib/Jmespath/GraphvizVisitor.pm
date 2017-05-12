package Jmespath::GraphvizVisitor;
use parent 'Jmespath::Visitor';
use strict;
use warnings;

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new( $expected, $actual, $name );
  @{$self->{_lines}} = [];
  $self->{_count} = 1;
  return $self;
}

sub visit {
#  my $self = shift; my $node = shift; my $args = @_;
  my ($self, $node, @args) = @_;
  push 'digraph AST {' ,@{$self->{_lines}};
  my $current = $node->{type} . $self->{_count};
  $self->{_count} += 1;
  $self->_visit($node, $current);
  push '}', @{$self->{_lines}};
  return;
}

# recursive function to iterate through all child nodes to produce
# relationship graph lines
sub _visit {
  my ($self, $node, $current) = @_;
  my $line = $current . ' [label="' . $node->{type} . '(' . $node->{value} . ')"]';
  push $line, @{$self->{_lines}};
  foreach my $child (@{$node->{children}}) {
    my $child_name = $child->{type} . $self->{_count};
    $self->{_count} += 1;
    push '  ' . $current . ' -> ' $child_name, @{$self->{_lines}};
    $self->_visit($child, $child_name);
  }
  return;
}

1;
