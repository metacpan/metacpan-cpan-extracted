#!/bin/sh

# my-kwalitee.sh -- run cpants_lint kwalitee checker

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# my-kwalitee.sh is shared by several distributions.
#
# my-kwalitee.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# my-kwalitee.sh is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


# Module::CPANTS::Analyse

set -e
set -x

DISTVNAME=`sed -n 's/^DISTVNAME = \(.*\)/\1/p' Makefile`
if test -z "$DISTVNAME"; then
  echo "DISTVNAME not found"
  exit 1
fi

if [ -e ~/bin/my-gpg-agent-daemon ]; then
  eval `my-gpg-agent-daemon`
  echo "gpg-agent $GPG_AGENT_INFO"
fi

TGZ="$DISTVNAME.tar.gz"
make "$TGZ"

cpants_lint "$TGZ"
