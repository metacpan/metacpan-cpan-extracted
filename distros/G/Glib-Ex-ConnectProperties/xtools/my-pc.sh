#!/bin/sh

# my-pc.sh -- run cpants_lint kwalitee checker

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# my-pc.sh is shared by several distributions.
#
# my-pc.sh is free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or (at your
# option) any later version.
#
# my-pc.sh is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

set -x

# PERLRUNINST=`sed -n 's/^PERLRUNINST = \(.*\)/\1/p' Makefile`
# if test -z "$PERLRUNINST"; then
#   echo "PERLRUNINST not found"
#   exit 1
# fi

EXE_FILES=`sed -n 's/^EXE_FILES = \(.*\)/\1/p' Makefile`
TO_INST_PM=`find lib -name \*.pm`

LINT_FILES="Makefile.PL $EXE_FILES $TO_INST_PM"

if test -e "t/*.t"; then
  LINT_FILES="$LINT_FILES t/*.t"
fi
if test -e "xt/*.t"; then
  LINT_FILES="$LINT_FILES xt/*.t"
fi
for i in t xt examples devel; do
  if test -e "$i/*.pl"; then
    LINT_FILES="$LINT_FILES $i/*.pl"
  fi
  if test -e "$i/*.pm"; then
    LINT_FILES="$LINT_FILES $i/*.pm"
  fi
done



perl -e 'use Test::Vars; all_vars_ok()'
# MyMakeMakerExtras_Pod_Coverage

perl -e 'use Pod::Coverage package => $class'

podlinkcheck -I lib `ls $LINT_FILES | grep -v '\.bash$$|\.desktop$$\.png$$|\.xpm$$'`

podchecker `ls $LINT_FILES | grep -v '\.bash$$|\.desktop$$\.png$$|\.xpm$$'`
perlcritic $LINT_FILES
