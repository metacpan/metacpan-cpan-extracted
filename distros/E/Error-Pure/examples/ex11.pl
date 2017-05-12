#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::ErrorList qw(err);

# Error.
eval { err "1"; };
if ($EVAL_ERROR) {
       err "2";
}

# Output:
# #Error [example3.pl:10] 1
# #Error [example3.pl:11] 2