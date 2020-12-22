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

my @stdout = $h->stdout;
my @stderr = $h->stderr;

is (@stdout, 2, "stdout ok after unhook");
is (@stderr, 2, "stderr ok after unhook");

$h->hook('stderr');

warn "err 3\n";
print "out 3\n";

$h->unhook;

@stdout = $h->stdout;
@stderr = $h->stderr;

is (@stdout, 2, "stdout ok after 2 unhook");
is (@stderr, 3, "stderr ok after 2 unhook");

done_testing();
