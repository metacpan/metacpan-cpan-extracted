#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

__END__


    if ($x >= $self->{'-width'} && ! $self->{'-expand'}) {
      return;
    }
    if ($x > length($row)) {
      $row .= ' ' x ($x - length($row));
    }
  if ($x < 0 || $y < 0) {
    # croak "Negative x or y";
    return;
  }
  if ($y > $#$rows_array) {
    if ($self->{'-expand'}) {
      $self->set(-height => $y+1);
    } else {
      # quietly ignore y >= height
      return;
    }
  }
#   if (defined (my $cindex = $param{'-cindex'})) {
#     delete $self->{'_cindex_reverse'};
#   }
#   my $reverse = ($self->{'_cindex_reverse'}
#                  ||= { reverse %{$self->{'-cindex'}} });
  if ($x_lo >= $self->{'-width'} && ! $self->{'-expand'}) {
    return;
  }

  if ($y_hi > $#$rows_array) {
    if ($self->{'-expand'}) {
      $self->set(-height => $y_hi+1);
    } else {
      if ($y_lo > $#$rows_array) {
        # quietly ignore all y >= height
        return;
      }
      $y_hi = $#$rows_array;
    }
  }
  my $y_lo = min($y1,$y2);
  my $y_hi = max($y1,$y2);
  my $x_lo = min($x1,$x2);
  my $x_hi = max($x1,$x2);
      if ($x_lo > length($row)) {
        $row .= ' ' x ($x_lo - length($row));
      }
  if (($y < 0 && $y2 < 0)
      || ($x < 0 && $x2 < 0)) {
    return;
  }


