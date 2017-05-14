#!/usr/bin/perl

#  MatchSet.pm - A perl representation of matches in algebraic expretions
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

  Math::Expr::MatchSet - Represents matches in algebraic expretions

=head1 SYNOPSIS

  require Math::Expr::MatchSet;
  $s=new Math::Expr::MatchSet;
  $s->Set($pos,$match);
  $s->Get($pos);

=head1 DESCRIPTION

  Two expretion can be matched in several ways, therefor we need to be 
  able to represent a set of matches keyed by the matchposition (the 
  subexpretion, where the match where found).

=head1 METHODS

=cut

package Math::Expr::MatchSet;
use strict;

=head2 $s=new Math::Expr::MatchSet

  Create a new MatchSet object.

=cut

sub new {bless {}, shift}

sub Copy {
  my $self = shift;
  my $n = new Math::Expr::MatchSet;

  foreach (keys %{$self->{'Matches'}}) {
    $n->Set($_, $self->{'Matches'}{$_}->Copy);
  }
  $n;
}

sub Clear {
  my $self = shift;

  foreach (keys %{$self->{'Matches'}}) {
    delete $self->{'Matches'}{$_};
  }
}

sub AddPos {
  my ($self, $p) = @_;
  my $t={};

  foreach (keys %{$self->{'Matches'}}) {
    $t->{$_.$p}=$self->{'Matches'}{$_};
    delete $self->{'Matches'}{$_};
  }
  $self->{'Matches'}=$t;
}

=head2 $s->Set($pos, $match)

  Sets the match at $pos to $match.

=cut

sub Set {shift->Add(@_)}

=head2 $s->Add($pos, $match)

  Synonyme to Set.

=cut

sub Add {
  my ($self, $pos, $vars) = @_;

	# Parameter sanity checks
	defined $pos || warn "Bad param pos: $pos";
	$vars->isa("Math::Expr::VarSet") || warn "Bad param vars: $vars";

	$self->{'Matches'}{$pos}=$vars;
}

=head2 $s->Insert($mset)

  Inserts all mathes in the MatchSet £mset intho $s.

=cut

sub Insert {
	my ($self, $mset) = @_;

	# Parameter sanity checks
	$mset->isa("Math::Expr::MatchSet") || warn "Bad param mset: $mset";

	foreach (keys %{$mset->{'Matches'}}) {
		if (defined $self->{'Matches'}{$_}) {warn "Overwriting previous settings";}
		$self->{'Matches'}{$_}=$mset->{'Matches'}{$_}
	}
}

sub del {
	my ($self, $pos) = @_;

	delete $self->{'Matches'}{$pos};
}



=head2 $s->SetAll($var, $obj)

  Sets the variable $var to $obj in all mathces in this set, and removes 
  all matches that already had a diffrent value for the variable $var.

=cut

sub SetAll {
	my ($self, $var, $obj) = @_;
	my $allgone=1;
	

	# Parameter sanity checks
	defined $var || warn "Bad param var: $var\n";
	$obj->isa("Math::Expr::Opp") ||
	$obj->isa("Math::Expr::Num") ||
	$obj->isa("Math::Expr::Var") || warn "Bad param obj: $obj\n";

	foreach (keys %{$self->{'Matches'}}) {
		if (!$self->{'Matches'}{$_}->Set($var,$obj)) {
			delete $self->{'Matches'}{$_};
		} else {
			$allgone=0;
		}
	}

	if ($allgone) {
		return 0;
	} else {
		return 1;
	}
}

=head2 $s->tostr

  Generates a string representation of the MatchSet, used for debugging.

=cut

sub tostr {
	my $self = shift;
	my $str="";


	foreach (keys %{$self->{'Matches'}}) {
		$str .= $_ . ":\n" . $self->{'Matches'}{$_}->tostr . "\n\n";
	}

	$str;
}

=head2 $s->Get($pos)

  Returns the Match at possition $pos.

=cut

sub Get {
	my ($self, $var) = @_;

	$self->{'Matches'}{$var};
}

=head2 $s->Keys

  Returns the positions at which there excists a match.

=cut

sub Keys {
	my ($self) = @_;
	
	keys %{$self->{'Matches'}};
}

1;
