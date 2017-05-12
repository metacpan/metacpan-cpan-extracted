package Jmespath::Ast;
use strict;
use warnings;


sub comparator {
  my ($class, $name, $first, $second) = @_;
  return { type => 'comparator',
           children => [$first, $second],
           value => $name,
         };
}

sub current_node {
  return { type => 'current', children => [] };
}

sub expref {
  my ( $class, $expression ) = @_;
  return { type => 'expref', 'children' => [$expression] };
}

sub function_expression {
  my ($class, $name, $args) = @_;
  return { type => 'function_expression', children => $args, value => $name };
}

sub field {
  my ($class, $name) = @_;
  return { type => 'field', children => [], value => $name };
}

sub filter_projection {
  my ($class, $left, $right, $comp) = @_;
  return { type => 'filter_projection', children => [ $left, $right, $comp ] };
}

sub flatten {
  my ($class, $node) = @_;
  return { type => 'flatten', children => [$node] };
}

sub identity {
  return { type => 'identity', 'children' => [] };
}

sub index_of {
  my ($class, $index) = @_;
  return { type => 'index', value => $index, children => [] };
}

sub index_expression {
  my ($class, $children) = @_;
  return { type => 'index_expression', children => $children };
}

sub key_val_pair {
  my ($class, $key_name, $node) = @_;
  return { type => 'key_val_pair', children => [$node], value => $key_name };
}

sub literal {
  my ($class, $literal_value) = @_;
  return { type => 'literal', value => $literal_value, children => [] };
}

sub multi_select_hash {
  my ($class, $nodes) = @_;
  return {type => 'multi_select_hash', children => $nodes };
}

sub multi_select_list {
  my ($class, $nodes) = @_;
  return { type => 'multi_select_list', children => $nodes };
}

sub or_expression {
  my ($class, $left, $right) = @_;
  return { type => 'or_expression', children => [$left, $right]};
}

sub and_expression {
  my ($class, $left, $right) = @_;
  return { type => 'and_expression', children => [$left, $right]};
}

sub not_expression {
  my ($class, $expr) = @_;
  return { type => 'not_expression', children => [$expr] };
}

sub pipe_oper {
  my ($class, $left, $right) = @_;
  return { type => 'pipe', children => [$left, $right]};
}

sub projection {
  my ($class, $left, $right) = @_;
  return { type => 'projection', children => [$left, $right] };
}

sub subexpression {
  my ($class, $children) = @_;
  return { type => 'subexpression', children => $children};
}

sub slice {
  my ($class, $start, $end, $step) = @_;
  return { type => 'slice', children => [$start, $end, $step]};
}

sub value_projection {
  my ($class, $left, $right) = @_;
  return { type => 'value_projection', children => [$left, $right] };
}

1;
