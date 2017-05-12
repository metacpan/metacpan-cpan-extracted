#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Utils qw(string_len);

# Print string length.
print string_len("\tab\t")."\n";

# Output:
# 18