#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;

use Path::Iterator::Rule;

# -------------
# Phase 1: Get the files already seen.

my($rule) = Path::Iterator::Rule -> new;

my(%seen);

# Skip special cases:

$seen{META}        = 1; # Not a *.gv file.
$seen{b15}         = 1; # Illegal utf8.
$seen{b34}         = 1;
$seen{b56}         = 1;
$seen{b60}         = 1;
$seen{Latin1}      = 1;
$seen{inv_inv}     = 1; # Uses external file (image, *.ps).
$seen{inv_nul}     = 1;
$seen{inv_val}     = 1;
$seen{nul_inv}     = 1;
$seen{nul_nul}     = 1;
$seen{nul_val}     = 1;
$seen{val_inv}     = 1;
$seen{val_nul}     = 1;
$seen{val_val}     = 1;
$seen{pslib}       = 1;
$seen{user_shapes} = 1;
$seen{tee}         = 1; # Causes a segfault.

for my $file ($rule -> name(qr/\.gv$/) -> all('./xt/author/data') )
{
	$seen{basename($file, '.gv')} = 1;
}

# Phase 2: Get the files not already seen.

$rule     = Path::Iterator::Rule -> new;
my($next) = $rule -> name(qr/\.gv$/) -> size('< 10k') -> iter("$ENV{HOME}/Downloads/Graphviz/graphviz-2.38.0");

my($basename);

while (defined(my $file = $next -> () ) )
{
	$basename = basename($file, '.gv');

	next if ($seen{$basename} || ($file =~ m|tclpkg/gv/META.gv|) );

	print "$file\n";
}
