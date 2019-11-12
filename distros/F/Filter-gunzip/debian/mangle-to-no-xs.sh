#!/bin/sh

# Copyright 2016, 2018, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Filter-gunzip is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.


# Run this script to change the control and rules files to make a pure-Perl
# "all" package instead of the normal XS.
#
# There's no reverse to put it back, so only do this in a copy!

set -e
set -x
if ! test -e rules; then
  cd debian
fi
if ! test -e rules; then
  echo oops, rules file not found
  exit 1
fi

echo "DEB_MAKEMAKER_USER_FLAGS = MY_WITHOUT_XS=1" >> rules
sed -i -e 's/Architecture: .*/Architecture: all/' \
       -e 's/, libperlio-gzip-perl//' \
       -e 's/, [$]{shlibs:Depends}//' \
    control
