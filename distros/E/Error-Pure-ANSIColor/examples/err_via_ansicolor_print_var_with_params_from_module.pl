#!/usr/bin/env perl

package Example3;

use strict;
use warnings;

use Error::Pure::ANSIColor::PrintVar qw(err);

# Test with error.
sub test {
        err '1', '2', '3';
}

package main;

use strict;
use warnings;

# Run.
Example3::test();

# Output:
# Example3: 1
# 2: 3