#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base.
#
# Image-Base is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Image-Base.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use List::Util qw(min max);

use Smart::Comments;

{
  package MyGrid;
  use Image::Base;
  use vars '@ISA';
  @ISA = ('Image::Base');
  sub new {
    my $class = shift;
    my $self = bless { @_}, $class;
    my $horiz = '+' . ('-' x $self->{'-width'}) . "+\n";
    $self->{'str'} = $horiz
      . (('|' . (' ' x $self->{'-width'}) . "|\n") x $self->{'-height'})
        . $horiz;
    return $self;
  }
  sub xy {
    my ($self, $x, $y, $colour) = @_;
    if (defined $colour && $colour eq 'black') {
      $colour = ' ';
    } else {
      $colour = '*';
    }
    substr ($self->{'str'}, $x+1 + ($y+1)*($self->{'-width'}+3), 1) = $colour;
  }
}

{
  my $p = MyGrid->new (-width => 10, -height => 5);
  my $q = $p->new_from_image('MyGrid') ;

  print $p->{'str'};
  print $q->{'str'};
  exit 0;
}
