#!/usr/bin/env perl -w

use Test::More "no_plan";
use strict;

is(qx"$^X -It t/outer.pl",
   <<'EEOOFF', "no unpound");
Starting outer
This is the inner1 package
This is the inner2 package
Done.
EEOOFF
    ;


is(qx"$^X -MFilter::Unpound=debug -It t/outer.pl",
   <<'EEOOFF', "debug unpound enabled");
Starting outer
Debug is ON.
This is the inner1 package
This is the inner2 package
INNER2: With debugging enabled
Done.
EEOOFF
    ;
