#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


__END__

    my $width = $self->{'line_width'} || 1;
    my $y_top = $y - $width;
    my $y_bottom = $y + $width;
#     $win->draw_segments
#       ($gc,
#        $x_lo,$y, $x_hi,$y, # horizontal
#        ($y_lo <= $y_top ? ($x,$y_lo, $x,$y_top) : ()),
#        ($y_bottom <= $y_hi ? ($x,$y_bottom, $x,$y_hi) : ()));
