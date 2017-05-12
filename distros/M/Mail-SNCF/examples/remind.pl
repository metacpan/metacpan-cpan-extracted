#! perl -Ilib

use strict;

use SNCF::Remind;

my $s = SNCF::Remind->parse("t/sncf");

$s->print;

