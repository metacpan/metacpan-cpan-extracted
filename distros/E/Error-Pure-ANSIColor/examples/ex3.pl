#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::ANSIColor::ErrorList qw(err);

# Error.
eval { err "1"; };
if ($EVAL_ERROR) {
       err "2";
}

# Output:
# #Error [example3.pl:10] 1
# #Error [example3.pl:11] 2