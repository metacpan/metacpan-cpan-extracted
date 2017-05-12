#!/bin/bash
#
# Name: bnf2tree.sh.
#
# Parameters:
# 1: The abbreviated name of sample input and output data files.
#	E.g. xyz simultaneously means share/xyz.bnf, share/xyz.cooked.tree and share/xyz.raw.tree.
# 2 .. 5: Use for anything. E.g.: -maxlevel debug.

perl -Ilib scripts/bnf2tree.pl -marpa_bnf share/metag.bnf -cooked share/$1.cooked.tree \
	-raw share/$1.raw.tree -user_bnf share/$1.bnf $2 $3 $4 $5
