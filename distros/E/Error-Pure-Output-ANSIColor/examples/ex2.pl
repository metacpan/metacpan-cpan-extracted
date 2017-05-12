#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::ANSIColor qw(err_line_all);

# Fictional error structure.
my @err = (
        {
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
        }, {
                'msg' => ['XXX'],
                'stack' => [
                        {
                                'args' => '',
                                'class' => 'main',
                                'line' => 2,
                                'prog' => 'script.pl',
                                'sub' => 'err',
                        },
                ],
        }
);

# Print out.
print err_line_all(@err);

# Output:
# #Error [script.pl:1] FOO
# #Error [script.pl:2] XXX