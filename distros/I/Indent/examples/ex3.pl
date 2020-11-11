#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Word;
use Term::ANSIColor;

# Object.
my $i = Indent::Word->new(
        'ansi' => 1,
        'line_size' => 20,
);

# Indent.
print $i->indent('text text '.color('cyan').'text'.color('reset').
        ' text '.color('red').'text'.color('reset').' text text')."\n";

# Output:
# text text text text
# <--tab->text text text