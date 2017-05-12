#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::NoDie qw(err);

# Error.
err '1', '2', '3';

# Output:
# 1