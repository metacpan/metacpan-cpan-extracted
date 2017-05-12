#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::ANSIColor::ErrorList qw(err);

# Error.
err '1', '2', '3';

# Output:
# #Error [example2.pl:9] 1