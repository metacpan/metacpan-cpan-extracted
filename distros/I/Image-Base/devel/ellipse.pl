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
use Image::Xpm;

# uncomment this to run the ### lines
#use Smart::Comments;

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
    if ($x != int($x) || $y != int($y)) {
    }
      print "$x $y\n";
    if ($colour eq 'black') {
      $colour = ' ';
    } else {
      $colour = '*';
    }
    substr ($self->{'str'}, $x+1 + ($y+1)*($self->{'-width'}+3), 1) = $colour;
    print $self->{'str'};
  }
}

my $w = 77;
my $h = 3;

{
  my $image = MyGrid->new (-width => $w, -height => $h);
  print "ellipse draw\n";
  $image->ellipse (0,0, $w-1,$h-1, 'white');
  print $image->{'str'};
  exit 0;
}

{
  my $image = Image::Xpm->new (-width => $w, -height => $h);
  $image->rectangle (0,0, $w-1,$h-1, 'black', 1);
  $image->line (0,int($h/2), $w-1,int($h/2), 'orange');
  $image->line (int($w/2),0, int($w/2),$h-1, 'orange');

  $image->line (int($w*.25),0, int($w*.25),$h-1, 'orange');
  $image->line (int($w*.75),0, int($w*.75),$h-1, 'orange');
  $image->line (0,int($h*.25), $w-1,int($h*.25), 'orange');
  $image->line (0,int($h*.75), $w-1,int($h*.75), 'orange');

  $image->ellipse (0,0, $w-1,$h-1, 'white');
  $image->save('/tmp/ellipse.xpm');
  system ('xzgv /tmp/ellipse.xpm');
  exit 0;
}
