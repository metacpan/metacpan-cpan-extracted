#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::AllError qw(err);

# Error.
err "This is a fatal error.", "name", "value";

# Output like this:
# Content-type: text/plain
#
# ERROR: This is a fatal error.
# name: value
# main  err  ./script.pl  12