#!/bin/bash

# My web server's doc root is $DR = /dev/shm/html.
# For non-Debian user's, /run/shm is the built-in RAM disk.

PREFIX=Perl-modules/html/Genealogy

mkdir -p $DR/$PREFIX/Gedcom/Reader
mkdir -p ~/savage.net.au/$PREFIX/Gedcom/Reader

pod2html.pl -i lib/Genealogy/Gedcom.pm              -o $DR/$PREFIX/Gedcom.html
pod2html.pl -i lib/Genealogy/Gedcom/Reader.pm       -o $DR/$PREFIX/Gedcom/Reader.html
pod2html.pl -i lib/Genealogy/Gedcom/Reader/Lexer.pm -o $DR/$PREFIX/Gedcom/Reader/Lexer.html

cp -r $DR/$PREFIX ~/savage.net.au
