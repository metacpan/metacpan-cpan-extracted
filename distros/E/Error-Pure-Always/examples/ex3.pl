#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Always;

# Set error type.
$Error::Pure::TYPE = 'AllError';

# Error.
die '1';

# Output something like:
# ERROR: 1
# main  err  path_to_script  12