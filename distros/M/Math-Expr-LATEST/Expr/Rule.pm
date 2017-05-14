#!/usr/bin/perl

#  Rule.pm - Represents a agebraic rule 
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

  Math::Expr::Var - Represents a agebraic rule 

=head1 SYNOPSIS

  reuire Math::Expr::Var;
  reuire Math::Expr;
	
	$r=new Math::Expr::Var($from, $to);
  @res=$r->Apply($expr)

=head1 DESCRIPTION 

  This will create a rule that converts the expression $from to $to,
  and then apply that rule to $expr. $from, $to, $expr are all
  Math::Expr::Opp structures that should be Simplified to work ok.

  The result is a array @res of Math::Expr::Opp objects which should 
  contain the results of applying the rule once on $expr in all 
  possible ways. They are all simplified, and duplicaions are removed.

=head1 METHODS

=cut

package Math::Expr::Rule;
use strict;

=head2 	$r=new Math::Expr::Var($from, $to);

  Makes a rule converting the Math::Expr::Opp structur $from into $to.

=cut

sub new {
	my($class, $from, $to) = @_;
	my $self = bless { }, $class;

	$self->{'From'}=$from;
	$self->{'To'}=$to;

	$self;
}

sub Apply {
	my ($self, $expr, $pre)=@_;
	my $e=$expr;
	my $ms=$e->Match($self->{'From'}, "", $pre);
	my ($n,$nh);
	my @res;
	my ($ok, $t);
	my $id=[];

	foreach ($ms->Keys) {
		$n=$e->Copy;
		$nh=$self->{'To'}->Subs($ms->Get($_));
		$n=$n->Set($_,$nh);
		$n->Simplify;

		$ok=1;
		foreach $t (@res) {
			if ($t->tostr eq $n->tostr) {$ok=0; last;}
		}
		if ($ok) {
			push @res,$n;
			push @{$id}, $_;
				
		}
	}
	$self->{'Id'}=$id;
	@res;
}

sub ApplyAt {
	my ($self, $e, $pos, $pre) = @_;
	my $i;
	my @r=$self->Apply($e, $pre);

	for ($i=0; $i<=$#r; $i++) {
		if ($self->{'Id'}[$i] eq $pos) {
			return $r[$i];
		}
	}
	warn "Unable to apply at that position";
	return 0;
}

sub GetId {
	my $self=shift;
	$self->{'Id'};
}

1;

