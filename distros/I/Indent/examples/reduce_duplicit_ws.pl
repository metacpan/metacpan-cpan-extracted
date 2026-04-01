#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Utils qw(reduce_duplicit_ws);

my $input = 'a  b';
reduce_duplicit_ws(\$input);
print "$input|\n";

# Output:
# a b|