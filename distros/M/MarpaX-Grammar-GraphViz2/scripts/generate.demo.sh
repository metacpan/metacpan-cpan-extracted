#!/bin/bash

if [ -n "$1" ]; then
	echo Processing c.ast. Wait 6 m 47 secs
	scripts/bnf2graph.sh c.ast
fi

scripts/bnf2graph.sh json.1
scripts/bnf2graph.sh json.2
scripts/bnf2graph.sh json.3
# Process killed!
#scripts/bnf2graph.sh metag
scripts/bnf2graph.sh numeric.expressions
scripts/bnf2graph.sh stringparser
scripts/bnf2graph.sh termcap.info

perl -Ilib scripts/generate.demo.pl

rm $DR/Perl-modules/html/marpax.grammar.graphviz2/*
cp html/* $DR/Perl-modules/html/marpax.grammar.graphviz2/

rm ~/savage.net.au/Perl-modules/html/marpax.grammar.graphviz2/*
cp html/* ~/savage.net.au/Perl-modules/html/marpax.grammar.graphviz2/