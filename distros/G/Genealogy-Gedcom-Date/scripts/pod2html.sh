#!/bin/bash

# My web server's doc root is $DR = /dev/shm/html/.
# For non-Debian user's, /dev/shm/ is the built-in RAM disk.

PREFIX=Perl-modules/html/Genealogy/Gedcom
FILE=$PREFIX/Date.html

mkdir -p $DR/$PREFIX
mkdir -p ~/savage.net.au/$PREFIX

pod2html.pl -i lib/Genealogy/Gedcom/Date.pm -o $DR/$FILE

cp $DR/$FILE ~/savage.net.au/$FILE
