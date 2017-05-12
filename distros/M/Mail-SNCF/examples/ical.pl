#! perl -Ilib

use strict;

use SNCF::ICal;


my $s = SNCF::ICal->parse("t/sncf");

$s->print;

