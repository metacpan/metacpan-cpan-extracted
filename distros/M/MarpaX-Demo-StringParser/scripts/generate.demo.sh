#!/bin/bash

rm html/*
rm $DR/Perl-modules/html/marpax.demo.stringparser/*
rm ~/savage.net.au/Perl-modules/html/marpax.demo.stringparser/*

perl -Ilib scripts/dash2svg.pl
perl -Ilib scripts/generate.index.pl

cp html/* $DR/Perl-modules/html/marpax.demo.stringparser
cp html/* ~/savage.net.au/Perl-modules/html/marpax.demo.stringparser
