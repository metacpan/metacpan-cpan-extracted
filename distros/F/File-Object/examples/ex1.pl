#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;

# Print actual directory path.
print File::Object->new->s."\n";

# Output which runs from /usr/local/bin:
# /usr/local/bin