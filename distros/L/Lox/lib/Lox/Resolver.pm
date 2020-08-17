package Lox::Resolver;
use strict;
use warnings;

BEGIN {
  my @constants = qw(CLASS FUNCTION INITIALIZER METHOD NONE SUBCLASS);
  my %constant_values = map { $constants[$_] => $_ } 0..$#constants;
  require constant;
  constant->import(\%constant_values);
}

our $VERSION = 0.02;

sub new {
  my ($class, $interpreter) = @_;
  return bless {
    current_function => NONE,
    current_class    => NONE,
    interpreter      => $interpreter,
    scopes           => [],
  }, $class;
}

sub current_function :lvalue { $_[0]->{current_function} }
sub current_class :lvalue { $_[0]->{current_class} }
sub interpreter { $_[0]->{interpreter} }
sub scopes { $_[0]->{scopes} }

sub run {
  my ($self, $stmts) = @_;
  $self->resolve($stmts);
}

sub visit_block_stmt {
  my ($self, $stmt) = @_;
  $self->begin_scope;
  $self->resolve($stmt->statements);
  $self->end_scope;
  return undef;
}

sub visit_break_stmt {
  my ($self, $stmt) = @_;
  return undef;
}

sub visit_class_stmt {
  my ($self, $stmt) = @_;
  my $enclosing_class = $self->current_class;
  $self->current_class = CLASS;
  $self->declare($stmt->name);
  $self->define($stmt->name);

  if (my $sc = $stmt->superclass) {
    if($stmt->name->lexeme eq $sc->name->lexeme) {
      Lox::error($sc->name, 'A class cannot inherit from itself');
    }
    $self->current_class = SUBCLASS;
    $self->resolve($sc);
    $self->begin_scope();
    $self->scopes->[-1]{super} = 1;
  }

  $self->begin_scope;
  $self->scopes->[-1]->{this} = 1;
  foreach my $method ($stmt->methods->@*) {
    my $declaration = $method->name->lexeme eq 'init' ? INITIALIZER : METHOD;
    $self->resolve_function($method, $declaration);
  }
  $self->end_scope;
  $self->end_scope if $stmt->superclass;
  $self->current_class = $enclosing_class;
  return undef;
}

sub visit_expression_stmt {
  my ($self, $stmt) = @_;
  $self->resolve($stmt->expression);
  return undef;
}

sub visit_if_stmt {
  my ($self, $stmt) = @_;
  $self->resolve($stmt->condition);
  $self->resolve($stmt->then_branch);
  if ($stmt->else_branch) {
    $self->resolve($stmt->else_branch);
  }
  return undef;
}

sub visit_print_stmt {
  my ($self, $stmt) = @_;
  $self->resolve($stmt->expression);
  return undef;
}

sub visit_return_stmt {
  my ($self, $stmt) = @_;
  if ($stmt->value) {
    if ($self->current_function == INITIALIZER) {
      Lox::error($stmt->keyword, 'Cannot return a value from an initializer');
    }
    $self->resolve($stmt->value);
  }
  return undef;
}

sub visit_function_stmt {
  my ($self, $stmt) = @_;
  $self->declare($stmt->name);
  $self->define($stmt->name);
  $self->resolve_function($stmt, FUNCTION);
  return undef;
}

sub visit_get_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->object);
  return undef;
}

sub resolve {
  my ($self, $stmt_or_expr) = @_;
  if (ref $stmt_or_expr ne 'ARRAY') {
    $stmt_or_expr = [$stmt_or_expr];
  }
  $_->accept($self) for (@$stmt_or_expr);
  return undef;
}

sub resolve_function {
  my ($self, $stmt, $type) = @_;
  my $enclosing_function = $self->current_function;
  $self->current_function = $type;
  $self->begin_scope;
  for my $param ($stmt->params->@*) {
    $self->declare($param);
    $self->define($param);
  }
  $self->resolve($stmt->body);
  $self->end_scope;
  $self->current_function = $enclosing_function;
}

sub begin_scope {
  my $self = shift;
  push $self->scopes->@*, {};
  return undef;
}

sub end_scope {
  my $self = shift;
  pop $self->scopes->@*;
  return undef;
}

sub visit_var_stmt {
  my ($self, $stmt) = @_;
  $self->declare($stmt->name);
  if (my $init = $stmt->initializer) {
    $self->resolve($init);
  }
  $self->define($stmt->name);
  return undef;
}

sub visit_while_stmt {
  my ($self, $stmt) = @_;
  $self->resolve($stmt->condition);
  $self->resolve($stmt->body);
  return undef;
}

sub visit_assign_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->value);
  $self->resolve_local($expr, $expr->name);
  return undef;
}

sub visit_binary_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->left);
  $self->resolve($expr->right);
  return undef;
}

sub visit_call_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->callee);
  for my $argument ($expr->arguments->@*) {
    $self->resolve($argument);
  }
  return undef;
}

sub visit_function_expr {
  my ($self, $expr) = @_;
  $self->resolve_function($expr, FUNCTION);
  return undef;
}

sub visit_grouping_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->expression);
  return undef;
}

sub visit_literal_expr { undef }

sub visit_logical_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->left);
  $self->resolve($expr->right);
  return undef;
}

sub visit_set_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->value);
  $self->resolve($expr->object);
  return undef;
}

sub visit_unary_expr {
  my ($self, $expr) = @_;
  $self->resolve($expr->right);
  return undef;
}

sub declare {
  my ($self, $name_token) = @_;
  return undef unless $self->scopes->@*;

  my $scope = $self->scopes->[-1];
  if (exists $scope->{$name_token->lexeme}) {
    Lox::error($name_token,
        'Variable with this name already declared in this scope');
  }

  return $self->scopes->[-1]{$name_token->lexeme} = 0;
}

sub define {
  my ($self, $name_token) = @_;
  return undef unless $self->scopes->@*;
  return $self->scopes->[-1]{$name_token->lexeme} = 1;
}

sub visit_super_expr {
  my ($self, $expr) = @_;
  if ($self->current_class == NONE) {
    Lox::error($expr->keyword, 'Cannot use \'super\' outside of a class');
  }
  elsif ($self->current_class != SUBCLASS) {
    Lox::error($expr->keyword,
      'Cannot use \'super\' in a class with no superclass');
  }
  $self->resolve_local($expr, $expr->keyword);
  return undef;
}

sub visit_this_expr {
  my ($self, $expr) = @_;
  if ($self->current_class == NONE) {
    Lox::error($expr->keyword, 'Cannot use \'this\' outside of a class');
  }
  $self->resolve_local($expr, $expr->keyword);
  return undef;
}

sub visit_variable_expr {
  my ($self, $expr) = @_;
  return undef unless $self->scopes->@*;

  my $value = $self->scopes->[-1]{$expr->name->lexeme};
  if (defined $value && $value == 0) {
    Lox::error($expr->name,
      'Cannot read local variable in its own initializer');
  }
  $self->resolve_local($expr, $expr->name);
  return undef;
}

sub resolve_local {
  my ($self, $expr, $name_token) = @_;
  for (my $i = $#{$self->scopes}; $i >= 0; $i--) {
    if (exists $self->scopes->[$i]{$name_token->lexeme}) {
      $self->interpreter->resolve($expr, $#{$self->scopes} - $i);
      return;
    }
  }
  # not found assume it is global
}

1;
