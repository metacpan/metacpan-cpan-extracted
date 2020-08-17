use strict;
use warnings;
our $VERSION = 0.02;

package Lox::Stmt;
sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

package Lox::Stmt::Break;
use parent -norequire, 'Lox::Stmt';

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_break_stmt($self);
}

package Lox::Stmt::Block;
use parent -norequire, 'Lox::Stmt';
sub statements { $_[0]->{statements} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_block_stmt($self);
}

package Lox::Stmt::Class;
use parent -norequire, 'Lox::Stmt';
sub name       { $_[0]->{name} }
sub methods    { $_[0]->{methods} }
sub superclass { $_[0]->{superclass} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_class_stmt($self);
}

package Lox::Stmt::Expression;
use parent -norequire, 'Lox::Stmt';
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_expression_stmt($self);
}

package Lox::Stmt::Function;
use parent -norequire, 'Lox::Stmt';
sub name   { $_[0]->{name} }
sub params { $_[0]->{params} }
sub body   { $_[0]->{body} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_function_stmt($self);
}

package Lox::Stmt::If;
use parent -norequire, 'Lox::Stmt';
sub condition   { $_[0]->{condition} }
sub then_branch { $_[0]->{then_branch} }
sub else_branch { $_[0]->{else_branch} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_if_stmt($self);
}

package Lox::Stmt::Print;
use parent -norequire, 'Lox::Stmt';
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_print_stmt($self);
}

package Lox::Stmt::Return;
use parent -norequire, 'Lox::Stmt';
sub keyword { $_[0]->{keyword} }
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_return_stmt($self);
}

package Lox::Stmt::Var;
use parent -norequire, 'Lox::Stmt';
sub name { $_[0]->{name} }
sub initializer { $_[0]->{initializer} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_var_stmt($self);
}

package Lox::Stmt::While;
use parent -norequire, 'Lox::Stmt';
sub condition   { $_[0]->{condition} }
sub body { $_[0]->{body} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_while_stmt($self);
}

1;
