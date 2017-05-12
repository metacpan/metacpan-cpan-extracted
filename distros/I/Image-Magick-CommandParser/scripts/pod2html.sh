#!/bin/bash
#
# $DR is my web server's doc root within Debian's RAM disk :-).
# The latter is at /run/shm, so $DR is /run/shm/html.

DIR=Perl-modules/html/Image/Magick
FILE=CommandParser

mkdir -p $DR/$DIR/$FILE
mkdir -p ~/savage.net.au/$DIR/$FILE

pod2html.pl -i lib/Image/Magick/$FILE.pm -o ~/savage.net.au/$DIR/$FILE.html

cp -r ~/savage.net.au/$DIR/* $DR/$DIR
