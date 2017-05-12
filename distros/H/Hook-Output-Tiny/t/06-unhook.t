#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $h = Hook::Output::Tiny->new;

$h->hook;

print "out 1\n";
print "out 2\n";

warn "err 1\n";
warn "err 2\n";

$h->unhook;

is ($h->stderr, 2, "stderr ok after unhook");
is ($h->stdout, 2, "stdout ok after unhook");

$h->hook('stderr');

warn "err 3\n";
print "out 3\n";

$h->unhook;

is ($h->stderr, 3, "stderr ok after 2 unhook");
is ($h->stdout, 2, "stdout ok after 2 unhook");

done_testing();
