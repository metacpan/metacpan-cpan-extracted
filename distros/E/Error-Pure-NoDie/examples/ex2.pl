#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::NoDie qw(err);

# Error.
err '1';
err '2';

# Output:
# 1
# 2