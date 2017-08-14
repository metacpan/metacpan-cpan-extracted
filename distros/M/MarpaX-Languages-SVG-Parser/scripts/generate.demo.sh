#!/bin/bash

perl -Ilib scripts/generate.demo.pl

rm $DR/Perl-modules/html/marpax.languages.svg.parser/*
cp html/*.svg html/*.html $DR/Perl-modules/html/marpax.languages.svg.parser

rm ~/savage.net.au/Perl-modules/html/marpax.languages.svg.parser/*
cp html/* ~/savage.net.au/Perl-modules/html/marpax.languages.svg.parser/
