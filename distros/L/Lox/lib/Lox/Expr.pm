use strict;
use warnings;
package Lox::Expr;
our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

package Lox::Expr::Variable;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;

sub name { $_[0]->{name} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_variable_expr($self);
}

package Lox::Expr::Unary;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_unary_expr($self);
}

package Lox::Expr::Assign;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub name { $_[0]->{name} }
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_assign_expr($self);
}

package Lox::Expr::Binary;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub left { $_[0]->{left} }
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_binary_expr($self);
}

package Lox::Expr::Call;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub arguments { $_[0]->{arguments} }
sub callee { $_[0]->{callee} }
sub paren { $_[0]->{paren} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_call_expr($self);
}

package Lox::Expr::Get;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub name { $_[0]->{name} }
sub object { $_[0]->{object} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_get_expr($self);
}

package Lox::Expr::Function;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub params { $_[0]->{params} }
sub body   { $_[0]->{body} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_function_expr($self);
}

package Lox::Expr::Grouping;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_grouping_expr($self);
}

package Lox::Expr::Literal;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_literal_expr($self);
}

package Lox::Expr::Logical;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub left { $_[0]->{left} }
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_logical_expr($self);
}

package Lox::Expr::Set;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub name { $_[0]->{name} }
sub object { $_[0]->{object} }
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_set_expr($self);
}

package Lox::Expr::Super;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub keyword { $_[0]->{keyword} }
sub method  { $_[0]->{method} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_super_expr($self);
}

package Lox::Expr::This;
use parent -norequire, 'Lox::Expr';
our $VERSION = 0.02;
sub keyword { $_[0]->{keyword} }
sub name { $_[0]->keyword }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_this_expr($self);
}

1;
