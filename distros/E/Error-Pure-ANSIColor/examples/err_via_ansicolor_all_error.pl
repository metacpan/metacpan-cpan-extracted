#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::ANSIColor::AllError qw(err);

err "This is a fatal error.", "name", "value";

# Output:
# ERROR: This is a fatal error.
# name: value
# main  err  ./script.pl  12