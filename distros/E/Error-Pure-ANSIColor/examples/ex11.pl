#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::ANSIColor::Die qw(err);

# Error.
err '1', '2', '3';

# Output:
# 1 at example2.pl line 9.