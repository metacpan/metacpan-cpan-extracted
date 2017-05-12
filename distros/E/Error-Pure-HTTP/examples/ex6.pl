#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::Print qw(err);

# Error.
err '1';

# Output:
# Content-type: text/plain
#
# 1