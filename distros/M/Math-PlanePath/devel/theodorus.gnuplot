# Copyright 2010 Kevin Ryde

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


set terminal xterm

# set xlabel "Days ago (0 today, 1 yesterday, etc)" 0, -2
#
# something evil happens with "xtics axis", need dummy xlabel
# set xlabel " " 0, -2
# set xrange [-0.5:39.5]
# set xtics axis 5
# set mxtics 5

# set ylabel "Weight (percent)"
#
#set yrange [-5:55]
#set format y "%.1f"

#unset key
#set style fill solid 1.0
#set boxwidth 0.6 relative
plot "/tmp/theodorus.data"
