#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::AllError qw(err);

# Print before.
print "Before\n";

# Error.
err "This is a fatal error.", "name", "value";

# Print after.
print "After\n";

# Output like this:
# Before
# Content-type: text/plain
#
# ERROR: This is a fatal error.
# name: value
# main  err  ./script.pl  12
# After