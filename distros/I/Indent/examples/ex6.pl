#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Utils qw(remove_ws);

my $input = '   a   ';
remove_ws(\$input);
print "$input|\n";

# Output:
# a|