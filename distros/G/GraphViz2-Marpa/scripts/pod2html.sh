#!/bin/bash

DEST=$DR/Perl-modules/html/GraphViz2

pod2html.pl -i lib/GraphViz2/Marpa.pm                   -o $DEST/Marpa.html
pod2html.pl -i lib/GraphViz2/Marpa/Config.pm            -o $DEST/Marpa/Config.html
pod2html.pl -i lib/GraphViz2/Marpa/Utils.pm             -o $DEST/Marpa/Utils.html
pod2html.pl -i lib/GraphViz2/Marpa/Renderer/Graphviz.pm -o $DEST/Marpa/Renderer/Graphviz.html
