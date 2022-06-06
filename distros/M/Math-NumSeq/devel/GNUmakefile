# Copyright 2012, 2013, 2021 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# This file named GNUmakefile to hide it from ExtUtils::MakeMaker.

#  -mtune=athlon -march=athlon
CFLAGS = -Wall -std=gnu99 -O2 -g

# exe-flimsy: exe-flimsy.o flimsy-subr.o

test:
	$(HOME)/p/shared/my-check-gp.pl *test*.gp
	#  gp-2.11.4 gp-2.9.5 gp-2.7.6
	for GP in gp; do \
	  echo $$GP; \
	  $$GP --quiet -f <a000119-Fibonacci-R--test.gp || exit 1; \
	done

spell:
	ispell-batch-gp.pl a000119-Fibonacci-R.gp
