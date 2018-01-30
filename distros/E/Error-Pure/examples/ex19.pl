#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Die qw(err);

# Error.
err '1', '2', '3';

# Output:
# 1 at example2.pl line 9.