#!/usr/bin/env perl

use strict;
use warnings;

use Indent::Data;

# Indent::Data object.
my $i = Indent::Data->new(
       'line_size' => '10',
       'next_indent' => '  ',
       'output_separator' => "|\n",
);

# Print indented text.
print $i->indent('text text text text text text', '<->', 1)."|\n";

# Output:
# <->text text text text text text|