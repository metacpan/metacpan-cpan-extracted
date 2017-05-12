#!/usr/bin/perl

use strict;

use File::Spec;

use Test::More tests => 9;
BEGIN { use_ok("Devel::Mortality"); }

my $inc_dir = Devel::Mortality::inc_dir;

my $path = File::Spec->catdir(qw(blib lib auto Devel Mortality));
like($inc_dir, qr{$path});

Devel::Mortality::__test();