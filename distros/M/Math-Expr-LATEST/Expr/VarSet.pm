#!/usr/bin/perl

#  VarSet.pm - Represents a set of variables and there values
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

  Math::Expr::VarSet - Represents a set of variables and there values

=head1 SYNOPSIS

  require Math::Expr::VarSet;
  $s=new Math::Expr::VarSet;
  $s->Set('a', 7);
  $s->Get('a');

=head1 DESCRIPTION

  Used to represent variables with values and substitutions.

=head1 METHODS

=cut

package Math::Expr::VarSet;
use strict;

=head2 $s=new Math::Expr::VarSet

  Create a new VarSet object.

=cut

sub new {bless {}, shift}

=head2 $s->Set($var, $val)

  Sets $var to $val. Returns 1 if the $var was already set to $val ore did 
  not have a value previously, otherwise 0.

=cut

sub Set {
	my ($self, $var, $val) = @_;
	my $ok=1;

	# Parameter sanity checks
	defined $var || warn "Bad param var: $var";
	$val->isa("Math::Expr::Opp") ||
	$val->isa("Math::Expr::Num") ||
	$val->isa("Math::Expr::Var") || warn "Bad param val: $val";

	if (defined $self->{'Vars'}{$var} && 
			$self->{'Vars'}{$var}->tostr ne $val->tostr) {$ok=0;}
	$self->{'Vars'}{$var}=$val;
	$ok;
}

sub Copy {
  my $self=shift;
  my $n=new Math::Expr::VarSet;

  foreach (keys %{$self->{'Vars'}}) {
    $n->Set($_, $self->{'Vars'}{$_});
  } 
  $n;
}

=head2 $s->Insert($set)

  Inserts all variables from $set into this object

=cut

sub Insert {
	my ($self, $set) = @_;
	my $ok=1;

	# Parameter sanity checks
	$set->isa("Math::Expr::VarSet") || warn "Bad param set: $set\n";

	foreach (keys %{$set->{'Vars'}}) {
		if (defined $self->{'Vars'}{$_}) {$ok=0;}
		$self->{'Vars'}{$_}=$set->{'Vars'}{$_};
	}
	$ok;
}

=head2 $s->tostr

  Returns a stringrepresentation of the set, usefull for debugging.

=cut

sub tostr {
	my $self = shift;
	my $str="";

	foreach (keys %{$self->{'Vars'}}) {
		$str .= $_ . "=" . $self->{'Vars'}{$_}->tostr . "\n";
	}

	$str;
}

=head2 $s->Get($var)

  Returns the value of $var.

=cut

sub Get {
	my ($self, $var) = @_;

	$self->{'Vars'}{$var};
}
1;
