#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Map::Tube::KualaLumpur;

# Object.
my $obj = Map::Tube::KualaLumpur->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# Ampang Line
# KL Monorail Line
# KLIA Ekspres Line
# KLIA Transit Line
# Kelana Jaya Line
# Port Klang Line
# Seremban Line
# Sri Petaling Line