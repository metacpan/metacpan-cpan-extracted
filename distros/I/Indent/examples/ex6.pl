#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Utils qw(remove_first_ws);

my $input = '  a';
remove_first_ws(\$input);
print "$input|\n";

# Output:
# a|