#!/bin/bash

GMP=GraphViz2/Marpa/PathUtils

mkdir -p $DR/Perl-modules/html/$GMP

pod2html.pl -i lib/$GMP.pm        -o $DR/Perl-modules/html/$GMP.html
pod2html.pl -i lib/$GMP/Config.pm -o $DR/Perl-modules/html/$GMP/Config.html
pod2html.pl -i lib/$GMP/Demo.pm   -o $DR/Perl-modules/html/$GMP/Demo.html
