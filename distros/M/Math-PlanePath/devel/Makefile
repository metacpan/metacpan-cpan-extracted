# Copyright 2011, 2012, 2013, 2015 Kevin Ryde

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


# CFLAGS = -Wall -O0 -g
CFLAGS = -Wall -O2 -DINLINE=inline -g
LOADLIBES = -lm

size:
	perl -e '$$/=undef; $$_=<>; \
          s{(?<!\")[\\][\\].*}{}g; \
          s<[ {}]><>g; \
          s<""><" ">g; \
          s{quit.*}{}s; \
          s{\n}{}sg; \
          print $$_,"\n",length($$_),"\n"' \
        <flowsnake-ascii-small.gp \
