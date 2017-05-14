#!/usr/bin/perl

#  Node.pm - A node in the expretion tree
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

  Math::Expr::Num - A node in the expretion tree, used as superclass only

=head1 SYNOPSIS

  package Math::Expr::Num;
  require Math::Expr::Node;

  use Math::Expr::Node;
  use vars qw(@ISA);
  @ISA = qw(Math::Expr::Node);


=head1 DESCRIPTION

  Each expretion is represented by a tree where each opperation and variable 
  is a separate node. This class contain the common code for all those noeds.

  It also defines all the common methods used in those node classes and does 
  some typecheckinig for them. Therefor the methodname in the subclasses 
  should start with a '_'-char followed by the actually method name. This 
  method will be called by the acutall method in this class after the 
  typecheking is done.

=cut

package Math::Expr::Node;
use strict;

# Type checking and result caching

sub Subs{
	my ($self, $vars) = @_;
	$vars->isa("Math::Expr::VarSet")|| warn("Bad param vars: $vars");
	$self->_Subs($vars);
}

sub Breakable{shift->_Breakable(@_)}
sub toMathML{shift->_toMathML}

sub Set{
	my ($self, $pos, $val) = @_;

	defined $pos || warn("Bad param pos: $pos");
	$val->isa("Math::Expr::Node") || warn("Bad param val: $val");
	!$self->InTable || warn "Can't edit items in the table";
	
	$self->_Set($pos,$val);
}

sub Match{
  my ($self,$rule,$pos,$pre)= @_;
	my $key=$rule->tostr.'§'.$pos;

	$rule->isa("Math::Expr::Node") || warn "Bad param rule: $rule";
	if (ref $pre) {
		$pre->isa("Math::Expr::VarSet") || warn "Bad param pre: $pre";
		$key.='§'.$pre->tostr;
	}
  elsif(defined  $pre) {
    warn "Bad param pre: $pre";
  }


	if ($self->{'Matches'}{$key}) {return $self->{'Matches'}{$key};}
	$self->{'Matches'}{$key}=$self->_Match($rule,$pos,$pre);
	$self->{'Matches'}{$key};
}

sub SubMatch{
	my ($self, $rule, $mset) = @_;

	$rule->isa("Math::Expr::Node") || warn "Bad param rule: $rule";
	$mset->isa("Math::Expr::MatchSet") || warn "Bad param mset: $mset";

	my $key=$rule->tostr.'§'.$mset->tostr;
	if ($self->{'SubMatches'}{$key}) {return $self->{'SubMatches'}{$key};}
	$self->{'SubMatches'}{$key}=$self->_SubMatch($rule,$mset);
	$self->{'SubMatches'}{$key};
}

sub Copy{shift->_Copy}

# Default actions

sub Simplify {shift->IntoTable;}

sub _Subs {shift;}

sub _Breakable{0;}

sub _Set {
  my ($self, $pos, $val)=@_;

  if ($pos ne "") {warn "Bad pos: $pos"}
  $val;
}

sub _Match {
  my ($self, $rule,$pos,$pri) = @_;
	my $mset=new Math::Expr::MatchSet;

	if (!defined $pri) {$pri=new Math::Expr::VarSet}

	$mset->Set($pos, $pri);
	if (!$self->SubMatch($rule, $mset)) {
		$mset->del($pos);
	}
	$mset;
}

# Table handling
#use MLDBM;
#use Fcntl;
my %table;
#tie %table, 'MLDBM','testmldbm', O_CREAT|O_RDWR, 0640 or die $!;

sub InTable {
	my $self=shift;
	if (defined $self->{'TableKey'}) {return 1} else {return 0}
}

sub IntoTable {
	my $self=shift;

	if ($self->InTable) {return $self;}

	my $key=$self->tostr;
	if (defined $table{$key}) {return $table{$key};}
	
	if ($self->isa("Math::Expr::Opp")) {
		for (my $i=0; $i<=$#{$self->{'Opps'}}; $i++) {
			$self->{'Opps'}[$i]=$self->{'Opps'}[$i]->IntoTable;
		}
	}
	$self->{'TableKey'}=$key;
	$table{$key}=$self;

	$self;
}
1;
