#!/bin/bash

# FILE=01
# NODE=Act_1
#
# FILE=02
# NODE=5
#
# FILE=03
# NODE=A

LENGTH=$1
FILE=$2
NODE=$3

perl -Ilib scripts/find.fixed.length.paths.pl \
	-allow_cycles 0 \
	-input_file data/fixed.length.paths.in.$FILE.gv \
	-output_file out/fixed.length.paths.out.$FILE.gv \
	-max notice \
	-path_length $LENGTH \
	-report_paths 1 \
	-start_node $NODE

dot -Tsvg data/fixed.length.paths.in.$FILE.gv > html/fixed.length.paths.in.$FILE.svg
dot -Tsvg out/fixed.length.paths.out.$FILE.gv > html/fixed.length.paths.out.$FILE.svg

# $DR is my web server's doc root.

PM=Perl-modules/html/graphviz2.marpa.pathutils

cp html/fixed.length.paths.* $DR/$PM
