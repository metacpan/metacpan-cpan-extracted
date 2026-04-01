#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::Bio qw(err_bio);

# Fictional error structure.
my $err_hr = {
        'msg' => [
                'FOO',
                'KEY',
                'VALUE',
        ],
        'stack' => [
                {
                        'args' => '(2)',
                        'class' => 'main',
                        'line' => 1,
                        'prog' => 'script.pl',
                        'sub' => 'err',
                }, {
                        'args' => '',
                        'class' => 'main',
                        'line' => 20,
                        'prog' => 'script.pl',
                        'sub' => 'eval {...}',
                }
        ],
};

# Print out.
print scalar err_bio($err_hr);

# Output:
# ------------- EXCEPTION -------------
# MSG: FOO
# VALUE: KEY: VALUE
# STACK: main script.pl:1
# STACK: main script.pl:20
# -------------------------------------