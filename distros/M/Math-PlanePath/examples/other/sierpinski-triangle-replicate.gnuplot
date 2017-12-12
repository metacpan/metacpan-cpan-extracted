#!/usr/bin/gnuplot

# Copyright 2012 Kevin Ryde

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
# Plot points of the Sierpinski triangle by replicating sub-parts of
# the pattern according to parameter t in ternary.
#
# The alignment relative to the Y axis can be changed by what
# digit_to_x() does.  For example to plot half,
#
#    digit_to_x(d) = (d<2 ? 0 : 1)
#



# triangle_x(n) and triangle_y(n) return X,Y coordinates for the
# Sierpinski triangle point number n, for integer n.
triangle_x(n) = (n > 0 ? 2*triangle_x(int(n/3)) + digit_to_x(int(n)%3) : 0)
triangle_y(n) = (n > 0 ? 2*triangle_y(int(n/3)) + digit_to_y(int(n)%3) : 0)
digit_to_x(d) = (d==0 ? 0 : d==1 ? -1 : 1)
digit_to_y(d) = (d==0 ? 0 : 1)


# Plot the Sierpinski triangle to "level" many replications.
# "trange" and "samples" are chosen so the parameter t runs through
# integers t=0 to 3**level-1, inclusive.
#
level=6
set trange [0:3**level-1]
set samples 3**level
set parametric
set key off
plot triangle_x(t), triangle_y(t) with points
pause 100