#!/usr/bin/env perl

use strict;
use warnings;

use File::BOM::Utils;
use File::Spec;

# -------------------

my($bommer)    = File::BOM::Utils -> new;
my($file_name) = File::Spec -> catfile('data', 'bom-UTF-8.xml');

$bommer -> action('test');
$bommer -> input_file($file_name);

my($report) = $bommer -> file_report;

print "BOM report for $file_name: \n";
print join("\n", map{"$_: $$report{$_}"} sort keys %$report), "\n";
