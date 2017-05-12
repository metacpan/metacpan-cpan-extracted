#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $h = Hook::Output::Tiny->new;

$h->hook;

print "out 1\n";
warn "err 1\n";

$h->unhook;

my @out = $h->stdout;
my @err = $h->stderr;

is (@out, 1, "stdout ok");
is (@err, 1, "stderr ok");

$h->flush('stdout');

@out = $h->stdout;
@err = $h->stderr;

is (@out, 0, "stdout flush ok");
is (@err, 1, "stderr no-flush ok");

$h->hook();

print "out 2\n";
warn "err 2\n";

$h->unhook();

$h->flush('stderr');

@out = $h->stdout;
@err = $h->stderr;

is (@out, 1, "stdout no-flush ok");
is (@err, 0, "stderr flush ok");

$h->hook();

print "out 3\n";
warn "err 3\n";

$h->flush;
$h->unhook;

@out = $h->stdout;
@err = $h->stderr;

is (@out, 0, "stdout flush both ok");
is (@err, 0, "stderr flush both ok");


done_testing();
