#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use File::Slurp;

my @types;
while (<>) {
    next unless /JIT_EXPORT_DATA jit_type_t const (\w+)/;
    push @types, $1;
}

my $prefix = "libjit_const_";

open my $c, ">", "jit_type-c.inc";
$c->print("jit_type_t $prefix$_ (void) { return $_; }\n")
    foreach @types;

open my $xs, ">", "jit_type-xs.inc";
$xs->print("MODULE = LibJIT  PACKAGE = LibJIT  PREFIX = $prefix\n\n");
$xs->print("jit_type_t\n$prefix$_()\n\n")
    foreach @types;

my $pm = read_file("lib/LibJIT.pm");
my $types = join "", map "    $_\n", @types;
$pm =~ s/(our\s+\@TYPES\s*=\s*qw\()[^\)]*(\);)/$1\n$types$2/m;

open my $pmf, ">", "lib/LibJIT.pm";
$pmf->print($pm);

