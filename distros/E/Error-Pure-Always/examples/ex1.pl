#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Always;

# Set env error type.
$ENV{'ERROR_PURE_TYPE'} = 'Die';

# Error.
die '1';

# Output:
# 1 at example1.pl line 9.