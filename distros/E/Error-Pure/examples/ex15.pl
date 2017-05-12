#!/usr/bin/env perl

package Example3;

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Print qw(err);

# Test with error.
sub test {
        err '1', '2', '3';
};

package main;

# Pragmas.
use strict;
use warnings;

# Run.
Example3::test();

# Output:
# Example3: 1