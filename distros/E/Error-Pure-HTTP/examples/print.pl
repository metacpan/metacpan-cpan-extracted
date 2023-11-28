#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::HTTP::Print qw(err);

# Error.
err '1';

# Output:
# Content-type: text/plain
#
# 1