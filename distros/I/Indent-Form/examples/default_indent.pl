#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Form;

# Indent object.
my $indent = Indent::Form->new;

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
#    Filename: foo.bar
#        Size: 1456kB
# Description: File
#      Author: skim.cz