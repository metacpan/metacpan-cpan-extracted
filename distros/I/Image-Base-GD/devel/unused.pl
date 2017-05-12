#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

__END__
  } elsif (($r, $g, $b)
           = ($colour =~ /^#([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{4})$/i)) {
    $r = hex($r);
    $g = hex($g);
    $b = hex($b);
    $r *= (0xFF / 0xFFFF);
    $g *= (0xFF / 0xFFFF);
    $b *= (0xFF / 0xFFFF);

  if (my ($r, $g, $b) = ($colour =~ /^#([0-9A-F]{4})([0-9A-F]{4})([0-9A-F]{4})$/i)) {
    return hex($r) / 0xFFFF, hex($g) / 0xFFFF, hex($b) / 0xFFFF;
  }
