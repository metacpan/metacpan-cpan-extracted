#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Carp;

use Env::Assert assert => {
    exact => 0,
    envdesc => <<'EOF'
USER=^[[:word:]]+$
SHELL=^[[:word:]\/-]+$
EOF
};

say 'My env is all good!' || croak 'Cannot say';
say "My name is '$ENV{USER}' and my shell is '$ENV{SHELL}'." || croak 'Cannot say';
exit 0;
