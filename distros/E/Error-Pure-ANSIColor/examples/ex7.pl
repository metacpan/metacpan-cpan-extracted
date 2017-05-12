#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::ANSIColor::AllError qw(err);

print "1\n";
err "This is a fatal error.", "name", "value";
print "2\n";

# Output:
# 1
# ERROR: This is a fatal error.
# name: value
# main  err  ./script.pl  12