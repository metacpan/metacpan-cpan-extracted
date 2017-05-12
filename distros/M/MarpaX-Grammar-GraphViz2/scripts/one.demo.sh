#!/bin/bash

scripts/bnf2graph.sh $1 $2 $3

rm $DR/Perl-modules/html/marpax.grammar.graphviz2/*
cp html/* $DR/Perl-modules/html/marpax.grammar.graphviz2/

rm ~/savage.net.au/Perl-modules/html/marpax.grammar.graphviz2/*
cp html/* ~/savage.net.au/Perl-modules/html/marpax.grammar.graphviz2/
