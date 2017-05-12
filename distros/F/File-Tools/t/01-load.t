#!/usr/bin/perl
use strict;
use warnings;

my @funcs = qw(cat df diff rm tail);

use Test::More;
use Test::NoWarnings;

plan tests => 1+@funcs;

use File::Tools;


foreach my $func (@funcs) {
  eval "File::Tools::$func()";
  is ($@, "Not implemented\n", "$func not implemented");
};
