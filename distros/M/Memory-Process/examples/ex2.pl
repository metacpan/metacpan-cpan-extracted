#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use Memory::Process;

# Object.
my $m = Memory::Process->new;

# Example process.
$m->record("Before my big method");
my $var = ('foo' x 100);
sleep 1;
$m->record("After my big method");
sleep 1;
$m->record("End");

# Print report.
my $state_ar = $m->state;

# Dump out.
p $state_ar;

# Output like:
# \ [
#     [0] [
#         [0] 1445941214,
#         [1] "Before my big method",
#         [2] 33712,
#         [3] 7956,
#         [4] 3876,
#         [5] 8,
#         [6] 4564
#     ],
#     [1] [
#         [0] 1445941215,
#         [1] "After my big method",
#         [2] 33712,
#         [3] 7956,
#         [4] 3876,
#         [5] 8,
#         [6] 4564
#     ],
#     [2] [
#         [0] 1445941216,
#         [1] "End",
#         [2] 33712,
#         [3] 7956,
#         [4] 3876,
#         [5] 8,
#         [6] 4564
#     ]
# ]