#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::ErrorList qw(err);

# Error.
err '1', '2', '3';

# Output:
# #Error [example2.pl:9] 1