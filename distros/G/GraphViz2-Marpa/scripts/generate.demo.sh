#!/bin/bash

PM=Perl-modules/html/graphviz2.marpa

for authortest in 0 1
do
	scripts/generate.svg.sh $authortest

	perl -Ilib scripts/generate.demo.pl -authortest $authortest

	# $DR is my web server's doc root (in Debian's RAM disk).
	# $PM is a directory path.

	if [ "$authortest" == "1" ]
	then
		PM="$PM/authortest"
		DIR=xt/author/html
	else
		DIR=html
	fi

	cp $DIR/* $DR/$PM             > /dev/null
	cp $DIR/* ~/savage.net.au/$PM > /dev/null

done

echo Check the version number in the demo index
