#!/bin/bash

DEST=$DR/Perl-modules/html

pod2html.pl -i lib/GraphViz2.pm                  -o $DEST/GraphViz2.html
pod2html.pl -i lib/GraphViz2/DBI.pm              -o $DEST/GraphViz2/DBI.html
pod2html.pl -i lib/GraphViz2/Utils.pm            -o $DEST/GraphViz2/Utils.html
pod2html.pl -i lib/GraphViz2/Data/Grapher.pm     -o $DEST/GraphViz2/Data/Grapher.html
pod2html.pl -i lib/GraphViz2/Parse/ISA.pm        -o $DEST/GraphViz2/Parse/ISA.html
pod2html.pl -i lib/GraphViz2/Parse/RecDescent.pm -o $DEST/GraphViz2/Parse/RecDescent.html
pod2html.pl -i lib/GraphViz2/Parse/Regexp.pm     -o $DEST/GraphViz2/Parse/Regexp.html
pod2html.pl -i lib/GraphViz2/Parse/STT.pm        -o $DEST/GraphViz2/Parse/STT.html
pod2html.pl -i lib/GraphViz2/Parse/XML.pm        -o $DEST/GraphViz2/Parse/XML.html
pod2html.pl -i lib/GraphViz2/Parse/Yacc.pm       -o $DEST/GraphViz2/Parse/Yacc.html
pod2html.pl -i lib/GraphViz2/Parse/Yapp.pm       -o $DEST/GraphViz2/Parse/Yapp.html
