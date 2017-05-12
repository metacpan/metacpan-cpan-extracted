#!/bin/bash

DIR=Perl-modules/html/File/BOM
FILE=Utils.html

mkdir -p $DR/$DIR ~/savage.net.au/$DIR

pod2html.pl -i lib/File/BOM/Utils.pm -o $DR/$DIR/$FILE

cp $DR/$DIR/$FILE ~/savage.net.au/$DIR
