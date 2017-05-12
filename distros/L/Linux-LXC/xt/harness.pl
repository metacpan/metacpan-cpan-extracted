#!/usr/bin/perl

use strict;
use warnings;

use v5.20;

use TAP::Harness;

my %args = (
	verbosity => 0,
	lib => ['../lib'],
	color => 1
);

my $harness = TAP::Harness->new(\%args);
$harness->runtests('lxc.t');