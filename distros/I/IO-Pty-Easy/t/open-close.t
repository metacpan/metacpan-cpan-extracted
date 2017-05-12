#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Pty::Easy;

my $pty = IO::Pty::Easy->new;
$pty->close;
ok(!$pty->opened, "closing a pty before a spawn");

done_testing;
