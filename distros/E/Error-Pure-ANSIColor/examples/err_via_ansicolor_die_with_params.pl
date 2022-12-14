#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::ANSIColor::Die qw(err);

# Error.
err '1', '2', '3';

# Output:
# 123 at ../err_via_ansicolor_die_with_params.pl line 9.