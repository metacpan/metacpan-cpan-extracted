#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Utils qw(remove_first_ws);

my $input = '  a';
remove_first_ws(\$input);
print "$input|\n";

# Output:
# a|