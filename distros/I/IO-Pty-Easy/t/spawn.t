#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Pty::Easy;

my $pty = IO::Pty::Easy->new;
$pty->spawn("$^X -ple ''");
ok($pty->is_active, "spawning a subprocess");
ok($pty->kill(0, 1), "subprocess actually exists");
$pty->kill;
ok(!$pty->is_active, "killing a subprocess");
$pty->spawn("$^X -ple ''");
$pty->close;
ok(!$pty->is_active, "auto-killing a pty with close()");
ok(!$pty->opened, "closing a pty after a spawn");

done_testing;
