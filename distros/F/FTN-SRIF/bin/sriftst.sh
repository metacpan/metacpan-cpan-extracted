#!/bin/sh
# sriftst.sh - v0.09 - R.J. Clay
#  This is an example test script to run the srif.pl script
# for processing incoming file requests via SRIF files
#
SRIFFILE="/opt/tst/out/07800220.srf"
BINDIR="/opt/ftn/srifpl"

# ftn-srif sriffile 
$BINDIR/ftn-srif $SRIFFILE 2>srif.errors
