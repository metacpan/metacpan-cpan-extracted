#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::NoDie qw(err);

# Error.
err '1', '2', '3';

# Output:
# 1