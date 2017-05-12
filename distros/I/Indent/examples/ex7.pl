#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Utils qw(remove_last_ws);

my $input = 'a   ';
remove_last_ws(\$input);
print "$input|\n";

# Output:
# a|