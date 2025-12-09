#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Carp;

# ATTN. do not alter the line numbering. Error check in test depends on it.

use Env::Assert assert => {
    envdesc_file         => 'another-envdesc',
    break_at_first_error => 0,
};

say 'Control should not reach this point!' || croak 'ERROR';
exit 0;
