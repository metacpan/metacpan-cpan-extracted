#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

my $libdir = "$FindBin::Bin/../lib";
eval qq(use lib "$libdir");

my @classes = grep { !/SDL/ } map {
	s!^$libdir/!!; s!/!::!g; s!\.pm$!!g;
	$_;
} "$libdir/Games/Checkers.pm", glob("$libdir/Games/Checkers/*.pm");

eval qq(use Test::More tests => ) . (1 + @classes); die $@ if $@;

use_ok($_) foreach @classes;

pass((eval 'use Games::Checkers::SDL; 1' ? 'with' : 'no') . ' SDL support');
