#!/usr/bin/perl

#  Var.pm - A perl representation of variables.
#  (c) Copyright 1998 Hakan Ardo <hakan@debian.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 NAME

  Math::Expr::Var - Represents one variable in a parsed expression tree

=head1 SYNOPSIS

  require Math::Expr::Opp;
  require Math::Expr::Var;
  require Math::Expr::Num;
  
  # To represent the expression "x+7":
  $n=new Math::Expr::Opp("+");
  $n->SetOpp(0,new Math::Expr::Var("x"));
  $n->SetOpp(1,new Math::Expr::Num(7));
  print $n->tostr . "\n";


=head1 DESCRIPTION

  Used by the Math::Expr to represent variables.

=head1 METHODS

=cut

package Math::Expr::Var;
require Math::Expr::Node;
use strict;

use Math::Expr::Node;
use vars qw(@ISA);
@ISA = qw(Math::Expr::Node);

=head2 $n=new Math::Expr::Var($name)

  Creates a new representation of the variable named $name.

=cut

sub new {
	my($class, $val) = @_;
	my $self = bless { }, $class;

	($self->{'Val'},$self->{'VarType'})=split(/:/,$val);
  if (!$self->{'VarType'}) {$self->{'VarType'}="Real";}
	$self;
}

=head2 $n->tostr

  Returns the string representation of the variable, that is the 
  variable name.

=cut

sub tostr {
	my $self = shift;
  $self->{'Val'}. ":" . $self->{'VarType'};
}

sub toText {
	my $self = shift;
	$self->{'Val'};
}

=head2 $n->strtype

  Returns the type of the variable.

=cut

sub strtype {
	my $self = shift;
  $self->{'VarType'};
}

=head2 $n->BaseType

  Simply cals strtype, its needed to be compatible with the other 
  elements in the structure.

=cut

sub BaseType {shift->strtype(@_)}

=head2 $n->Match

  Mathces a rule expression with the variable, and returns an array of 
  VarSet objects with this variable name set to the expression if there 
  types match.

=cut

=head2 $n->SubMatch

  Used by upper level Match procedure to match an entire expression.

=cut

sub SubMatch {
	my ($self, $rule, $mset) = @_;

  if ($rule->isa('Math::Expr::Var') && $self->BaseType eq $rule->BaseType) {
		$mset->SetAll($rule->{'Val'},$self);
		return 1;
	}
	return 0;
}

=head2 $n->Subs($vars)

  Returns this variables vaule taken from $vars or a new copy of itselfe 
  if it does not excist.

=cut

sub _Subs {
	my ($self, $vars) = @_;
	my $v=$vars->Get($self->{'Val'});

	if ($v) {return $v} else {return new Math::Expr::Var($self->{'Val'}.":".
																											$self->{'VarType'})}
}

=head2 $n->Copy

Returns a new copy of itself.

=cut

sub _Copy {
	my $self= shift;

	new Math::Expr::Var($self->{'Val'}.":".$self->{'VarType'});
}

sub _toMathML {
	my $self = shift;

  "<mi>".$self->{'Val'}."</mi>";
}

=head1 AUTHOR

  Hakan Ardo <hakan@debian.org>

=head1 SEE ALSO

  L<Math::Expr::Opp>

=cut

1;
