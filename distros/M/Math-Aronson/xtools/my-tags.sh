#!/bin/sh

# my-tags.sh -- make tags

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# my-tags.sh is shared by several distributions.
#
# my-tags.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# my-tags.sh is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


set -e
set -x

# in a hash-style multi-const this "use constant" pattern only picks up the
# first constant, unfortunately, but it's better than nothing

etags \
 --regex='{perl}/use[ \t]+constant\(::defer\)?[ \t]+\({[ \t]*\)?\([A-Za-z_][^ \t=,;]+\)/\3/' \
 `find lib -type f`
