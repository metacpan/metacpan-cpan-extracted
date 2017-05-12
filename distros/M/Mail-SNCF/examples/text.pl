#! perl -Ilib

use strict;

use SNCF::Text;

my $s = SNCF::Text->parse("t/sncf");

$s->print;

