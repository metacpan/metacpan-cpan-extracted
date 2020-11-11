#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Word;

# Object.
my $i = Indent::Word->new(
        'line_size' => 20,
);

# Indent.
print $i->indent(join(' ', ('text') x 7))."\n";

# Output:
# text text text text
# <--tab->text text text