#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::Text qw(err_print);

# Fictional error structure.
my $err_hr = {
        'msg' => [
                'FOO',
                'BAR',
        ],
        'stack' => [
                {
                        'args' => '(2)',
                        'class' => 'Class',
                        'line' => 1,
                        'prog' => 'script.pl',
                        'sub' => 'err',
                }, {
                        'args' => '',
                        'class' => 'mains',
                        'line' => 20,
                        'prog' => 'script.pl',
                        'sub' => 'eval {...}',
                }
        ],
};

# Print out.
print err_print($err_hr)."\n";

# Output:
# Class: FOO