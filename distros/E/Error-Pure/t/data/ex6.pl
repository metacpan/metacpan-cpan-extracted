#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure qw(err);

# Tests issue to 0.28 version of Error::Pure.
# Output should be a Error::Pure::Die error.
$ENV{'Error::Pure::Type'} = 'AllError';
$Error::Pure::TYPE = 'Die';

# Error.
err 'Error.', 'Parameter', 'Value';
