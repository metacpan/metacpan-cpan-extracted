#!/bin/sh

# my-manifest.sh -- update MANIFEST file

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# my-manifest.sh is shared by several distributions.
#
# my-manifest.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# my-manifest.sh is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


set -e
if [ -e MANIFEST ]; then
  mv MANIFEST MANIFEST.old || true
fi
touch SIGNATURE
(
  make manifest 2>&1;
  diff -u MANIFEST.old MANIFEST
) | ${PAGER:-more}
