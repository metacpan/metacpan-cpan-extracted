#!/usr/bin/env perl

use Capture::Tiny 'capture';

use File::Spec;

# --------------------

my($stdout, $stderr) = capture{system 'dot', '-T?'};
my(@field)           = split(/one of:\s+/, $stderr);
my($file_name)       = File::Spec -> catfile('data', 'output.formats.dat');

open(OUT, '>', $file_name) || die "Can't open(> $file_name): $!";
print OUT map{"$_\n"} sort split(/\s+/, $field[1]);
close OUT;
