#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure::Output::Text qw(err_bt_pretty_rev);

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
print scalar err_bt_pretty_rev(@err);

# Output:
# ERROR: XXX
# main  err         script.pl  2
# ERROR: FOO
# BAR
# main  err         script.pl  1
# main  eval {...}  script.pl  20