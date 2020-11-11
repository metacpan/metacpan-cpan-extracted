#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Utils qw(string_len);

# Print string length.
print string_len("\tab\t")."\n";

# Output:
# 18