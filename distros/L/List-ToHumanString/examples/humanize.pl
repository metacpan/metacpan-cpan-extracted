#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib  ../lib);
use List::ToHumanString;

@ARGV or die "Usage: $0 LIST OF ITEMS\n";

print to_human_string( "The {item is|items are} |list|\n", @ARGV, );
