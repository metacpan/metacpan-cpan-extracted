#!/bin/sh

# my-diff-prev.sh -- diff against previous version

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# my-diff-prev.sh is shared by several distributions.
#
# my-diff-prev.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# my-diff-prev.sh is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


set -e
set -x

DISTNAME=`sed -n 's/^DISTNAME = \(.*\)/\1/p' Makefile`
if test -z "$DISTNAME"; then
  echo "DISTNAME not found"
  exit 1
fi

VERSION=`sed -n 's/^VERSION = \(.*\)/\1/p' Makefile`
if test -z "$VERSION"; then
  echo "VERSION not found"
  exit 1
fi

case $VERSION in
  3.*) PREV_VERSION=3.012000 ;;
  *)   PREV_VERSION="`expr $VERSION - 1`" ;;
esac
if test -z "$VERSION"; then
  echo "PREV_VERSION not established"
  exit 1
fi

rm -rf diff.tmp
mkdir -p diff.tmp
(cd diff.tmp;
 tar xfz ../$DISTNAME-$PREV_VERSION.tar.gz
 tar xfz ../$DISTNAME-$VERSION.tar.gz
 diff -ur $DISTNAME-$PREV_VERSION \
          $DISTNAME-$VERSION \
   >tree.diff || true
)
${PAGER:-more} diff.tmp/tree.diff || true
rm -rf diff.tmp
exit 0
