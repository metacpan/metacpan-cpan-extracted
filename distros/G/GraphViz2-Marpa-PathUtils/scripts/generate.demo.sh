#!/bin/bash

perl -Ilib scripts/generate.demo.pl

# $DR is my web server's doc root.

DIR=html
PM=Perl-modules/html/graphviz2.marpa.pathutils

mkdir -p $DR/$PM
mkdir -p ~/savage.net.au/$PM

cp $DIR/* $DR/$PM             > /dev/null
cp $DIR/* ~/savage.net.au/$PM > /dev/null

echo Copied files to $DR/$PM
echo Warning: Check the version number in the demo index
