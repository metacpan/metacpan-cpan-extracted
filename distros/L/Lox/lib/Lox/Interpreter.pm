package Lox::Interpreter;
use feature 'say';
use strict;
use warnings;
use Lox::Bool;
use Lox::Callable;
use Lox::Environment;
use Lox::Function;
use Lox::Class;
use Lox::Nil;
use Lox::TokenType;
our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  $args //= {};
  my $globals = Lox::Environment->new({});
  my $interpreter = bless {
    environment => $globals,
    globals     => $globals,
    locals      => {},
    %$args,
  }, $class;
  $interpreter->globals->define('clock', Lox::Callable->new({
    arity => 0,
    call  => sub { time },
  }));

  return $interpreter;
}

sub environment :lvalue { $_[0]->{environment} }
sub globals { $_[0]->{globals} }
sub locals { $_[0]->{locals} }

sub interpret {
  my ($self, $stmts) = @_;
  for (@$stmts) {
    $self->execute($_);
  }
}

sub execute {
  my ($self, $stmt) = @_;
  $stmt->accept($self) unless $self->{breaking};
}

sub resolve {
  my ($self, $expr, $depth) = @_;
  $self->locals->{"$expr"} = $depth;
}

sub visit_break_stmt {
  my ($self, $stmt) = @_;
  $self->{breaking}++;
  return undef;
}

sub visit_class_stmt {
  my ($self, $stmt) = @_;
  my $superclass = undef;
  if (my $sc = $stmt->superclass) {
    $superclass = $self->evaluate($sc);
    unless (ref $superclass eq 'Lox::Class') {
      Lox::runtime_error($sc->name, 'Superclass must be a class');
    }
  }
  $self->environment->define($stmt->name->lexeme, undef);

  if ($superclass) {
    $self->environment = Lox::Environment->new({ enclosing => $self->environment });
    $self->environment->define('super', $superclass);
  }

  my %methods;
  for my $method ($stmt->methods->@*) {
    my $function = Lox::Function->new({
      is_initializer => $method->name->lexeme eq 'init',
      declaration    => $method,
      closure        => $self->environment,
    });
    $methods{$method->name->lexeme} = $function;
  }
  my $klass = Lox::Class->new({
      superclass => $superclass,
      methods    => \%methods,
      name       => $stmt->name->lexeme,
  });

  if ($superclass) {
    $self->environment = $self->environment->enclosing;
  }

  $self->environment->assign($stmt->name, $klass);
  return undef;
}

sub visit_expression_stmt {
  my ($self, $stmt) = @_;
  $self->evaluate($stmt->expression);
  return undef;
}

sub visit_if_stmt {
  my ($self, $stmt) = @_;
  if ($self->is_truthy($self->evaluate($stmt->condition))) {
    $self->execute($stmt->then_branch);
  }
  elsif ($stmt->else_branch) {
    $self->execute($stmt->else_branch);
  }
}

sub visit_function_stmt {
  my ($self, $stmt) = @_;
  my $function = Lox::Function->new({
    declaration => $stmt,
    closure => $self->environment,
  });
  $self->environment->define($stmt->name->lexeme, $function);
  return undef;
}

sub visit_function_expr {
  my ($self, $expr) = @_;
  return Lox::Function->new({
    declaration => $expr,
    closure => $self->environment,
  });
}

sub visit_logical_expr {
  my ($self, $expr) = @_;
  my $left = $self->evaluate($expr->left);
  if ($expr->operator->type == OR) {
    return $left if $self->is_truthy($left);
  }
  else {
    return $left if !$self->is_truthy($left);
  }

  return $self->evaluate($expr->right);
}

sub visit_set_expr {
  my ($self, $expr) = @_;
  my $object = $self->evaluate($expr->object);
  if (ref $object ne 'Lox::Instance') {
    Lox::runtime_error($expr->name, "Only instances have fields");
  }

  my $value = $self->evaluate($expr->value);
  $object->set($expr->name, $value);
  return $value
}

sub visit_super_expr {
  my ($self, $expr) = @_;
  my $distance = $self->locals->{"$expr"};
  my $superclass = $self->environment->get_at($distance, 'super');
  my $object = $self->environment->get_at($distance - 1, 'this');
  my $method = $superclass->find_method($expr->method->lexeme);
  unless ($method) {
    Lox::runtime_error($expr->method,
      sprintf 'Undefined property \'%s\'', $expr->method->lexeme);
  }
  return $method->bind($object);
}

sub visit_this_expr {
  my ($self, $expr) = @_;
  return $self->look_up_variable($expr);
}

sub visit_print_stmt {
  my ($self, $stmt) = @_;
  my $value = $self->evaluate($stmt->expression);
  say $self->stringify($value);
  return undef;
}

sub visit_return_stmt {
  my ($self, $stmt) = @_;
  if ($stmt->value) {
    $self->{returning} = $self->evaluate($stmt->value);
  }
  die "return\n";
  return undef;
}

sub visit_var_stmt {
  my ($self, $stmt) = @_;
  my $value = undef;
  if ($stmt->initializer) {
    $value = $self->evaluate($stmt->initializer);
  }
  $self->environment->define($stmt->name->{lexeme}, $value);
  return undef;
}

sub visit_while_stmt {
  my ($self, $stmt) = @_;
  while ($self->is_truthy($self->evaluate($stmt->condition))) {
    $self->execute($stmt->body);
    last if $self->{breaking};
  }
  return undef $self->{breaking};
}

sub visit_block_stmt {
  my ($self, $stmt) = @_;
  $self->execute_block(
    $stmt->statements,
    Lox::Environment->new({ enclosing => $self->environment }));

  return undef;
}

sub execute_block {
  my ($self, $statements, $environment) = @_;
  my $prev_environment = $self->environment;
  $self->environment = $environment;
  my $error;
  for my $stmt (@$statements) {
    eval { $self->execute($stmt) }; # so we can reset the env
    if ($error = $@) {
      last;
    }
  }
  $self->environment = $prev_environment;
  die $error if $error;
  return undef;
}

sub visit_literal_expr {
  my ($self, $expr) = @_;
  return $expr->value;
}

sub visit_call_expr {
  my ($self, $expr) = @_;
  my $callee = $self->evaluate($expr->callee);
  my @args;
  for my $arg ($expr->arguments->@*) {
    push @args, $self->evaluate($arg);
  }
  unless (ref $callee && $callee->isa('Lox::Callable')) {
    Lox::runtime_error($expr->paren, 'Can only call functions and classes');
  }

  if (@args!= $callee->arity) {
    Lox::runtime_error($expr->paren,
      sprintf 'Expected %d arguments but got %s',$callee->arity,scalar @args);
  }
  return $callee->call($self, \@args) // $Nil;
}

sub visit_get_expr {
  my ($self, $expr) = @_;
  my $object = $self->evaluate($expr->object);

  if (ref $object eq 'Lox::Instance') {
    return $object->get($expr->name);
  }
  Lox::runtime_error($expr->name, 'Only instances have properties');
}

sub visit_grouping_expr {
  my ($self, $expr) = @_;
  return $self->evaluate($expr->expression);
}

sub visit_unary_expr {
  my ($self, $expr) = @_;
  my $right = $self->evaluate($expr->right);

  if ($expr->operator->{type} == MINUS) {
    # numbers are not objects
    Lox::runtime_error($expr->operator, 'Operand must be a number')
      if ref $right;
    return -$right;
  }
  else {
    return !($self->is_truthy($right) ? $True : $False);
  }
}

sub visit_assign_expr {
  my ($self, $expr) = @_;
  my $value = $self->evaluate($expr->value);
  my $distance = $self->locals->{"$expr"};
  if (defined $distance) {
    $self->environment->assign_at($distance, $expr->name, $value);
  }
  else {
    $self->globals->assign($expr->name, $value);
  }
  return $value;
}

sub visit_variable_expr {
  my ($self, $expr) = @_;
  return $self->look_up_variable($expr);
}

sub look_up_variable {
  my ($self, $expr) = @_;
  my $distance = $self->locals->{"$expr"};
  return defined $distance
    ? $self->environment->get_at($distance, $expr->name->lexeme)
    : $self->globals->get($expr->name);
}

sub visit_binary_expr {
  my ($self, $expr) = @_;
  my $left = $self->evaluate($expr->left);
  my $right = $self->evaluate($expr->right);

  my $type = $expr->operator->{type};
  if ($type == EQUAL_EQUAL) {
    return $self->are_equal($left, $right) ? $True : $False;
  }
  elsif ($type == BANG_EQUAL) {
    return !$self->are_equal($left, $right) ? $True : $False;
  }
  elsif ($type == GREATER) {
    # numbers are not objects
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $left > $right ? $True : $False;
  }
  elsif ($type == GREATER_EQUAL) {
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $left >= $right ? $True : $False;
  }
  elsif ($type == LESS) {
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $left < $right ? $True : $False;
  }
  elsif ($type == LESS_EQUAL) {
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $left <= $right ? $True : $False;
  }
  elsif ($type == MINUS) {
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $left - $right;
  }
  elsif ($type == PLUS) {
    if (ref $left || ref $right) {
      if (ref $left eq ref $right) {
        if (ref $left eq 'Lox::String') {
          return Lox::String->new("$left" . "$right");
        }
      }
      Lox::runtime_error(
        $expr->operator, 'Operands must be two numbers or two strings');
    }
    return $left + $right; # Lox numbers are the only non-object values
  }
  elsif ($type == SLASH) {
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $right ? $left / $right : 'NaN';
  }
  elsif ($type == STAR) {
    Lox::runtime_error($expr->operator, 'Operands must be two numbers')
      if ref $left || ref $right;
    return $left * $right;
  }
}

sub evaluate {
  my ($self, $expr) = @_;
  return $expr->accept($self);
}

sub is_truthy {
  my ($self, $value) = @_;
  return !!$value if ref $value;
  return 1;
}

sub are_equal {
  my ($self, $left, $right) = @_;
  if (my $ltype = ref $left) {
    if ($ltype eq ref $right) {
      return "$left" eq "$right";
    }
    return undef;
  }
  elsif (ref $right) {
    return undef;
  }
  else {
    return $left == $right;
  }
}

sub stringify {
  my ($self, $object) = @_;
  return "$object";
}

1;
