#!/bin/sh

# my-check-copyright-years.sh -- check copyright years in dist

# Copyright 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde

# my-check-copyright-years.sh is shared by several distributions.
#
# my-check-copyright-years.sh is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# my-check-copyright-years.sh is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

set -e   # die on error
set -x   # echo

# find files in the dist with mod times this year, but without this year in
# the copyright line

if test -z "$DISTVNAME"; then
  DISTVNAME=`sed -n 's/^DISTVNAME = \(.*\)/\1/p' Makefile`
fi
if test -z "$DISTVNAME"; then
  echo "DISTVNAME not set and not in Makefile"
  exit 1
fi
TARGZ="$DISTVNAME.tar.gz"
if test -e "$TARGZ"; then :;
else
  pwd
  echo "TARGZ $TARGZ not found"
  exit 1
fi


MY_HIDE=
year=`date +%Y`

result=0

# files with dates $year
tar tvfz $TARGZ \
| egrep "$year-|debian/copyright" \
| sed "s:^.*$DISTVNAME/::" \
| {
while read i
do
  # echo "consider $i"
  GREP=grep
  case $i in \
    '' | */ \
    | ppport.h \
    | debian/changelog | debian/doc-base \
    | debian/compat | debian/emacsen-compat | debian/source/format \
    | debian/patches/*.diff \
    | COPYING | MANIFEST* | SIGNATURE | META.yml | META.json \
    | version.texi | */version.texi \
    | *utf16* | examples/rs''s2lea''fnode.conf \
    | */MathI''mage/ln2.gz | */MathI''mage/pi.gz \
    | *.mo | *.locatedb* | t/samp.* \
    | t/empty.dat | t/*.xpm | t/*.xbm | t/*.jpg | t/*.gif \
    | t/*.g${MY_HIDE}d)
      continue ;;
    *.gz)
      GREP=zgrep
  esac; \

  if test -e "$srcdir/$i"
  then f="$srcdir/$i"
  else f="$i"
  fi

  if $GREP -q -e "Copyright.*$year" $f
  then :;
  else
    echo "$i:1: this file"
    grep Copyright $f
    result=1
  fi
done
}
exit $result
