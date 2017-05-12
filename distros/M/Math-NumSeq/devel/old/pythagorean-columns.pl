#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# http://oeis.org/A001333
#    -- sqrt(2) convergents numerators
# http://oeis.org/A000129
#    -- Pell numbers, sqrt(2) convergents numerators
# http://oeis.org/A002965
#    -- interleaved
#
# $values_info{'columns_of_pythagoras'} =
#   { subr => \&values_make_columns_of_pythagoras,
#     name => __('Columns of Pythagoras'),
#     # description => __('The ....'),
#   };
sub values_make_columns_of_pythagoras {
  my ($self, $lo, $hi) = @_;
  my $a = 1;
  my $b = 1;
  my $c;
  return sub {
    if (! defined $c) {
      $c = $a + $b;
      return $c;
    } else {
      $b = $a + $c;
      $a = $c;
      undef $c;
      return $b;
    }
  };
}

sub make_iter_empty {
  my ($self) = @_;
  return $self->make_iter_arrayref([]);
}
sub make_iter_arrayref {
  my ($self, $arrayref) = @_;
  $self->{'iter_arrayref'} = $arrayref;
  my $i = 0;
  return sub {
    return $arrayref->[$i++];
  };
}

