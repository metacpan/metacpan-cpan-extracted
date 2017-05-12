#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;

# Print parent directory path.
print File::Object->new->up->s."\n";

# Output which runs from /usr/local/bin:
# /usr/local