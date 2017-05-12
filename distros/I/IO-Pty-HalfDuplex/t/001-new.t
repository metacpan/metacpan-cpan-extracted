#!/usr/bin/env perl
use strict;
use warnings;
use IO::Pty::HalfDuplex;

use Test::More tests => 3;

####

my $pty = IO::Pty::HalfDuplex->new;

ok($pty->isa("IO::Pty::HalfDuplex"), "new returns an object");

ok(!$pty->is_active, "new pty is not active");

$pty->close;

pass("close succeeded");
