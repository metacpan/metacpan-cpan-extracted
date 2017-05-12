#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;

BEGIN {
        chdir 't' if -d 't';
        use lib '../blib/lib', 'lib/', '..', 'blib/arch';
}

my $mod = "IP::Unique";
use_ok($mod);

can_ok($mod, "new");
can_ok($mod, "DESTROY");
can_ok($mod, "add_ip");
can_ok($mod, "compact");
can_ok($mod, "unique");
can_ok($mod, "total");
