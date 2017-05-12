divert(-1)

# Copyright 2013 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Usage: m4 sierpinski-triangle.m4
#
# Plot points of the Sierpinski triangle using a bitwise-and to decide
# whether a given X,Y point should be a "*" or a space.
#


# forloop(varname, start,end, body)
# Expand body with varname successively define()ed to integers "start" to
# "end" inclusive.  "start" to "end" can go either increasing or decreasing.
define(`forloop', `define(`$1',$2)$4`'dnl
ifelse($2,$3,,`forloop(`$1',eval($2 + 2*($2 < $3) - 1), $3, `$4')')')

divert`'dnl

forloop(`y',15,0,
`forloop(`i',0,y,` ')dnl  indent y many spaces
forloop(`x',0,15,
`ifelse(eval(x&y),0,` *',`  ')')
')
