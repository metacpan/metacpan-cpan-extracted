#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::HTTP::Error qw(err);

# Error.
err '1';

# Output like this:
# Content-type: text/plain
#
# #Error [script.pl:12] 1