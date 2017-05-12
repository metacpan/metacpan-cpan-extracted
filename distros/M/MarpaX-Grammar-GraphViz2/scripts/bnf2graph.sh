#!/bin/bash
#
# Name: bnf2graph.sh.
#
# Parameters:
# 1: The abbreviated name of sample input and output data files.
#	E.g. xyz simultaneously means share/xyz.bnf and html/xyz.svg.
# 2 .. 5: Use for debugging. E.g.: -maxlevel debug.

perl -Ilib scripts/bnf2graph.pl -legend 1 -marpa share/metag.bnf -o html/$1.svg -user share/$1.bnf $2 $3 $4 $5
