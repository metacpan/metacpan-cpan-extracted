#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use lib 'lib';

use t::Utils;

my $log = xopen(">tfiles/file.log");
for my $i (1 .. 30) {
    print {$log} "line $i\n";
}
xclose($log);

my $perl = $^X;

# simple usage (1)
{
    my $result = xqx("$perl -Ilib bin/unrotate tfiles/file.pos tfiles/file.log");
    is($result, join('', map {"line $_\n"} (1..30)), "simple unrotate call");
}

# commit (3)
{
    my $result = xqx("$perl -Ilib bin/unrotate -n=10 tfiles/file.pos --commit tfiles/file.log");
    is($result, join('', map {"line $_\n"} (1..10)), "unrotate understands --commit");

    $result = xqx("$perl -Ilib bin/unrotate -n=10 tfiles/file.pos tfiles/file.log");
    is($result, join('', map {"line $_\n"} (11..20)), "unrotate --commit works");

    $result = xqx("$perl -Ilib bin/unrotate -n=10 tfiles/file.pos tfiles/file.log");
    is($result, join('', map {"line $_\n"} (11..20)), "--commit is off by default");
}

# -n option (2)
{
    my $result = xqx("$perl -Ilib bin/unrotate tfiles/file.pos -n 3 tfiles/file.log");
    is($result, join('', map {"line $_\n"} (11..13)), "unrotate understands -n");

    $result = xqx("$perl -Ilib bin/unrotate tfiles/file.pos tfiles/file.log");
    is($result, join('', map {"line $_\n"} (11..30)), "-n is infinite by default");
}

# posfile stores logfile name (1)
{
    my $result = xqx("$perl -Ilib bin/unrotate -n 3 tfiles/file.pos");
    is($result, join('', map {"line $_\n"} (11..13)), "logfile is optional");
}

