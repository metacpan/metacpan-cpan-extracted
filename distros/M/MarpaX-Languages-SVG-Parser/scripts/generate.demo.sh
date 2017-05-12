#!/bin/bash

perl -Ilib scripts/generate.demo.pl

cp html/*.svg html/*.html $DR/Perl-modules/html/marpax.languages.svg.parser
