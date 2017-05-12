#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Form;

# Indent object.
my $indent = Indent::Form->new(
        'align' => 'left',
        'fill_character' => '.',
);

# Input data.
my $input_ar = [
        ['Filename', 'foo.bar'],
        ['Size', '1456kB'],
        ['Description', 'File'],
        ['Author', 'skim.cz'],
];

# Indent.
print $indent->indent($input_ar)."\n";

# Output:
# Filename...: foo.bar
# Size.......: 1456kB
# Description: File
# Author.....: skim.cz