package Lox::AstPrinter;
use strict;
use warnings;
our $VERSION = 0.02;

sub new { bless {}, shift }

sub print_tree {
  my ($self, $stmts) = @_;
  return join "\n", grep { /\S/ } split "\n", $self->parenthesize(@$stmts);
}

sub visit_break_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize('break');
}

sub visit_class_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize('class', $stmt->name, $stmt->methods->@*);
}

sub visit_expression_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize($stmt->expression);
}

sub visit_return_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize('return', $stmt->value);
}

sub visit_print_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize('print', $stmt->expression);
}

sub visit_var_stmt {
  my ($self, $stmt) = @_;
  my @expressions = ('var', $stmt->name, '=');
  push @expressions, $stmt->initializer if $stmt->initializer;
  return $self->parenthesize(@expressions);
}

sub visit_while_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize('while', $stmt->condition, $stmt->body);
}

sub visit_function_stmt {
  my ($self, $stmt) = @_;
  my @expressions = ('fun', $stmt->name, '(');
  push @expressions, $stmt->params->@* if $stmt->params->@*;
  return $self->parenthesize(@expressions, ')', $stmt->body->@*);
}

sub visit_function_expr {
  my ($self, $expr) = @_;
  my @expressions = ('fun', '(');
  push @expressions, $expr->params->@* if $expr->params->@*;
  return $self->parenthesize(@expressions, ')', $expr->body->@*);
}

sub visit_if_stmt {
  my ($self, $stmt) = @_;
  my @expressions = ('if', $stmt->condition, $stmt->then_branch);
  push @expressions, $stmt->else_branch if $stmt->else_branch;
  return $self->parenthesize(@expressions);
}

sub visit_block_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize($stmt->statements->@*);
}

sub visit_unary_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->operator,$expr->right);
}

sub visit_binary_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->left,$expr->operator,$expr->right);
}

sub visit_assign_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->name,'=',$expr->value);
}

sub visit_call_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->callee, $expr->arguments->@*);
}

sub visit_set_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->object, '.', $expr->name, '(', $expr->value, ')');
}

sub visit_this_expr {
  my ($self, $expr) = @_;
  return $expr->keyword->lexeme;
}

sub visit_variable_expr {
  my ($self, $expr) = @_;
  return $expr->name->lexeme;
}

sub visit_get_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->object, '.', $expr->name, '()');
}

sub visit_grouping_expr {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->expression);
}

sub visit_literal_expr {
  my ($self, $expr) = @_;
  return $expr->value;
}

sub visit_logical_expr {
  my ($self, $expr) = @_;
  return $self->visit_binary($expr);
}

sub visit_token {
  my ($self, $token) = @_;
  return $token->lexeme;
}

my $column = 0;
sub parenthesize {
  my ($self, @expr) = @_;
  my $indent =  ' ' x $column // '';
  $column += 2;
  my $values = join ' ', map { ref $_ ? $_->accept($self) : $_ } @expr;
  my $parenthesized = "\n$indent(\n$indent $values\n$indent)";
  $column -= 2;
  return $parenthesized;
}

1;
