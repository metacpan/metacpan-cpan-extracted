#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Form;
use Term::ANSIColor;

# Indent object.
my $indent = Indent::Form->new(
    'ansi' => 1,
);

# Input data.
my $input_ar = [
        [
                color('cyan').'Filename'.color('reset'),
                color('bold cyan').'f'.color('reset').'oo.'.color('bold cyan').'b'.color('reset').'ar',
        ],
        [
                color('cyan').'Size'.color('reset'),
                '1456kB',
        ],
        [
                color('cyan').'Description'.color('reset'),
                color('bold cyan').'F'.color('reset').'ile',
        ],
        [
                color('cyan').'Author'.color('reset'),
                'skim.cz',
        ],
];

# Indent.
print $indent->indent($input_ar)."\n";

# Output (with ANSI colors):
#    Filename: foo.bar
#        Size: 1456kB
# Description: File
#      Author: skim.cz