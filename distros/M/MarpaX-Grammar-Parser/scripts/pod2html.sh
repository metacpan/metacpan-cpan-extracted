#!/bin/bash

PREFIX=Perl-modules/html/MarpaX/Grammar/
FILE=$PREFIX/Parser.html

mkdir -p $DR/$PREFIX
mkdir -p ~/savage.net.au/$PREFIX

pod2html.pl -i lib/MarpaX/Grammar/Parser.pm -o $DR/$FILE

cp $DR/$FILE ~/savage.net.au/$FILE
