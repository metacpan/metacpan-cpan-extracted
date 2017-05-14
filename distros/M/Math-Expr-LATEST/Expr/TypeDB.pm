#!/usr/bin/perl 

#  TypeDB.pm - A db of basic types and there properties
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

  Math::Expr::TypeDB - A db of basic type and there properties

=head1 SYNOPSIS

  require Math::Expr::TypeDB;
  $db=new Math::Expr::TypeDB($file);

=cut

package Math::Expr::TypeDB;
use strict;

sub new {
  my $self = bless {}, shift;
  $self->Load(shift);
  $self;
}

sub Load {
  my ($self, $file) = @_;
  my %t;

  open (F, "<$file");
  while (<F>) {
    if (/^([^:]+)\s*:\s*(.*)$/) {$t{lc($1)}=$2;}
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


sub Keys {
	my $self = shift;

	keys %{$self->{'opps'}};
}

sub Get {
	my ($self, $a) = @_;

	$self->{'opps'}{$a};
}

1;
