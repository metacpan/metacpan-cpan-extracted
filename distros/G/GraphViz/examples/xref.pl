#!/usr/bin/perl -w
#
# This script illustrates how cross-referencing using the
# B::Xref module can work

use strict;
qx(perl -MO=Xref,-r ../lib/GraphViz.pm > GraphViz.xref;  ./xref_aux.pl GraphViz.xref > GraphViz.png);


