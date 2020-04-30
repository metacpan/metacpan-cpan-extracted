#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure qw(err);

# Set env error type.
$ENV{'ERROR_PURE_TYPE'} = 'Die';

# Error.
err '1';

# Output:
# 1 at example1.pl line 9.