#!/bin/bash

# ignore this - it's just a prototype

rrd=$1
[ -z "$rrd" ] && exit 200

#title="\"$rrd hits per minute\""
title=$rrd

start=1137737400
end=1137823800

cmd="rrdtool graph $rrd-hpm.png --start $start --end $end \
              --width 800 --height 150 \
              --title $title \
              --vertical-label hits \
              DEF:myover1=$rrd.rrd:over1:AVERAGE \
              DEF:myover2=$rrd.rrd:over2:AVERAGE \
              DEF:myover3=$rrd.rrd:over3:AVERAGE \
              DEF:myover4=$rrd.rrd:over4:AVERAGE \
              CDEF:over1hpm=myover1,60,* \
              CDEF:over2hpm=myover2,60,* \
              CDEF:over3hpm=myover3,60,* \
              CDEF:over4hpm=myover4,60,* \
              AREA:over1hpm#32CD32::STACK \
              AREA:over2hpm#0000FF::STACK \
              AREA:over3hpm#FF7F00::STACK \
              AREA:over4hpm#FF0000::STACK"

echo
echo COMMAND: $cmd
echo
echo

$cmd

#
# RRA:CF:xff:steps:rows
#
# The purpose of an RRD is to store data in the round robin archives
# (RRA). An archive consists of a number of data values from all the
# defined data-sources (DS) and is defined with an RRA line.
#
#  When data is entered into an RRD, it is first fit into time slots
# of the length defined with the -s option becoming a primary data
# point.
#
# The data is also consolidated with the consolidation function (CF)
# of the archive. The following consolidation functions are defined:
# AVERAGE, MIN, MAX, LAST.
#
# xff The xfiles factor defines what part of a consolidation interval
# may be made up from *UNKNOWN* data while the consolidated value is
# still regarded as known.
#
# steps defines how many of these primary data points are used to
# build a consolidated data point which then goes into the archive.
#
# rows defines how many generations of data values are kept in an RRA.
#
#

