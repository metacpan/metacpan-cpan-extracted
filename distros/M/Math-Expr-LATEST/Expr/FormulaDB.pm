#!/usr/bin/perl 

#  FormulaDB.pm - A db of formulas and there properties
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

  Math::Expr::FormulaDB - A db of formulas and there properties

=head1 SYNOPSIS

  require Math::Expr::FormulaDB;
  $db=new Math::Expr::FormulaDB($file);

=cut

package Math::Expr::FormulaDB;
use strict;
use Math::Expr;

require Math::Expr::Rule;

sub new {
  my $self = bless {}, shift;
  $self->Load(shift);
	my $db;
	my ($vl, $hl);

	foreach ($self->Keys) {
    $db=$self->Get($_);
		$vl=Parse($db->{'vl'}); $vl=$vl->Simplify;
		$hl=Parse($db->{'hl'}); $hl=$hl->Simplify;

		$db->{'for'}= new Math::Expr::Rule($vl, $hl);
		$db->{'back'}= new Math::Expr::Rule($hl, $vl);
	}

  $self;
}

sub Load {
  my ($self, $file) = @_;

  if (-f $file) {$self->LoadFile($file);}
  if (-d $file) {$self->LoadDir($file);}
}
sub LoadFile {
  my ($self, $file) = @_;
  my %t;

  open (F, "<$file");
  while (<F>) {
    if (/^([^:]+)\s*:\s*(.*)$/) {
			my  $a=lc($1);
			if (defined $t{$a}) {$t{$a}.="\n$2";} else {$t{$a}=$2;}
		}
    if (/^\s*$/ || eof F) {
      if ($t{'name'}) {
				my $t=$t{'name'};
				delete $t{'name'};

				foreach (keys %t) {
					$self->{'opps'}{$t}{$_}=$t{$_};
          delete $t{$_};
				}
      }
    }
  }
}

sub LoadDir {
  my ($self, $dir) = @_;

  foreach (split(/\n/s, `find $dir -type f`)) {
    next if (/~$/);
    $self->LoadFile($_);
  }
}

sub Keys {
	my $self = shift;
	
	keys %{$self->{'opps'}};
}

sub Get {
	my ($self, $a) = @_;

	$self->{'opps'}{$a};
}

sub Find {
  my ($self, $e, $t) = @_;
  my $db;
  my ($n, $d, $i);
  my (@res, $id);
  my $r;

	if (!defined $t) {$t=0;}

  foreach $n ($self->Keys) {
    $db=$self->Get($n);
		foreach $d ("for", "back") {
			if (!$t || !$db->{'triv'.$d}) {
				@res=$db->{$d}->Apply($e);
				$id=$db->{$d}->GetId;
				for ($i=0; $i<=$#res; $i++) {
					$r->{"$n-$d-".$id->[$i]}=$res[$i];
				}
			}
		}
  }
  $r;
}

sub ApplyProof {
	my ($self, $key) = @_;
	my %vars;
	my $db=$self->Get($key);
	my $res="";
	my $prev="";

	if (defined $db->{'b'}) {
		$vars{'vl'}=Parse($db->{'vl'}); 	
		$vars{'hl'}=Parse($db->{'hl'}); 	

		$res.=$vars{'hl'}->toText;
		$vars{'hl'}->Simplify;
		$res.=" <=> ".$vars{'hl'}->toText."\n";

		$res.=$vars{'vl'}->toText;
		$vars{'vl'}->Simplify;
		$res.=" <=> " . $vars{'vl'}->toText;
		$prev="vl";

		foreach (split(/\n/s, $db->{'b'})) {
			if (/^\s*\$([^\s=]+)\s*=\s*([^\'\s]*)\s*(\'[^\']+\')?$/) {
				my $var=$1; my $rule=$2; my $pre=$3;
				if (defined $pre && $pre=~/^\s*\'\s*([^=\s]+)\s*=\s*([^\']+)\'\s*$/) {
					my $a=$1; my $b=$2;
					print "Pre: $a<=>$b\n";
					$pre=new Math::Expr::VarSet;
					$pre->Set($a, Parse($b));
				} else {
					$pre=undef;
				}

				if ($prev ne $var) {$res.="\n".$vars{$var}->toText;}
				$vars{$var}=$self->ApplyAt($vars{$var},$rule,$pre);
				$res.=" <=> " . $vars{$var}->toText;
				$prev=$var;
			}
		}
		$res."\n";
	}
}

sub ApplyAt {
	my ($self, $e, $r,$pre) = @_;
	my ($rule, $dir, $pos) = split (/-/, $r);

	$self->Get($rule)->{$dir}->ApplyAt($e,$pos,$pre);
}

1;
