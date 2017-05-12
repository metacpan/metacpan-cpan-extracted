#!/bin/bash
#
# Parameters:
# 1: The name of input and files.
#	16 means the input is data/16.gv, and the output is
#	$DR/Perl-modules/html/graphviz2.marpa/16.svg.
# $DR is my web server's doc root (in Debian's RAM disk).

MAX=$2

if [ -z "$MAX" ]
then
	MAX=info
fi

if [ "$MAX" == "debug" ]
then
	echo Contents of data/$1.gv:
	cat data/$1.gv
	echo ----------------------------
fi

scripts/gv2svg.sh $1

scripts/g2m.sh data/$1.gv -max $MAX -out $1.gv > $1.log

if [ ! -e "$1.gv" ]
then
	echo Warning: $1.gv was not created

	exit 1
fi

echo Out: $1.gv and $1.log

dot -Tsvg data/$1.gv > $DR/Perl-modules/html/graphviz2.marpa/$1.svg
dot -Tsvg      $1.gv > $DR/Perl-modules/html/graphviz2.marpa/$1.new.svg

ls -aFl $DR/Perl-modules/html/graphviz2.marpa/$1.svg $DR/Perl-modules/html/graphviz2.marpa/$1.new.svg

echo Diff: $DR/Perl-modules/html/graphviz2.marpa/$1.svg $DR/Perl-modules/html/graphviz2.marpa/$1.new.svg

diff $DR/Perl-modules/html/graphviz2.marpa/$1.svg $DR/Perl-modules/html/graphviz2.marpa/$1.new.svg

if [ "$?" -eq "0" ]
then
	echo OK - No difference in SVGs
else
	echo Failed - Check $1.svg and $1.new.svg
fi

echo
