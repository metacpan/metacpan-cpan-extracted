#!/bin/bash

rm html/*
rm $DR/Perl-modules/html/marpax.languages.dash/*
rm ~/savage.net.au/Perl-modules/html/marpax.languages.dash/*

perl -Ilib scripts/dash2svg.pl
perl -Ilib scripts/generate.index.pl

cp html/* $DR/Perl-modules/html/marpax.languages.dash
cp html/* ~/savage.net.au/Perl-modules/html/marpax.languages.dash
