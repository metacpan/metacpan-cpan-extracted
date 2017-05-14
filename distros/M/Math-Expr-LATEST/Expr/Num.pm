#!/usr/bin/perl

#  Num.pm - A perl representation of numbers
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

  Math::Expr::Num - Represents one number in a parsed expression tree

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

  Used by the Math::Expr to represent numbers.

=head1 METHODS

=cut

package Math::Expr::Num;
use strict;

use Math::Expr::Node;
use vars qw(@ISA);
@ISA = qw(Math::Expr::Node);

=head2 $n=new Math::Expr::Num($num)

  Creates a new representation of the number $num.

=cut

sub new {
	my($class, $val) = @_;
	my $self = bless { }, $class;

	$self->{'Val'}=$val;
	$self;
}

=head2 $n->tostr

  Returns the string representation of the number which in perl is
  the same as the number itsefle

=cut
sub tostr {
	my $self = shift;
  $self->{'Val'};
}

sub toText {shift->tostr}

sub strtype {
  "Real";
}

sub BaseType {shift->strtype(@_)}

sub _toMathML {
  my $self = shift;
  "<mn>".$self->{'Val'}."</mn>";
}


sub SubMatch {
	my ($self, $rule, $mset) = @_;

  if ($rule->isa('Math::Expr::Var') && $self->BaseType eq $rule->BaseType) {
		$mset->SetAll($rule->{'Val'},$self);
		return 1;
	}
  if ($rule->isa('Math::Expr::Num') && $self->BaseType eq $rule->BaseType) {
	return 1;
  }
	return 0;
}

=head2 $n->Copy

Returns a new copy of itself.

=cut

sub _Copy {
	my $self= shift;

	new Math::Expr::Num($self->{'Val'});
}


=head1 AUTHOR

  Hakan Ardo <hakan@debian.org>

=head1 SEE ALSO

  L<Math::Expr::Opp>

=cut

1;
