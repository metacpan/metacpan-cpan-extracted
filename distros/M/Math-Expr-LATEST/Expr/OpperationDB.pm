#!/usr/bin/perl 

#  OpperationDB.pm - A db of basic opperands and there properties
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

  Math::Expr::OpperationDB - A db of basic opperands properties

=head1 SYNOPSIS

  require Math::Expr::OpperationDB;
  $db=new Math::Expr::OpperationDB($file);

=head1 DESCRIPTION

  This is a database containing info about the different opperations 
  (eg +,  -, *, ...). Each opperation is represented by a regexp 
  mathing a type specifikation. That way Real*Real wont be the same 
  opperation as Matrix*Matrix even though the same operation character 
  is used.

  The data stored for each operation is the return type of the 
  operation and whatever this operation is kommutativ or assosiative.

  Currently the data is hardcoded into the code, but that is about to 
  chnage.

=head1 METHODS

=cut

package Math::Expr::OpperationDB;
use strict;

use Math::Expr;

=head2 $db=new Math::Expr::OpperationDB;

  Creates a new db.

=cut

sub new {
	my $self = bless {}, shift;

	$self->Load(shift);

	$self;
}

sub InitDB {
	my $self=shift;
	my $a=$self->{'opps'};

	foreach (keys %{$a}) {
		if ($a->{$_}->{'simp'}) {
			$a->{$_}->{'simp'}=Parse($a->{$_}->{'simp'});
		}
		$a->{$_}{'TypeReg'}=qr/^$_$/;
	}
}

sub Load {
  my ($self, $file) = @_;
  my (%t, @o);

  open (F, "<$file");
  while (<F>) {
    if (/^([^:]+)\s*:\s*(.*)$/) {$t{lc($1)}=$2;}
    if (/^\s*$/ || eof F) {
      if ($t{'type'}) {
				my $t=$t{'type'};
				delete $t{'type'};

        if (defined $t{'prop'}) {
          @o = split(/\s*,\s*/, $t{'prop'});
          foreach (@o) {
            $self->{'opps'}{$t}{lc($_)}=1;
          }
          delete $t{'prop'};
        }

				foreach (keys %t) {
					$self->{'opps'}{$t}{$_}=$t{$_};
          delete $t{$_};
				}
      }
    }
  }
}

=head2 $db->Find($t)

  Tries all the type regexps in the db on $t and if one matches that 
  post is returned.

=cut

sub Find {
	my ($self, $str) = @_;
	my $opp;

	foreach (values %{$self->{'opps'}}) {
		if ($str =~ $_->{'TypeReg'}) {$opp=$_; last;}
	}

	$opp;
}

sub Keys {
	my $self = shift;

	keys %{$self->{'opps'}};
}

sub Get {
	my ($self, $a) = @_;

	$self->{'opps'}{$a};
}

1;
