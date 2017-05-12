#!/bin/bash
#
# Parameters:
# 1: The name of input and files.
#	16 means the input is data/16.gv, and the output is
#	$DR/Perl-modules/html/graphviz2.marpa/16.svg.
# $DR is my web server's doc root (in Debian's RAM disk).

echo In: data/$1.gv

dot -Tsvg data/$1.gv > html/$1.svg

cp html/$1.svg $DR/Perl-modules/html/graphviz2.marpa/$1.svg

echo Out: html/$1.svg and $DR/Perl-modules/html/graphviz2.marpa/$1.svg
