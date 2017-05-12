#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(encode_utf8);
use Map::Tube::Tbilisi;

# Object.
my $obj = Map::Tube::Tbilisi->new;

# Get lines.
my $lines_ar = $obj->get_lines;

# Print out.
map { print encode_utf8($_->name)."\n"; } sort @{$lines_ar};

# Output:
# ახმეტელი-ვარკეთილის ხაზი
# საბურთალოს ხაზი