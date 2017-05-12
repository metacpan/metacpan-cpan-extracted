#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::Error qw(err);

# Error.
err '1';

# Output like this:
# Content-type: text/plain
#
# #Error [script.pl:12] 1