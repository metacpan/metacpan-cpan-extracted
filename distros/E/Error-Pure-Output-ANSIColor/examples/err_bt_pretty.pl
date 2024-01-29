#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::ANSIColor qw(err_bt_pretty);

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
print scalar err_bt_pretty($err_hr);

# Output:
# ERROR: FOO
# KEY: VALUE
# main  err         script.pl  1
# main  eval {...}  script.pl  20