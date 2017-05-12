#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::HTTP::ErrorList qw(err);

# Error.
eval { err "1"; };
if ($EVAL_ERROR) {
       err "2";
}

# Output like this:
# Content-type: text/plain
# 
# #Error [script.pl:12] 1
# #Error [script.pl:13] 2