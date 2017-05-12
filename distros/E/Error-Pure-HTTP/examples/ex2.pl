#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::ErrorList qw(err);

# Error.
err '1', '2', '3';

# Output like this:
# Content-type: text/plain
#
# #Error [script.pl:11] 1