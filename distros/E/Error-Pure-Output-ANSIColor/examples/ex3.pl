#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::ANSIColor qw(err_line);

# Fictional error structure.
my $err_hr = {
        'msg' => [
                'FOO',
                'BAR',
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
print err_line($err_hr);

# Output:
# #Error [script.pl:1] FOO