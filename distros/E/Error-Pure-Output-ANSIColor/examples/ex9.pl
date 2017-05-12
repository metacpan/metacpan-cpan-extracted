#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::ANSIColor qw(err_die);

# Fictional error structure.
my $err_hr = {
        'msg' => [
                'FOO',
                'KEY1',
                'VALUE1',
                'KEY2',
                'VALUE2',
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
print err_die($err_hr);

# Output:
# FOOKEY1VALUE1KEY2VALUE2 at script.pl line 1.