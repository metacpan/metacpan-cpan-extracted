#!/bin/bash
#
# Parameters:
# 1: The name of input file.
#	E.g. data/19.gv.
# 2 .. N: Use for debugging etc. E.g.: -maxlevel debug.

perl -Ilib scripts/g2m.pl -input_file $1 $2 $3 $4 $5 $6 $7
