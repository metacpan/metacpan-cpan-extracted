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



# Usage: gnuplot sierpinski-triangle-text.gnuplot
#
# Print the Sierpinski triangle pattern with spaces and stars using
# bitwise-and to decide whether or not to plot each X,Y.
#
#            *
#           * *
#          *   *
#         * * * *
#        *       *
#       * *     * *
#      *   *   *   *
#     * * * * * * * *
#


# Return a space or star string to print at x,y.
# Must have x<y.  Can have x<0.  If x<-y then it's before the left
# edge of the triangle and the return is a space.
char(x,y) = (y+x>=0 && ((y+x)%2)==0 && ((y+x)&(y-x))==0 ? "*" : " ")

# Return a string which is row y of the triangle from character
# position x through to the right hand end x==y, inclusive.
row(x,y) = (x<=y ? char(x,y).row(x+1,y) : "\n")

# Return a string of stars, spaces and newlines which is the
# Sierpinski triangle rows from y to limit, inclusive.
# The first row is y=0.
triangle(y,limit) = (y <= limit ? row(-limit,y).triangle(y+1,limit) : "")

# Print rows 0 to 15, which is the order 4.
print triangle(0,15)

exit
