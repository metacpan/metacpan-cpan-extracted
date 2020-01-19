#!/usr/bin/env perl

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
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
print encode_utf8($indent->indent($input_ar, decode_utf8('|↔| ')))."\n";

# Output:
# |↔|    Filename: foo.bar
# |↔|        Size: 1456kB
# |↔| Description: File
# |↔|      Author: skim.cz