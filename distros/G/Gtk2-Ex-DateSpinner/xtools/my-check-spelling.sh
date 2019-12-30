#!/bin/sh

# my-check-spelling.sh -- grep for spelling errors

# Copyright 2009, 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2018, 2019 Kevin Ryde

# my-check-spelling.sh is shared by several distributions.
#
# my-check-spelling.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# my-check-spelling.sh is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


set -e
# set -x


 # | tee /dev/stdout
# -name samp -prune \
#        -o -name formats -prune \
#        -o -name "*~" -prune \
#        -o -name "*.tar.gz" -prune \
#        -o -name "*.deb" -prune \
#        -o 
       # -o -name dist-deb -prune \
# | egrep -v '(Makefile|dist-deb)' \


#  --colour=always

if find . -name my-check-spelling.sh -prune \
          -o -type f -print0 \
| xargs -0 egrep -nHi 'simlar|roughtly|randomes|silbing|minmal|wiht|\bits the\b|\bint he\b|withtout|occured|exmaple|weiner|rigth|peroid|Manhatten|occuring|optino|recurrance|nineth|\bon on\b|\bto to\b|tranpose|adjustement|glpyh|rectanglar|availabe|grabing|cusor|refering|writeable|nineth|\bommitt?ed|omited|[$][rd]elf|requrie|noticable|continous|existant|explict|agument|destionation|\bthe the\b|\bfor for\b|\bare have\b|\bare are\b|\bwith with\b|\bin in\b|\b[tw]hen then\b|\bnote sure\b|\bnote yet\b|correspondance|sprial|wholely|satisif|\bteh\b|\btje\b|\btained\b|zip.com.au'
then
  echo '(word)'
  exit 1
fi

if find . -name my-check-spelling.sh -prune \
          -o -name \*.gz -prune \
          -o -type f -print0 \
| xargs -0 egrep -nH '\bov\b|\bTH[a-ce-z]'
then
  echo '(ov or TH)'
  exit 1
fi

exit 0
