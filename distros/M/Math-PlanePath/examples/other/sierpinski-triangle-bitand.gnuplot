#!/usr/bin/gnuplot

# Copyright 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Usage: gnuplot sierpinski-triangle-replicate.gnuplot
#
# Plot points of the Sierpinski triangle by a bitwise-and to decide
# whether a given X,Y point should be plotted.  Points not wanted are
# suppressed by returning NaN.


level=6
size=2**level

# Return X,Y grid coordinates ranging X=0 to size-1 and Y=0 to size-1,
# as t ranges 0 to size*size-1.
x(t) = int(t) % size
y(t) = int(t / size)

# Return true if the X,Y coordinates at t are wanted for the
# Sierpinski triangle.
want(t) = ((x(t) & y(t)) == 0)

triangle_x(t) = (want(t) ? x(t) : NaN)
triangle_y(t) = (want(t) ? y(t) : NaN)

set parametric
set trange [0:size*size-1]
set samples size*size
set key off
plot triangle_x(t),triangle_y(t) with points
pause 100
