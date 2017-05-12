#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::AllError qw(err);

print "1\n";
err "This is a fatal error.", "name", "value";
print "2\n";

# Output:
# 1
# ERROR: This is a fatal error.
# name: value
# main  err  ./script.pl  12